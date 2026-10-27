# Project guidance

This repository contains agent skills for the Cetus Aggregator V3 REST API, CLMM SDK/Move interface, DLMM SDK/Move interface, limit orders, and DCA on Sui.

## Layout

- `README.md`: installation, version matrix, and quick starts.
- `UPSTREAM.md`: dated upstream sources, migration notes, and verification limits.
- `skills/cetus-aggregator/{SKILL.md,README.md,reference.md}`: REST endpoints, schemas, and examples.
- `skills/cetus-clmm/{SKILL.md,README.md,reference/}`: CLMM operations and topic references, including flash loans.
- `skills/cetus-dlmm/{SKILL.md,README.md,reference/}`: DLMM pools, strategies, positions, swaps, and collection.
- `skills/cetus-limitorder/{SKILL.md,README.md,reference/}`: directional target-price orders, inverse-rate math, owner actions and atomic fills.
- `skills/cetus-dca/{SKILL.md,README.md,reference/}`: recurring orders, oracle/keeper signatures, user actions and atomic execution.
- `.claude/hooks/`: local command validation hooks.

## Documentation conventions

Keep each `SKILL.md` concise with YAML `name` and `description`, operation/parameter tables, and links to detailed references. Load topic files only as needed. Update the root README when adding skills. Keep shared version and address snapshots consistent across README and skill files.

## Upstream verification

Check npm dist-tags, published package types/source maps, official Cetus source repositories, and read-only API responses. Distinguish npm latest, SDK configuration snapshots, and live chain state. Do not label a version matrix tested unless the corresponding checks were actually run. See `UPSTREAM.md` for the current snapshot and validation scope.

The current SDK generation uses Sui 2.x with gRPC/GraphQL. Import `clmmMainnet` and `dlmmMainnet` from their respective SDK packages, not common-sdk. Set the sender before building funded transactions. DLMM opening with liquidity uses `Position.addLiquidityPayload` with the complete liquidity result and bin range.

## Sui and transaction handling

Coin types use `{package_id}::{module}::{struct}`. Amounts are integer smallest units; preserve precision with strings/BN. Original package IDs identify types; upgraded `published_at` addresses target Move calls. Prefer SDK configuration for call targets.

Aggregator flow: `find_routes` → `request_id` → `swap_v3` → unsigned bytes → wallet signing and submission. Keep `by_amount_in` consistent and include `v=1999999` in REST route requests. Building and quoting do not authorize signing or submitting transactions.

## Order skill source boundaries

Limit-order and DCA references are based on the user-provided `cetus-clmm-sui` checkout and published SDK tarballs. Each contract reference records source fingerprints and deployment differences. Do not equate local publication records, SDK version fields, and live chain state. Use production entrypoints only; test helpers differ from production semantics.

Limit-order expiry is milliseconds and its rate is the inverse of human target-per-pay price. DCA times are seconds, fees come from the input coin, and opening requires authorized oracle signatures. The DCA SDK close builder cancels pending orders; it does not delete them. Both protocols use shared indexed order objects and require external execution infrastructure.
