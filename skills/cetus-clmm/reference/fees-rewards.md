# CLMM — Fee & Reward Collection

SDK and Move examples for collecting LP fees and rewarder payouts. Parameter tables are in [SKILL.md](../SKILL.md).

## Contents

- [collect_fee](#collect_fee)
- [collect_reward](#collect_reward)
- [fetch_position_fees](#fetch_position_fees)

## collect_fee

Bundles LP fees and rewarder rewards in one transaction via the SDK rewarder helper. Set `collect_fee: true` to fold fee collection into the same payload.

```typescript
const position = await sdk.Position.getPosition(positionAddress)
const pool = await sdk.Pool.getPool(position.pool)

const rewarder_coin_types = pool.rewarder_infos.map((r) => r.coin_type)

const collect_rewarder_payload = await sdk.Rewarder.collectRewarderPayload({
  pool_id: pool.id,
  pos_id: positionAddress,
  rewarder_coin_types,
  coin_type_a: pool.coin_type_a,
  coin_type_b: pool.coin_type_b,
  collect_fee: true,
})

const txn = await sdk.FullClient.sendTransaction(signer, collect_rewarder_payload)
```

**Move (`cetus_integrate::pool_script`)**:

```move
pool_script::collect_fee<SUI, USDC>(config, pool, position, ctx);
// Fees transferred to sender
```

## collect_reward

SDK v2 collects rewards through the same `Rewarder.collectRewarderPayload` helper as `collect_fee` (set `collect_fee: true` to bundle).

**Move (`cetus_integrate::pool_script`)** — per reward coin type:

```move
pool_script::collect_reward<SUI, USDC, CETUS>(
    config, pool, position_nft,
    vault,         // RewarderGlobalVault
    true,          // collect_fee
    clock, ctx,
);
// CETUS rewards transferred to sender
```

## fetch_position_fees

Query claimable fees without collecting — result is emitted as `FetchPositionFeesEvent`.

**Move (`cetus_integrate::fetcher_script`)**:

```move
fetcher_script::fetch_position_fees<SUI, USDC>(config, pool, position_id);
```
