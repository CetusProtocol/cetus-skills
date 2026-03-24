# Cetus Aggregator V3 — Reference

Detailed payload shapes, response schemas, curl examples, and edge cases.

## find_routes — Response Schema

### Success (200)

```json
{
  "code": 200,
  "msg": "Success",
  "data": {
    "request_id": "fc59359262f4a7013e09625ed02d8468",
    "amount_in": 10000000,
    "amount_out": 4296,
    "deviation_ratio": "0.07938901",
    "paths": [
      {
        "id": "0xe7f40844d329124a12fe0e4997b5007b641734b47ce2e8e0eac6fe09d557954e",
        "provider": "MAGMA",
        "from": "0x356a26eb9e012a68958082340d4c4116e7f55615cf27affcff209cf0ae544f59::wal::WAL",
        "target": "0x0000000000000000000000000000000000000000000000000000000000000002::sui::SUI",
        "direction": true,
        "fee_rate": "0.0001",
        "lot_size": 1,
        "amount_in": 10000000,
        "amount_out": 1169612,
        "published_at": "0x9a8e367ae1120a462af2144159a01ee71185b13d3a80d827022aa34ddcc7afcb",
        "extended_details": {
          "after_sqrt_price": 6309028175088270238
        }
      },
      {
        "id": "0x9a1a135398d7d79cfdd27ed664b53afb4744faccb16d03dc7935c00619599f63",
        "provider": "CETUS",
        "from": "0x0000000000000000000000000000000000000000000000000000000000000002::sui::SUI",
        "target": "0x93a3b2cdf609169baa2df5e746f5b45ae0a64242f46fa7b4c7a66527d0e328c9::susdt::SUSDT",
        "direction": false,
        "fee_rate": "0.01",
        "lot_size": 1,
        "amount_in": 1169612,
        "amount_out": 13781769856,
        "published_at": "0x550dcd6070230d8bf18d99d34e3b2ca1d3657b76cc80ffdacdb2b5d28d7e0124",
        "extended_details": {
          "after_sqrt_price": 169233527930194888
        }
      },
      {
        "id": "0x2bcfb471c4f27539083c2c1ca0e0479ffd7ef544f2a7ec80ade7e7446faecf98",
        "provider": "CETUS",
        "from": "0x93a3b2cdf609169baa2df5e746f5b45ae0a64242f46fa7b4c7a66527d0e328c9::susdt::SUSDT",
        "target": "0xdba34672e30cb065b1f93e3ab55318768fd6fef66c15942c9f7cb846e2f900e7::usdc::USDC",
        "direction": false,
        "fee_rate": "0.01",
        "lot_size": 1,
        "amount_in": 13781769856,
        "amount_out": 4296,
        "published_at": "0x550dcd6070230d8bf18d99d34e3b2ca1d3657b76cc80ffdacdb2b5d28d7e0124",
        "extended_details": {
          "after_sqrt_price": 33091158768251823095188
        }
      }
    ],
    "packages": {
      "aggregator_v3": "0x07c27e879ba9282506284b0fef26d393978906fc9496550d978c6f493dbfa3e5"
    },
    "gas": 35000
  }
}
```

### Error — Insufficient Liquidity

```json
{
  "code": 400,
  "msg": "liquidity is not enough"
}
```

### Field Descriptions

| Field | Type | Description |
|-------|------|-------------|
| data.request_id | string | Opaque ID referencing cached routing results. Pass to `swap_v3`. |
| data.amount_in | integer | Total input amount across all paths (smallest denomination) |
| data.amount_out | integer | Total output amount across all paths (smallest denomination) |
| data.deviation_ratio | string | Price deviation ratio |
| data.gas | integer | Estimated gas in smallest SUI units |
| data.paths[] | array | Ordered list of hops in the route |
| data.paths[].id | string | Pool object ID on Sui |
| data.paths[].provider | string | DEX provider name |
| data.paths[].from | string | Input coin type for this hop |
| data.paths[].target | string | Output coin type for this hop |
| data.paths[].direction | boolean | Pool swap direction |
| data.paths[].fee_rate | string | Pool fee rate (e.g. "0.0001" = 0.01%) |
| data.paths[].lot_size | integer | Minimum trade lot size |
| data.paths[].amount_in | integer | Input amount for this hop |
| data.paths[].amount_out | integer | Output amount for this hop |
| data.paths[].published_at | string | Package address used for this pool |
| data.paths[].extended_details | object | Provider-specific data (e.g. after_sqrt_price) |
| data.packages | object | Contract package addresses used |

---

## swap_v3 — Response Schema

### Success (200)

```json
{
  "code": 200,
  "msg": "Success",
  "data": {
    "data": "AAAHAQCJabZsKnIcXqghVCVOnYLLfey96rBf2+SnwVKzMgNB...<base64 tx bytes>",
    "to": "0xec2108d2092dd6f1f6fe45def639500e323596e0bab9fabc206461aadf357e6a"
  }
}
```

### Field Descriptions

| Field | Type | Description |
|-------|------|-------------|
| data.data | string | Base64-encoded unsigned transaction bytes. Sign with wallet then submit to Sui. |
| data.to | string | Aggregator contract addresses used (comma-separated if multiple) |

---

## curl Examples

### Find routes: SUI → USDC (1 SUI)

```bash
curl --location --request GET \
  'https://api-sui.cetus.zone/router_v3/find_routes?from=0x0000000000000000000000000000000000000000000000000000000000000002::sui::SUI&target=0xdba34672e30cb065b1f93e3ab55318768fd6fef66c15942c9f7cb846e2f900e7::usdc::USDC&amount=1000000000&by_amount_in=true&v=1999999'
```

