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

const create_pool_payload = sdk.Pool.createPoolPayload(
  { coin_type_a, coin_type_b, bin_step, active_id },
  new Transaction(),
)

const txn = await sdk.FullClient.sendTransaction(signer, create_pool_payload)
```

**Move (`cetusdlmm::pool`)**:

```move
pool::create_pool<SUI, USDC>(
    config,
    registry,
    2,                    // bin_step
    i32::from(23000),     // active_id
    versioned,
    ctx,
);
```

## Pool lookup

```typescript
const pool = await sdk.Pool.getPool(poolAddress)
// pool.coin_type_a, pool.coin_type_b, pool.active_id, pool.bin_step,
// pool.reward_manager.rewards (for collecting rewards)
```

> **Version compatibility:** `dlmm-sdk@1.2.6` is sensitive to `common-sdk` API changes. If `getPool` or `preSwapQuote` throw on unrelated arg shapes, verify the pinned versions in [SKILL.md](../SKILL.md) are installed.
