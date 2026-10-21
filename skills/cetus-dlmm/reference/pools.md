# DLMM — Pool Operations

SDK and Move examples for pool creation and queries. Parameter tables are in [SKILL.md](../SKILL.md). Bin math helpers are in [concepts.md](concepts.md).

## Contents

- [create_pool](#create_pool)
- [Pool lookup](#pool-lookup)

## create_pool

Create a new DLMM pool with a `bin_step` and an initial `active_id`.

```typescript
import { BinUtils } from '@cetusprotocol/dlmm-sdk'
import { Transaction } from '@mysten/sui/transactions'

const coin_type_a = '0x2::sui::SUI'
const coin_type_b = '0xdba34672e30cb065b1f93e3ab55318768fd6fef66c15942c9f7cb846e2f900e7::usdc::USDC'

const bin_step = 2
const active_id = BinUtils.getBinIdFromPrice('2.5', bin_step, true, 9, 6)

const tx = new Transaction()
const pool_result = sdk.Pool.createPoolPayload(
  { coin_type_a, coin_type_b, bin_step, base_factor: 1000, active_id },
  tx,
)

const txn = await sdk.FullClient.sendTransaction(signer, tx)
```

**Move (`cetusdlmm::pool`)**:

```move
let (receipt, new_pool) = registry::create_pool_v3<SUI, USDC>(
    registry, 2, 1000, 23000, // bin_step, base_factor, active_id
    string::utf8(b""), config, versioned, clock, ctx,
);
registry::destroy_receipt(receipt, new_pool, versioned);
```

## Pool lookup

```typescript
const pool = await sdk.Pool.getPool(poolAddress)
// pool.coin_type_a, pool.coin_type_b, pool.active_id, pool.bin_step,
// pool.reward_manager.rewards (for collecting rewards)
```

> **Version compatibility:** use the version snapshot in [SKILL.md](../SKILL.md). The current SDK uses Sui 2.x and gRPC/GraphQL; old JSON-RPC client integrations need migration.