### Find routes: USDC → CETUS (4 USDC)

```bash
curl --location --request GET \
  'https://api-sui.cetus.zone/router_v3/find_routes?from=0xdba34672e30cb065b1f93e3ab55318768fd6fef66c15942c9f7cb846e2f900e7::usdc::USDC&target=0x06864a6f921804860930db6ddbe2e16acdf8504495ea7481637a1c8b9a8fe54b::cetus::CETUS&amount=4000000&by_amount_in=true&v=1999999'
```

### Find routes: SUI → USDC (no splitting, CETUS provider only)

```bash
curl --location --request GET \
  'https://api-sui.cetus.zone/router_v3/find_routes?from=0x0000000000000000000000000000000000000000000000000000000000000002::sui::SUI&target=0xdba34672e30cb065b1f93e3ab55318768fd6fef66c15942c9f7cb846e2f900e7::usdc::USDC&amount=1000000000&by_amount_in=true&split_count=1&providers=CETUS&v=1999999'
```

### Build swap transaction

```bash
curl --location --request POST \
  'https://api-sui-mcp.cetus.zone/aggregator/swap_v3?apikey=YOUR_API_KEY' \
  --header 'Content-Type: application/json' \
  --data-raw '{
    "request_id": "fc59359262f4a7013e09625ed02d8468",
    "wallet": "0xYOUR_WALLET_ADDRESS",
    "slippage": 0.005
  }'
```

---

## Error Codes

| Code | Meaning | Description | Recommended Action |
|------|---------|-------------|--------------------|
| 200 | OK | Request succeeded | Process response data |
| 400 | Unknown error | Catch-all error, often insufficient liquidity | Check params; try different pair or smaller amount |
| 4000 | Bad Request | Invalid or missing parameters | Verify all required params and coin type formats |
| 4030 | Forbidden | Authentication failed | Check API key is valid and included in query |
| 5000 | Liquidity not enough | No viable route at requested amount | Reduce amount, try different providers, or split manually |
| 5040 | Unsupported API version | API version mismatch | Remove version params; use default endpoints |

---

## Common Coin Types

| Token | Decimals | Coin Type | 1 token = |
|-------|----------|-----------|-----------|
| SUI | 9 | `0x0000000000000000000000000000000000000000000000000000000000000002::sui::SUI` | 1,000,000,000 |
| USDC | 6 | `0xdba34672e30cb065b1f93e3ab55318768fd6fef66c15942c9f7cb846e2f900e7::usdc::USDC` | 1,000,000 |
| USDT | 6 | `0xc060006111016b8a020ad5b33834984a437aaa7d3c74c18e09a95d48aceab08c::coin::COIN` | 1,000,000 |
| CETUS | 9 | `0x06864a6f921804860930db6ddbe2e16acdf8504495ea7481637a1c8b9a8fe54b::cetus::CETUS` | 1,000,000,000 |
| DEEP | 6 | `0xdeeb7a4662eec9f2f3def03fb937a663dddaa2e215b8078a284d026b7946c270::deep::DEEP` | 1,000,000 |
| WAL | 9 | `0x356a26eb9e012a68958082340d4c4116e7f55615cf27affcff209cf0ae544f59::wal::WAL` | 1,000,000,000 |

**Amount conversion:** `amount = human_amount * 10^decimals`

---

## Edge Cases & Gotchas

### request_id Expiration
The `request_id` from `find_routes` references server-side cached results. It has a limited time-to-live — call `swap_v3` promptly after obtaining it. If expired, re-call `find_routes`.

### by_amount_in Matching
The `by_amount_in` value in `swap_v3` **must match** the value used in the corresponding `find_routes` call. Mismatched values will produce incorrect transactions.

### by_amount_in=false Limitation
When `by_amount_in` is set to `false`, only the CETUS provider is used. Multi-provider routing is not supported for fixed-output swaps.

### Multi-hop Paths
A single route can contain multiple hops (up to `depth` hops, max 3). Each element in `data.paths[]` represents one hop. The `target` of hop N matches the `from` of hop N+1.

### Amount Decimals
All amounts are in the smallest denomination of the token. Always convert human-readable amounts before calling the API:
- 1 SUI → `1000000000` (9 zeros)
- 5 USDC → `5000000` (6 zeros)
- 0.5 CETUS → `500000000` (9 zeros)

### Gas Units
The `gas` field is in smallest SUI units. For example, 35000 = 0.000035 SUI.

### Transaction Signing
The `swap_v3` endpoint returns unsigned transaction bytes (`data.data`). You must sign these with the user's wallet private key and submit the signed transaction to the Sui blockchain. This is client-side and SDK-dependent.

### Slippage Behavior
The slippage value is a decimal ratio. The on-chain transaction will automatically fail if the actual swap result exceeds the specified slippage. For example, `0.005` means the transaction reverts if the output is more than 0.5% worse than the quoted amount.

### Version Parameter
The `v=1999999` query parameter represents version **v99.99.99** — a deliberately high version number that tells the service to return the latest and most complete set of liquidity sources from all providers. Always hardcode `v=1999999` in every `find_routes` request. Omitting `v` will result in a `4000 "version too low"` error and an empty response.

### Partner Integration
Partners holding a `PartnerCap` object can pass their partner object ID to earn a share of protocol fees. See [Cetus Developer Docs](https://cetus-1.gitbook.io/cetus-developer-docs/developer/via-sdk-v2/sdk-modules/cetusprotocol-sui-clmm-sdk/partner-swap) for fee collection.
