# DLMM — Fee & Reward Collection

SDK and Move examples for collecting LP fees and reward tokens. Parameter tables are in [SKILL.md](../SKILL.md).

## Contents

- [collect_position_fee](#collect_position_fee)
- [collect_position_reward](#collect_position_reward)
- [Bundling fee + rewards in one call](#bundling-fee--rewards-in-one-call)

## collect_position_fee

```typescript
const position = await sdk.Position.getPosition(positionAddress)
const pool = await sdk.Pool.getPool(position.pool_id)

const collect_fee_payload = await sdk.Position.collectFeePayload({
  pool_id: pool.id,
  position_id: positionAddress,
  coin_type_a: pool.coin_type_a,
  coin_type_b: pool.coin_type_b,
})

const txn = await sdk.FullClient.sendTransaction(signer, collect_fee_payload)
```

**Move (`cetusdlmm::pool`)**:

```move
let (coin_a, coin_b) = pool::collect_position_fee<SUI, USDC>(
    config, pool, position, versioned, ctx,
);
transfer::public_transfer(coin_a, ctx.sender());
transfer::public_transfer(coin_b, ctx.sender());
```

## collect_position_reward

**Move (`cetusdlmm::pool`)** — per reward coin type:

```move
let reward_coin = pool::collect_position_reward<SUI, USDC, CETUS>(
    config, pool, position, versioned, ctx,
);
transfer::public_transfer(reward_coin, ctx.sender());
```

Call `pool::update_position_fee_and_rewards(pool, position, config, versioned, clock)` first if you want freshly-accrued fees and rewards to settle on the position before collection.

## Bundling fee + rewards in one call

`sdk.Position.collectRewardAndFeePayload` accepts an array of positions and collects every reward coin plus LP fees in a single transaction:

```typescript
const pool = await sdk.Pool.getPool(pool_id)
const reward_coins = pool.reward_manager.rewards.map((r) => r.reward_coin)

const collect_payload = await sdk.Position.collectRewardAndFeePayload([
  {
    pool_id: pool.id,
    position_id: positionAddress,
    reward_coins,
    coin_type_a: pool.coin_type_a,
    coin_type_b: pool.coin_type_b,
  },
])

const txn = await sdk.FullClient.sendTransaction(signer, collect_payload)
```
