---
name: cetus-aggregator
description: >
  Swap tokens on Sui via Cetus Aggregator V3. Find optimal routes, get quotes,
  build unsigned swap transactions. Triggers on: swap, quote, route, Cetus,
  aggregator, token exchange, price check, DEX, trade, Sui swap, token pair.
---

# Cetus Aggregator V3

DEX aggregator on Sui. Find best-price routes across 28 providers, then build an unsigned transaction for on-chain execution.

## Endpoints

| Method | Path | Auth |
|--------|------|------|
| GET | `https://api-sui.cetus.zone/router_v3/find_routes` | None |
| POST | `https://api-sui-mcp.cetus.zone/aggregator/swap_v3` | apikey (query) |

## find_routes — Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| from | string | Y | Source coin type (full address) |
| target | string | Y | Target coin type (full address) |
| amount | number | Y | Input amount (smallest unit) when `by_amount_in=true`, otherwise output amount |
| by_amount_in | string | N | `true` = fix input amount (default, recommended). `false` = fix output, CETUS provider only |
| split_count | number | N | Order splitting: 1 = no split, max 50, default 50 |
| providers | string | N | Comma-separated provider filter (e.g. `CETUS,DEEPBOOKV3`). Default: all |
| depth | number | N | Max hops 1-3, default 3 |
| v | number | N | API version flag. Always set to `1999999` (≈ v99.99.99) to get the latest and most complete liquidity from all providers. Omitting returns 4000 error. |
| gas | number | N | Estimated gas in smallest SUI units (e.g. 35000 = 0.000035 SUI) |

## swap_v3 — Parameters

| Name | Location | Type | Required | Description |
|------|----------|------|----------|-------------|
| apikey | query | string | Y | API key from Cetus (add as `?apikey=KEY` in URL) |
| request_id | body | string | Y | From `find_routes` response `data.request_id` |
| wallet | body | string | Y | User's Sui wallet address |
| slippage | body | number | Y | Slippage tolerance (0.005 = 0.5%, 0.01 = 1%) |
| by_amount_in | body | string | N | Must match the value used in `find_routes`. Default: `true` |
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
6. POST swap_v3?apikey=KEY  { request_id, wallet, slippage }
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
| slippage | Use 0.5% (0.005) as default; confirm if user wants different |
| apikey | "A Cetus API key is required for building the swap transaction. Please provide your key or set the `CETUS_API_KEY` environment variable." |

## Error Codes

| Code | Meaning |
|------|---------|
| 200 | Success |
| 400 | Unknown error |
| 4000 | Bad Request — check parameters |
| 4030 | Forbidden — check API key |
| 5000 | Liquidity not enough — try smaller amount or different pair |
| 5040 | Unsupported API version |

## Supported Providers (28)

CETUS, SCALLOP, AFTERMATH, FLOWXV3, AFSUI, VOLO, KRIYAV3, KRIYA, ALPHAFI, FLOWX, BLUEMOVE, DEEPBOOKV3, BLUEFIN, HAEDAL, TURBOS, SPRINGSUI, STEAMM, METASTABLE, HAWAL, OBRIC, STEAMM_OMM_V2, STEAMM_OMM, MOMENTUM, MAGMA, FERRADLMM, FERRACLMM, HAEDALPMM, HAEDALHMMV2

Payload shapes: [reference.md](reference.md).
