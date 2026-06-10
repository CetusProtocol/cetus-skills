# DLMM — Liquidity Operations

SDK and Move examples for add / remove liquidity. Parameter tables are in [SKILL.md](../SKILL.md).

## Contents

- [add_liquidity (router)](#add_liquidity-router)
- [remove_liquidity](#remove_liquidity)
- [remove_liquidity_by_percent](#remove_liquidity_by_percent)

## add_liquidity (router)

Append liquidity to an existing position. SDK computes per-bin distribution; the router handles repayment.

```typescript
import { StrategyType } from '@cetusprotocol/dlmm-sdk'

const position = await sdk.Position.getPosition(positionAddress)
const pool = await sdk.Pool.getPool(position.pool_id)

const bin_infos = await sdk.Position.calculateAddLiquidityInfo({
  active_id: pool.active_id,
  bin_step: pool.bin_step,
  lower_bin_id: position.lower_bin_id,
  upper_bin_id: position.upper_bin_id,
  amount_a_in_active_bin: '0',
  amount_b_in_active_bin: '0',
  strategy_type: StrategyType.Spot,
  coin_amount: '500000000', // 0.5 SUI
  fix_amount_a: true,
})

const add_liquidity_payload = await sdk.Position.addLiquidityPayload({
  pool_id: pool.id,
  position_id: positionAddress,
  coin_type_a: pool.coin_type_a,
  coin_type_b: pool.coin_type_b,
  bin_infos: bin_infos.bins,
  strategy_type: StrategyType.Spot,
})

const txn = await sdk.FullClient.sendTransaction(signer, add_liquidity_payload)
```

**Move (`dlmmrouter::add_liquidity`)**:

```move
add_liquidity::add_liquidity<SUI, USDC>(
    pool, position, coin_a, coin_b,
    vector[23000, 23001, 23002],                       // bins
    vector[166666666, 166666667, 166666667],           // amounts_a (~0.5 SUI)
    vector[0, 0, 0],                                    // amounts_b
    config, versioned, clock, ctx,
);
```

## remove_liquidity

Remove a specific share amount from each targeted bin (direct call to `cetusdlmm::pool`).

```typescript
const position = await sdk.Position.getPosition(positionAddress)
const pool = await sdk.Pool.getPool(position.pool_id)

const remove_payload = await sdk.Position.removeLiquidityPayload({
  pool_id: pool.id,
  position_id: positionAddress,
  coin_type_a: pool.coin_type_a,
  coin_type_b: pool.coin_type_b,
  bin_ids: [23000, 23001, 23002],
  liquidity_shares: ['50000000', '50000000', '50000000'],
})

const txn = await sdk.FullClient.sendTransaction(signer, remove_payload)
```

**Move (`cetusdlmm::pool`)**:

```move
let (coin_a, coin_b) = pool::remove_liquidity<SUI, USDC>(
    config, pool, position,
    vector[i32::from(23000), i32::from(23001), i32::from(23002)],
    vector[50000000, 50000000, 50000000],
    versioned, clock, ctx,
);
transfer::public_transfer(coin_a, ctx.sender());
transfer::public_transfer(coin_b, ctx.sender());
```

## remove_liquidity_by_percent

Removes a percentage from each listed bin. `percent` is basis points × 100 — `10000 = 100%`, `5000 = 50%`.

**Move (`cetusdlmm::pool`)**:

```move
let (coin_a, coin_b) = pool::remove_liquidity_by_percent<SUI, USDC>(
    config, pool, position,
    vector[i32::from(23000), i32::from(23001), i32::from(23002)],
    5000,                                    // 50%
    versioned, clock, ctx,
);
```
