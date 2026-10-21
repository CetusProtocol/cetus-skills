# Project guidance

This repository contains agent skills for the Cetus Aggregator V3 REST API, CLMM SDK/Move interface, and DLMM SDK/Move interface on Sui.

## Layout

- `README.md`: installation, version matrix, and quick starts.
- `UPSTREAM.md`: dated upstream sources, migration notes, and verification limits.
- `skills/cetus-aggregator/{SKILL.md,README.md,reference.md}`: REST endpoints, schemas, and examples.
- `skills/cetus-clmm/{SKILL.md,README.md,reference/}`: CLMM operations and topic references, including flash loans.
- `skills/cetus-dlmm/{SKILL.md,README.md,reference/}`: DLMM pools, strategies, positions, swaps, and collection.
- `.claude/hooks/`: local command validation hooks.

## Documentation conventions

Keep each `SKILL.md` concise with YAML `name` and `description`, operation/parameter tables, and links to detailed references. Load topic files only as needed. Update the root README when adding skills. Keep shared version and address snapshots consistent across README and skill files.

## Upstream verification

Check npm dist-tags, published package types/source maps, official Cetus source repositories, and read-only API responses. Distinguish npm latest, SDK configuration snapshots, and live chain state. Do not label a version matrix tested unless the corresponding checks were actually run. See `UPSTREAM.md` for the current snapshot and validation scope.

The current SDK generation uses Sui 2.x with gRPC/GraphQL. Import `clmmMainnet` and `dlmmMainnet` from their respective SDK packages, not common-sdk. Set the sender before building funded transactions. DLMM opening with liquidity uses `Position.addLiquidityPayload` with the complete liquidity result and bin range.

## Sui and transaction handling

Coin types use `{package_id}::{module}::{struct}`. Amounts are integer smallest units; preserve precision with strings/BN. Original package IDs identify types; upgraded `published_at` addresses target Move calls. Prefer SDK configuration for call targets.

Aggregator flow: `find_routes` → `request_id` → `swap_v3` → unsigned bytes → wallet signing and submission. Keep `by_amount_in` consistent and include `v=1999999` in REST route requests. Building and quoting do not authorize signing or submitting transactions.
