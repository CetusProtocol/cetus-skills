# DLMM — Position Management

SDK and Move examples for opening and closing positions with the three strategy types. Parameter tables are in [SKILL.md](../SKILL.md). Strategy semantics are in [concepts.md](concepts.md).

## Contents

- [open_position (router) — Spot](#open_position-router--spot)
- [open_position (router) — Curve](#open_position-router--curve)
- [open_position (router) — BidAsk](#open_position-router--bidask)
- [close_position](#close_position)
- [Position structure](#position-structure)

## open_position (router) — Spot

Uniform distribution across all bins in range.

```typescript
import { StrategyType } from '@cetusprotocol/dlmm-sdk'

const pool = await sdk.Pool.getPool(poolAddress)
const lower_bin_id = pool.active_id - 10
const upper_bin_id = pool.active_id + 10

const bin_infos = await sdk.Position.calculateAddLiquidityInfo({
  active_id: pool.active_id,
  bin_step: pool.bin_step,
  lower_bin_id,
  upper_bin_id,
  pool_id: pool.id, // fetch real active-bin balances
  strategy_type: StrategyType.Spot,
  coin_amount: '1000000000', // 1 SUI
  fix_amount_a: true,
})

const open_position_payload = await sdk.Position.addLiquidityPayload({
  pool_id: pool.id,
  coin_type_a: pool.coin_type_a,
  coin_type_b: pool.coin_type_b,
  lower_bin_id: pool.active_id - 10,
  upper_bin_id: pool.active_id + 10,
  active_id: pool.active_id,
  bin_step: pool.bin_step,
  max_price_slippage: 0.01,
  bin_infos,
  strategy_type: StrategyType.Spot,
})

const txn = await sdk.FullClient.sendTransaction(signer, open_position_payload)
```

**Move (`dlmmrouter::add_liquidity`)**:

```move
add_liquidity::open_position<SUI, USDC>(
    pool, coin_a, coin_b,
    vector[23000, 23001, 23002],                       // bins
    vector[333333333, 333333333, 333333334],           // amounts_a (~1 SUI)
    vector[0, 0, 0],                                    // amounts_b
    config, versioned, clock, ctx,
);
```

## open_position (router) — Curve

Concentrates more liquidity near the active bin. Only the `strategy_type` field changes:

```typescript
const bin_infos_curve = await sdk.Position.calculateAddLiquidityInfo({
  /* ...same as Spot... */
  strategy_type: StrategyType.Curve,
})

await sdk.Position.addLiquidityPayload({
  /* ...same as Spot... */
  bin_infos: bin_infos_curve,
  strategy_type: StrategyType.Curve,
})
```

## open_position (router) — BidAsk

Concentrates liquidity at the ends of the range (market-maker spread).

```typescript
const bin_infos_bidask = await sdk.Position.calculateAddLiquidityInfo({
  /* ...same as Spot... */
  strategy_type: StrategyType.BidAsk,
})

await sdk.Position.addLiquidityPayload({
  /* ...same as Spot... */
  bin_infos: bin_infos_bidask,
  strategy_type: StrategyType.BidAsk,
})
```

## close_position

Closes the position, removes all liquidity, and collects fees. Requires destroying the close certificate to finalize on-chain.

```typescript
const close_payload = await sdk.Position.closePositionPayload({
  pool_id: pool.id,
  position_id: positionAddress,
  reward_coins: pool.reward_manager.rewards.map((r) => r.reward_coin),
  coin_type_a: pool.coin_type_a,
  coin_type_b: pool.coin_type_b,
})

const txn = await sdk.FullClient.sendTransaction(signer, close_payload)
```

**Move (`cetusdlmm::pool`)**:

```move
let (mut close_cert, balance_a, balance_b) = pool::close_position<SUI, USDC>(
    pool, position, config,
    versioned, clock, ctx,
);
// Repeat for every reward coin configured on this pool:
let reward = pool::take_reward_from_close_position_cert<SUI, USDC, CETUS>(
    pool, &mut close_cert, versioned,
);
transfer::public_transfer(coin::from_balance(reward, ctx), ctx.sender());
pool::destroy_close_position_cert(close_cert, versioned);
transfer::public_transfer(coin::from_balance(balance_a, ctx), ctx.sender());
transfer::public_transfer(coin::from_balance(balance_b, ctx), ctx.sender());
```

## Position structure

| Field | Type | Description |
|-------|------|-------------|
| pool_id | ID | Pool object ID |
| lower_bin_id | I32 | Lower bound bin ID |
| upper_bin_id | I32 | Upper bound bin ID |
| liquidity_shares | `vector<u128>` | Liquidity shares — one entry per bin in range |
| index | u64 | Position index within the pool |

Unlike CLMM (single `liquidity` value per position), DLMM stores per-bin shares.
