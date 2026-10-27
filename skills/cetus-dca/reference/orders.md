# DCA user operations

Initialize `sdk` as in [SKILL.md](../SKILL.md). These are unsigned transaction builders. Coin types are directional `InCoin, OutCoin`; raw amounts stay integer strings.

## Read config and order state

```typescript
const config = await sdk.Dca.getDcaGlobalConfig()
if (!config) throw new Error('DCA config unavailable')
const allowedCoins = await sdk.Dca.getDcaCoinWhiteList(Number(config.whitelist_mode))
const orders = await sdk.Dca.getDcaOrders(walletAddress)
```

`getDcaGlobalConfig()` exposes only minimum cycle count/frequency and whitelist mode. Read the deployment's full config object for `package_version`, `oracle_valid_duration`, `keeper_threshold`, and ACL state. Whitelist mode is a bitmask: 0 unrestricted, bit 1 input whitelist, bit 2 output whitelist. Current config governs, not initial defaults.

Orders are shared objects discovered through the indexer's user table. Its boolean value can become false when an order finishes/cancels, while the object remains. Check on-chain `status`, `user`, input balance, output balance, and schedule; don't equate returned history with pending orders.

## Open an order

Get oracle-signed `timestamp`, `fee_rate`, `per_cycle_in_amount_limit`, frequency/count, and hex signature from an authorized service. Match the signed wallet and input type. See [signature bytes](keeper.md#oracle-opening-authorization). No service URL or signing key is provided by the contract sources.

```typescript
import type { OpenDcaOrderParams } from '@cetusprotocol/dca-sdk'

// oracleAuthorization comes from the deployment's service; it is not a wallet tx signature.
const params: OpenDcaOrderParams = {
  in_coin_type: '0xdba34672e30cb065b1f93e3ab55318768fd6fef66c15942c9f7cb846e2f900e7::usdc::USDC',
  out_coin_type: '0x2::sui::SUI',
  in_coin_amount: '100000000', // 100 USDC total
  cycle_frequency: oracleAuthorization.cycle_frequency, // seconds
  cycle_count: oracleAuthorization.cycle_count,
  per_cycle_min_out_amount: '1', // illustrative; derive realistic output bounds
  per_cycle_max_out_amount: '1000000000000',
  per_cycle_in_amount_limit: oracleAuthorization.per_cycle_in_amount_limit,
  fee_rate: oracleAuthorization.fee_rate,
  timestamp: oracleAuthorization.timestamp, // Unix seconds
  signature: oracleAuthorization.signature, // hex, scheme || sig || pubkey
}
if (!Number.isSafeInteger(params.cycle_count) || params.cycle_count <= 0) {
  throw new Error('Invalid cycle count')
}
const perCycle = BigInt(params.in_coin_amount) / BigInt(params.cycle_count)
if (perCycle < BigInt(params.per_cycle_in_amount_limit) || perCycle === 0n) {
  throw new Error('Deposit below signed per-cycle minimum')
}
const tx = sdk.Dca.dcaOpenOrderPayload(params)
tx.setSender(walletAddress)
```

Before signing, validate all bounds in [SKILL.md](../SKILL.md), freshness against chain time, whitelist and source version. Also check `floor(deposit / perCycle) × max_out <= u64::MAX`, the source's conservative total-output overflow guard. Division by zero happens before the contract's minimum-count validation, so reject zero count locally. For an exact requested spend/cycle, choose a deposit divisible by the intended count; the schedule stores raw per-cycle amount and a remainder, not a hard cycle-count cap.

Opening shares the order and emits `OpenOrderEvent.order_id`. The first cycle is due immediately (`next_cycle_at = chain now in seconds`). A later eligible cycle still requires an authorized keeper, fresh threshold signatures, and viable liquidity. There is no add-funds or edit-schedule entrypoint in this source; changing the plan requires canceling and opening a new order with fresh authorization.

## Withdraw accrued output

```typescript
const tx = await sdk.Dca.withdrawPayload({
  order_id: orderId,
  in_coin_type: inCoinType,
  out_coin_type: outCoinType,
})
```

Only the pending order's owner may withdraw. The helper calls `order::withdraw` and transfers its returned `Coin<OutCoin>` to the SDK sender. This keeps the recurring order active; final completion already transfers the remaining output automatically.

## Cancel and refund

```typescript
const tx = sdk.Dca.dcaCloseOrderPayload([{
  order_id: orderId,
  in_coin_type: inCoinType,
  out_coin_type: outCoinType,
}])
```

Despite its name, this SDK method calls **`cancel_order`**, receives input and output coins, and transfers both to the sender. It sets status 2, clears the schedule, removes the order from open-orders indexing, and marks its user-table entry false. It does not delete the shared object. Use only for pending orders owned by the sender; a multi-order batch reverts if any included order fails. The misspelled legacy `cancle_order` is deprecated and always aborts.
