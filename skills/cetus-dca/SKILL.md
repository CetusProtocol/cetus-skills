---
name: cetus-dca
description: >
  Create, inspect, withdraw from, and cancel Cetus DCA orders on Sui, or integrate
  their keeper execution and oracle signatures. Use for Cetus DCA,
  dollar-cost averaging, recurring token purchases, 定投, and 周期交易.
---

# Cetus DCA

Deposit input coins into a shared `Order<InCoin, OutCoin>`. Authorized keepers execute cycles through an atomic borrow/swap/repay flow. This is an on-chain order, not a local cron job; neither the contract nor this skill guarantees a keeper will execute on time.

## Setup

```bash
npm install @cetusprotocol/dca-sdk@1.2.5 @cetusprotocol/common-sdk@1.4.3 @mysten/sui@2.31.2
```

```typescript
import { CetusDcaSDK, dcaMainnet } from '@cetusprotocol/dca-sdk'

const sdk = CetusDcaSDK.createSDK(dcaMainnet)
sdk.setSenderAddress(walletAddress)
```

Version snapshot: 2026-10-26. Configuration is exported by the DCA SDK, not common-sdk. Sui 2.x clients use gRPC/GraphQL. The SDK config's `dca.version` is 2 although its target matches local `Published.toml` v4: do not use that field as a live gate check. See [deployment provenance](reference/contracts.md#deployment-provenance).

## Choose the operation

| Intent | SDK method on `sdk.Dca` | Notes |
|---|---|---|
| Current minimums / policy | `getDcaGlobalConfig()` | Also read config for signature validity and keeper threshold |
| Whitelisted coins | `getDcaCoinWhiteList(whitelistMode)` | Read mode from config; don't hardcode initialization defaults |
| Owner orders | `getDcaOrders(wallet)` | Shared indexed orders; finished/canceled history may remain |
| Opening authorization | GET `https://api-sui.cetus.zone/dca/quote` | Query `in_coin`, `freq`, `count`, `sender`; see [orders](reference/orders.md) |
| Open | `dcaOpenOrderPayload(params)` | Use fresh quote signature, fee rate, timestamp and input limit |
| Withdraw proceeds | `withdrawPayload(params)` / `withdrawAll(params[])` | Pending order, owner-only; builders transfer returned coins |
| Cancel and refund | `dcaCloseOrderPayload(params[])` | Calls `cancel_order`, not object deletion; pending owner only |
| Keeper cycle | Raw `flash_loan_for_make_deal_v2` + `repay_for_make_deal` | Load [keeper and signatures](reference/keeper.md) |

## Essential units and lifecycle

- Collect input/output types, raw deposit, cycle frequency/count, per-cycle output bounds, wallet, and service-supplied oracle authorization. Amount fields in opening params are **integer strings** in smallest units; frequency, count, fee rate and timestamp are safe-integer numbers.
- DCA times are Unix **seconds**, including `cycle_frequency`, signed `timestamp`, `next_cycle_at`, and `created_at`. Clock object `0x6` supplies milliseconds, divided by 1000 internally. Limit-order expiry uses different units.
- Require distinct coin types, `cycle_count > 0` and at least the current config minimum, frequency within `[config.min_cycle_frequency, 31536000]`, `min_out < max_out`, and `0 <= fee_rate <= 1000000`.
- `in_amount_per_cycle = floor(deposit / cycle_count)` must be positive and at least signed `per_cycle_in_amount_limit > 0`. Budget using the actual integer division and remainder; `cycle_count` is not a stored execution counter. The first cycle is eligible immediately. Later cycles become due at actual execution time + frequency; a delayed keeper does not execute automatic catch-up cycles.
- Fee denominator is **1,000,000**; 1000 means 0.1%. Fee is taken from **input** before routing. Output bounds and promised output apply to the whole output coin supplied to repayment; excess above the maximum reverts.
- Status is 0 pending, 1 finished, 2 canceled. Pending owners can withdraw accrued output or cancel to receive both balances. Final repayment automatically transfers all accrued output to the owner and marks the order finished; do not send a redundant withdraw/cancel for a finished order.
- `cancle_order` and `flash_loan_for_make_deal` are deprecated and always abort. Use `cancel_order` and the `_v2` keeper entrypoint. Ignore all `#[test_only]` helpers when integrating production.

For mainnet opening authorization, call the official GET `https://api-sui.cetus.zone/dca/quote` with `in_coin`, `freq`, `count`, and `sender`. Preserve the request's frequency/count (not echoed in the response); set `per_cycle_in_amount_limit = String(quote.amount_in_limit_per_cycle)` and copy `fee_rate`, `timestamp`, and `signature` from response `data`. Fetch again if signed parameters change or the quote expires. See [orders](reference/orders.md) for HTTP/business-error handling and the complete mapping. Keeper threshold signing is a separate service; its endpoint is not established here. If quote retrieval fails, report the actual error instead of fabricating authorization. Build unsigned payloads; signing/submitting requires the user's authorization.

## References

- [Orders](reference/orders.md): opening params, queries, withdrawal and cancellation examples.
- [Keeper and signatures](reference/keeper.md): exact signed bytes, ACL checks, fees and atomic execution.
- [Contracts](reference/contracts.md): source provenance, deployment IDs, production signatures and errors.
