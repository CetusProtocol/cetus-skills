# Upstream verification

Checked on 2026-10-21. These are observed upstream snapshots, not a guarantee that deployed contracts or routing availability will remain unchanged.

## Published SDK versions

| Package | Previous docs | npm latest checked |
|---|---|---|
| `@cetusprotocol/common-sdk` | 1.3.3 | 1.4.3 |
| `@cetusprotocol/sui-clmm-sdk` | 1.4.1 | 1.4.9 |
| `@cetusprotocol/dlmm-sdk` | 1.2.6 | 1.3.3 |
| `@cetusprotocol/aggregator-sdk` | REST skill; no SDK pin | 1.7.5 (provider snapshot source) |

Sources: npm registry metadata and release tarballs for [common](https://registry.npmjs.org/@cetusprotocol/common-sdk/1.4.3), [CLMM](https://registry.npmjs.org/@cetusprotocol/sui-clmm-sdk/1.4.9), [DLMM](https://registry.npmjs.org/@cetusprotocol/dlmm-sdk/1.3.3), and [Aggregator](https://registry.npmjs.org/@cetusprotocol/aggregator-sdk/1.7.5). The published declarations and source maps were inspected alongside the [official SDK repository](https://github.com/CetusProtocol/cetus-sdk-v2).

The new SDKs require `@mysten/sui >=2.28.0`. Verification used 2.31.2 with `blakejs`, which is a peer dependency of CLMM/DLMM. The client layer uses gRPC and GraphQL; older JSON-RPC integrations must migrate.

## Material changes

- Mainnet configuration exports belong to the CLMM/DLMM packages, not common-sdk.
- DLMM has no `Position.openPositionPayload`. Use `addLiquidityPayload` without `position_id`, supplying the bin range, complete `BinLiquidityInfo`, active ID, bin step, and price slippage. Existing-position additions also take fee/reward collection options.
- DLMM liquidity calculations can resolve actual active-bin balances via `pool_id`. Do not substitute zero balances for a live active bin.
- DLMM pool creation requires `base_factor`. Its helper returns a pool argument inside the transaction; submit the containing transaction.
- DLMM removal accepts `BinLiquidityInfo`; SDK `remove_percent` is a fraction (0.5 = 50%), while Move uses basis points (5000 = 50%). Close operations must consume reward balances and the close certificate.
- CLMM examples now await asynchronous builders, use `getPositionById`, and handle current pool/math return types.
- Address tables distinguish original package IDs from current SDK `published_at` targets. DLMM Router package identity also changed. Use the SDK configuration when building calls.
- Aggregator SDK 1.7.5 exposes 37 providers. This is an SDK list; actual REST availability depends on the service, token pair, and routing conditions.

DLMM Move signatures were compared with the [official interface](https://github.com/CetusProtocol/cetus-dlmm-interface), including registry creation, removal, balance returns, and close certificates. Interface implementations are stubs, so they cannot establish execution behavior.

## Verification scope

- Installed the pinned SDK matrix together in an isolated temporary npm project.
- Type-checked complete TypeScript SDK example blocks against the published declarations with TypeScript (`--noEmit --skipLibCheck`, ES2022/NodeNext). External inputs such as pool IDs and signers were declared with SDK types. Illustrative partial snippets were excluded.
- Runtime smoke checks passed for both SDK constructors, bin/tick math, and `getAllProviders()` (37 entries).
- Live REST `find_routes` returned code 200 for SUI/USDC with `v=1999999`, for both input-fixed and output-fixed requests. A request omitting `v` returned code 4000, `version too low`.
- Checked local Markdown file links and Git whitespace errors.

No wallet signing, on-chain transaction submission, funded integration test, or Move compilation was performed. Published addresses are verified against the SDK release configuration, not independently resolved from live chain upgrade state. The `swap_v3` transaction-building service and every provider were not individually exercised. Example quote amounts and JSON responses remain illustrative.
