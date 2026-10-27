# Limit-order user operations

Use the SDK initialized in [SKILL.md](../SKILL.md). Examples build unsigned transactions; replace wallet/order/coin inputs with resolved values. Every type pair is directional: `PayCoin` first, `TargetCoin` second.

## Query before acting

```typescript
const tokenList = await sdk.LimitOrder.getLimitOrderTokenList()
const page = await sdk.LimitOrder.getOwnerLimitOrderList(walletAddress)
const order = await sdk.LimitOrder.getLimitOrder(orderId)
```

Follow `page.has_next_page` / `page.next_cursor` using the SDK's pagination argument. No-indexer users and nonexistent pair/order objects need explicit handling; an RPC/indexer failure is not proof that an order is absent. Verify `order.owner`, `pay_balance`, `target_balance`, `expire_ts`, and normalized `canceled_ts` before building a mutation. SDK status omits an explicit expired state; compare expiry separately with the chain clock.

## Place with the SDK

`price` is **human TargetCoin per PayCoin**. All numbers below are illustrative, not a market quote.

```typescript
const payCoinType = '0x2::sui::SUI'
const targetCoinType = '0xdba34672e30cb065b1f93e3ab55318768fd6fef66c15942c9f7cb846e2f900e7::usdc::USDC'
const payAmountRaw = 1_000_000_000 // 1 SUI, safe integer required by this SDK API
if (!Number.isSafeInteger(payAmountRaw) || payAmountRaw <= 0) {
  throw new Error('Use the exact-integer PTB path for this amount')
}
const tx = await sdk.LimitOrder.placeLimitOrder({
  pay_coin_type: payCoinType,
  target_coin_type: targetCoinType,
  pay_coin_amount: payAmountRaw,
  price: 2.5, // illustrative minimum USDC per SUI
  pay_decimal: 9,
  target_decimal: 6,
  expired_ts: Date.now() + 86_400_000, // milliseconds; compare with chain clock
})
tx.setSender(walletAddress)
```

The builder looks up the pair indexer and chooses `place_limit_order` or `create_indexer_and_place_limit_order`. The latter aborts if an indexer already exists; on lookup errors or races, refresh pair state before retrying. Do not create a second order as a blind retry after an uncertain submission result.

## Exact-rate PTB

The SDK accepts numeric amounts/prices and rounds its rate helper to nearest. For values outside JS safe integers or a strict price floor, encode an integer rate with BigInt and floor division. If `human_price = priceNumerator / priceDenominator`, then:

```
rate = floor(10^(18 + pay_decimals - target_decimals) / human_price)
minimum target_raw for full order = ceil(pay_raw × 10^18 / rate)
```

For selling 1 SUI at 2.5 USDC/SUI, `rate = 400000000000000000000` and minimum output is `2500000` raw USDC. Lowering the rate makes the required target amount larger. Reject zero rate, values beyond u128, and a computed full-order output beyond u64. Show the effective rounded price before signing.

```typescript
import { Transaction, coinWithBalance } from '@mysten/sui/transactions'
import { limitMainnet } from '@cetusprotocol/limit-sdk'

const payType = '0x2::sui::SUI'
const targetType = '0xdba34672e30cb065b1f93e3ab55318768fd6fef66c15942c9f7cb846e2f900e7::usdc::USDC'
const payRaw = 1_000_000_000n
const payDecimals = 9
const targetDecimals = 6
const priceNumerator = 5n
const priceDenominator = 2n
const exponent = 18 + payDecimals - targetDecimals
const numerator = (exponent >= 0 ? 10n ** BigInt(exponent) : 1n) * priceDenominator
const denominator = priceNumerator * (exponent < 0 ? 10n ** BigInt(-exponent) : 1n)
const rate = numerator / denominator
const u64Max = (1n << 64n) - 1n
const requiredTarget = rate > 0n ? (payRaw * 10n ** 18n + rate - 1n) / rate : 0n
if (payRaw <= 0n || payRaw > u64Max || rate <= 0n || rate >= (1n << 128n) || requiredTarget > u64Max) {
  throw new Error('Amount/rate outside contract bounds')
}
const config = limitMainnet.limit_order.config!
const tx = new Transaction()
tx.setSender(walletAddress)
const payCoin = tx.add(coinWithBalance({ type: payType, balance: payRaw }))
tx.moveCall({
  target: `${limitMainnet.limit_order.published_at}::limit_order::place_limit_order`,
  typeArguments: [payType, targetType],
  arguments: [
    tx.object(config.global_config_id),
    tx.object(pairIndexerId), // existing indexer for this exact Pay → Target pair
    tx.object(config.user_orders_indexer_id),
    payCoin,
    tx.pure.u128(rate),
    tx.pure.u64(BigInt(Date.now()) + 86_400_000n),
    tx.object('0x6'),
  ],
})
```

For a missing pair, use `create_indexer_and_place_limit_order` and the global `rate_orders_indexer_id` in the second argument. The coin is consumed and the contract shares the new order internally; there is no returned order NFT to transfer. Capture `OrderPlacedEvent.order_id` after execution.

## Claim and cancel

```typescript
const order = await sdk.LimitOrder.getLimitOrder(orderId)
if (!order || order.owner !== walletAddress) throw new Error('Resolve and verify the order owner')
const pair = { pay_coin_type: order.pay_coin_type, target_coin_type: order.target_coin_type }
const claimTx = await sdk.LimitOrder.claimTargetCoin({ ...pair, order_id: order.id })
const cancelTx = await sdk.LimitOrder.cancelOrdersByOwner([{ ...pair, order_id: order.id }])
```

These are alternative payloads to review, not a request to submit both. Claim transfers current target balance to the owner internally; do not add a transfer of a nonexistent return value. Cancellation is not deletion. In this source, cancellation refunds pay and target balances when remaining pay is positive; full-fill repayment has already transferred target proceeds when remaining pay reaches zero. The contract does not update `claimed_amount` in `claim_target_coin`; use actual balances and claim/repayment events rather than that field as an authoritative withdrawal total.
