---
name: cetus-limitorder
description: >
  Place, query, cancel, and claim Cetus limit orders on Sui, or integrate their
  keeper fill flow. Use for Cetus limit order, limitorder, target-price orders,
  限价单, 挂单, 撤单, and claiming limit-order proceeds.
---

# Cetus Limit Orders

Escrow pay coins in a shared `LimitOrder<PayCoin, TargetCoin>` until an external filler exchanges them for target coins. A limit order does not guarantee execution or schedule a market swap.

## Setup

```bash
npm install @cetusprotocol/limit-sdk@1.2.6 @cetusprotocol/common-sdk@1.4.3 @mysten/sui@2.31.2 blakejs
```

```typescript
import { CetusLimitOrderSDK, limitMainnet } from '@cetusprotocol/limit-sdk'

const sdk = CetusLimitOrderSDK.createSDK(limitMainnet)
sdk.setSenderAddress(walletAddress)
```

Version snapshot: 2026-10-26. Mainnet configuration comes from the limit SDK. Use Sui 2.x gRPC/GraphQL; `package_id` identifies types and `published_at` targets calls. See [deployment provenance](reference/contracts.md#deployment-provenance) before selecting a deployment.

## Choose the operation

| Intent | SDK method on `sdk.LimitOrder` | Notes |
|---|---|---|
| Supported tokens / minimum fills | `getLimitOrderTokenList()` | Read current whitelist policy too |
| Pair indexer | `getPoolIndexerId(payType, targetType)` | Direction matters; preserve Pay → Target order |
| Owner orders | `getOwnerLimitOrderList(owner, pagination?)` | Shared objects, not wallet-owned NFTs; follow pagination |
| One order | `getLimitOrder(orderId)` | Check owner, balances, expiry and cancellation |
| Place | `placeLimitOrder(params)` | Async unsigned builder; creates pair indexer if absent |
| Claim accrued target | `claimTargetCoin(params)` | Owner-only; transfers to owner internally |
| Cancel | `cancelOrdersByOwner(params[])` | Owner-only; distinct from keeper deletion |
| Fill / cleanup | Raw Move calls | Load [keeper reference](reference/keeper.md) |

## Essential units and lifecycle

- Collect pay/target coin types, their decimals, pay amount, minimum human price **target per pay**, wallet, and expiry. Resolve raw amounts without floating-point loss.
- SDK `pay_coin_amount` is a **raw-unit number**: require a positive safe integer. Its `price` is a positive finite human price. For larger raw amounts or precise decimal prices, use the string/BigInt PTB route in [orders](reference/orders.md).
- `expired_ts` is Unix **milliseconds**, strictly after the chain clock. Never pass seconds. The contract's fill check requires `clock.timestamp_ms < expire_ts`.
- Contract `rate = 10^(18 + pay_decimals - target_decimals) / human_price`. It is the inverse of the human quote, not a tick or sqrt price. Required target for a fill is based on `ceil(pay_raw × 10^18 / rate)` with a cumulative rounding cap. For a strict minimum price, floor the encoded rate; the SDK helper rounds to nearest.
- Orders start with `canceled_ts = u64::MAX`; the SDK normalizes that sentinel to 0. Partial proceeds sit in `target_balance`; `claim_target_coin` pays them to the owner. Final fill repayment automatically transfers accumulated target to the owner.
- Cancellation removes the rate index and stamps `canceled_ts`; the object and user index can remain until keeper deletion after the grace period. Do not treat index membership as proof an order is fillable. An expired order can need keeper cancellation; the clock does not refund it automatically.

Build unsigned transactions after reviewing amount, price and expiry. Signing/submitting requires the user's authorization; a request to inspect an order does not authorize a trade.

## References

- [Orders](reference/orders.md): SDK place/query/claim/cancel and exact-rate PTB.
- [Keeper](reference/keeper.md): conditional ACL, atomic fill, cancellation and deletion.
- [Contracts](reference/contracts.md): source provenance, mainnet IDs, exact production signatures and errors.
