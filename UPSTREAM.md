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

## Limit-order and DCA skills (2026-10-26)

Added `cetus-limitorder` and `cetus-dca` from the user-provided local `cetus-clmm-sui` checkout at commit `6909b262aac6b54013df8efd967d359b46512feb`. Read `limitorder/sources/{limit_order,config}.move`, `cetus_dca/sources/{order,config}.move`, and each package's publication metadata. The contract checkout was not modified. Each new skill's contract reference records SHA-256 source fingerprints and exact production entrypoint signatures; test-only helpers are excluded.

Compared published npm `latest` tarballs for [limit-sdk 1.2.6](https://registry.npmjs.org/@cetusprotocol/limit-sdk/1.2.6) and [dca-sdk 1.2.5](https://registry.npmjs.org/@cetusprotocol/dca-sdk/1.2.5), including declarations, builders, utilities, and source-map mainnet configuration. Examples pin common-sdk 1.4.3 and Sui 2.31.2. Limit SDK also requires `blakejs`.

Deployment differences are explicit:

- Local limitorder `Published.toml` / `Move.toml` records v3 (`0x37d628…`), local config source has gate VERSION 4, and limit-sdk 1.2.6 targets configured v4 (`0xd36484…`). ABI/source equality to that target was not verified.
- Local DCA publication and source gate are v4 (`0xa893af…`); the SDK targets that address but retains `dca.version = 2`. This field is not live deployment/version-gate proof.
- DCA oracle/keeper signing-service endpoints and the protocol fee-vault object ID are not supplied by SDK config. Skills explain the required authorization and fee-vault discovery rather than inventing them.

Validation for the additions: skill frontmatter validation, local Markdown links, exact production signature comparison, strict TypeScript checking of all 10 new example blocks, and offline SDK builder inspection of 7 paths against the local ABI. The builder smoke checks cover limit-order place/claim/cancel (with fixture pair-indexer lookup), DCA open/withdraw/cancel, inverse-rate encoding and Sui PTB argument layout. This does not test oracle authenticity, keeper authorization, funded simulation, on-chain fills, or contract deployment. No signing, submission, new Move build/test, or source-verification run was performed. Earlier verification results above remain scoped to their original date and SDKs.
