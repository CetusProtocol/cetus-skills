---
name: cetus-aggregator
description: >
  Swap tokens on Sui via Cetus Aggregator V3. Find optimal routes, get quotes,
  build unsigned swap transactions. Triggers on: swap, quote, route, Cetus,
  aggregator, token exchange, price check, DEX, trade, Sui swap, token pair.
---

# Cetus Aggregator V3

DEX aggregator on Sui. Find best-price routes across multiple providers, then build an unsigned transaction for on-chain execution.

Transaction building supports fixed input only. Use `by_amount_in=true` in `find_routes`; fixed-output quotes (`by_amount_in=false`) cannot be used to build transactions.

## Endpoints

| Method | Path | Auth |
|--------|------|------|
| GET | `https://api-sui.cetus.zone/router_v3/find_routes` | None |
| POST | `https://api-sui-mcp.cetus.zone/aggregator/swap_v3` | None |

## find_routes — Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| from | string | Y | Source coin type (full address) |
| target | string | Y | Target coin type (full address) |
| amount | number | Y | Input amount (smallest unit) when `by_amount_in=true`, otherwise output amount |
| by_amount_in | string | N | `true` = fixed input (default, required for transaction building). `false` = fixed output (quote only) |
| split_count | number | N | Order splitting: 1 = no split, max 50, default 50 |
| providers | string | N | Comma-separated provider filter (e.g. `CETUS,DEEPBOOKV3`). Default: all |
| depth | number | N | Max hops 1-3, default 3 |
| v | number | N | API version flag. Always set to `1999999` (≈ v99.99.99) to get the latest and most complete liquidity from all providers. Omitting returns 4000 error. |
| gas | number | N | Estimated gas in smallest SUI units (e.g. 35000 = 0.000035 SUI) |

## swap_v3 — Parameters

| Name | Location | Type | Required | Description |
|------|----------|------|----------|-------------|
| request_id | body | string | Y | From `find_routes` response `data.request_id` |
| wallet | body | string | Y | User's Sui wallet address |
| slippage | body | number | Y | Slippage tolerance as decimal ratio. **Must be ≤ 0.5 (50%).** Recommended: 0.005 (0.5%) for stablecoin pairs, 0.01 (1%) for volatile pairs. Values > 0.5 are dangerous and will cause significant asset loss. |
| by_amount_in | body | string | N | Only `true` is supported (default). The `request_id` must come from a fixed-input quote |
| partner | body | string | N | Partner object ID for referral fee sharing |

## Common Coin Types

| Token | Decimals | Coin Type |
|-------|----------|-----------|
| SUI | 9 | `0x0000000000000000000000000000000000000000000000000000000000000002::sui::SUI` |
| USDC | 6 | `0xdba34672e30cb065b1f93e3ab55318768fd6fef66c15942c9f7cb846e2f900e7::usdc::USDC` |
| USDT | 6 | `0xc060006111016b8a020ad5b33834984a437aaa7d3c74c18e09a95d48aceab08c::coin::COIN` |
| CETUS | 9 | `0x06864a6f921804860930db6ddbe2e16acdf8504495ea7481637a1c8b9a8fe54b::cetus::CETUS` |
| DEEP | 6 | `0xdeeb7a4662eec9f2f3def03fb937a663dddaa2e215b8078a284d026b7946c270::deep::DEEP` |
| WAL | 9 | `0x356a26eb9e012a68958082340d4c4116e7f55615cf27affcff209cf0ae544f59::wal::WAL` |

Amount formula: `amount = human_amount * 10^decimals` (e.g. 1 SUI = 1000000000, 5 USDC = 5000000)

## Integration Flow

```
1. Collect: from coin, target coin, amount, wallet address, slippage
2. GET  find_routes(from, target, amount, by_amount_in=true, v=1999999)
3.      → response.data.request_id, amount_in, amount_out
4. Display quote to user (convert amounts back to human-readable)
5. On confirmation:
6. POST swap_v3  { request_id, wallet, slippage }
7.      → response.data.data  (unsigned transaction bytes, base64)
8. Sign tx bytes with user's wallet → submit to Sui blockchain
```

## Missing Params — What to Ask

| Missing | Prompt |
|---------|--------|
| from | "Which token do you want to swap from?" |
| target | "Which token do you want to receive?" |
| amount | "How much do you want to swap? (e.g. 1 SUI, 10 USDC)" |
| wallet | "What is your Sui wallet address?" |
| slippage | Default to 0.5% (0.005). **⚠ Always warn the user:** "Slippage controls how much price movement you accept. Higher slippage = higher risk of asset loss. Recommended: 0.5% for stablecoins, 1% for volatile pairs. Never exceed 50%." Reject any value > 0.5. |


## Error Codes

| Code | Meaning |
|------|---------|
| 200 | Success |
| 400 | Unknown error |
| 4000 | Bad Request — check parameters |
| 4030 | Forbidden |
| 5000 | Liquidity not enough — try smaller amount or different pair |
| 5040 | Unsupported API version |

## Provider Snapshot (37)

From `@cetusprotocol/aggregator-sdk@1.7.5` (`getAllProviders`), checked 2026-10-21. This SDK list does not guarantee every provider is enabled by the REST service or available for a given pair; omit the filter to use server defaults.

CETUS, KRIYA, DIPCOIN, FLOWX, FLOWXV3, KRIYAV3, TURBOS, AFTERMATH, HAEDAL, VOLO, AFSUI, BLUEMOVE, DEEPBOOKV3, SCALLOP, SUILEND, BLUEFIN, HAEDALPMM, ALPHAFI, SPRINGSUI, STEAMM, METASTABLE, OBRIC, HAWAL, MOMENTUM, STEAMM_OMM, STEAMM_OMM_V2, MAGMA, SEVENK, HAEDALHMMV2, FULLSAIL, CETUSDLMM, FERRADLMM, FERRACLMM, BOLT, MAGMAPROPAMM, HAEDALPROPAMM, CETUS_TIDE

Payload shapes: [reference.md](reference.md).
