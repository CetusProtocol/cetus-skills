# CLMM — Position Management

SDK and Move examples for opening, closing, and inspecting positions. Parameter tables are in [SKILL.md](../SKILL.md). Tick math helpers are in [concepts.md](concepts.md).

## Contents

- [open_position](#open_position)
- [open_position_with_liquidity_with_all](#open_position_with_liquidity_with_all)
- [close_position](#close_position)
- [Position structure](#position-structure)

## open_position

Open an empty position NFT within a tick range.

```typescript
import { TickMath } from '@cetusprotocol/common-sdk'

const pool = await sdk.Pool.getPool(poolAddress)
const current_tick_index = Number(pool.current_tick_index)
const tick_spacing = Number(pool.tick_spacing)

const tick_lower = TickMath.getPrevInitializeTickIndex(current_tick_index, tick_spacing)
const tick_upper = TickMath.getNextInitializeTickIndex(current_tick_index, tick_spacing)

const open_position_payload = sdk.Position.openPositionPayload({
  pool_id: pool.id,
  tick_lower: tick_lower.toString(),
  tick_upper: tick_upper.toString(),
  coin_type_a: pool.coin_type_a,
  coin_type_b: pool.coin_type_b,
})

const txn = await sdk.FullClient.sendTransaction(signer, open_position_payload)
```

**Move (`cetus_integrate::pool_script`)**:

```move
pool_script::open_position<SUI, USDC>(config, pool, 100, 200, ctx);
// Position NFT transferred to sender
```

## open_position_with_liquidity_with_all

Open a position and add liquidity using both coins in one call. See [liquidity.md](liquidity.md) for SDK distribution math (same as `add_liquidity_fix_coin_with_all`).

**Move (`cetus_integrate::pool_script`)**:

```move
pool_script::open_position_with_liquidity_with_all<SUI, USDC>(
    config, pool,
    100, 200,                  // tick_lower_idx, tick_upper_idx
    coins_a, coins_b,
    1000000000, 2500000,       // amount_a (1 SUI), amount_b (2.5 USDC)
    true,                      // fix_amount_a
    clock, ctx,
);
```

## close_position

Close position, remove all liquidity, collect fees and rewards atomically.

```typescript
import BN from 'bn.js'
import { ClmmPoolUtil, TickMath, Percentage, adjustForCoinSlippage } from '@cetusprotocol/common-sdk'

const pool = await sdk.Pool.getPool(pool_id)
const position = await sdk.Position.getPositionById(pos_id)

const lower_sqrt_price = TickMath.tickIndexToSqrtPriceX64(Number(position.tick_lower_index))
const upper_sqrt_price = TickMath.tickIndexToSqrtPriceX64(Number(position.tick_upper_index))

const slippage_tolerance = new Percentage(new BN(5), new BN(100)) // 5%
const coin_amounts = ClmmPoolUtil.getCoinAmountFromLiquidity(
  new BN(position.liquidity),
  new BN(pool.current_sqrt_price),
  lower_sqrt_price,
  upper_sqrt_price,
  false,
)
const { coin_amount_limit_a, coin_amount_limit_b } = adjustForCoinSlippage(coin_amounts, slippage_tolerance, false)

const rewarder_coin_types = pool.rewarder_infos.map((r) => r.coin_type)

const close_position_payload = await sdk.Position.closePositionPayload({
  coin_type_a: pool.coin_type_a,
  coin_type_b: pool.coin_type_b,
  min_amount_a: coin_amount_limit_a.toString(),
  min_amount_b: coin_amount_limit_b.toString(),
  rewarder_coin_types,
  pool_id: pool.id,
  pos_id,
  collect_fee: true,
})

const txn = await sdk.FullClient.sendTransaction(signer, close_position_payload)
```

**Move (`cetus_integrate::pool_script`)**:

```move
pool_script::close_position<SUI, USDC>(
    config, pool,
    position_nft,
    0, 0,        // min_amount_a, min_amount_b (set realistic slippage limits in production)
    clock, ctx,
);
// Coins transferred to sender, NFT burned
```

## Position structure

Position NFT fields:

| Field | Type | Description |
|-------|------|-------------|
| pool | ID | Pool object ID |
| tick_lower | I32 | Lower tick index (signed) |
| tick_upper | I32 | Upper tick index (signed) |
| liquidity | u128 | Current liquidity amount |
