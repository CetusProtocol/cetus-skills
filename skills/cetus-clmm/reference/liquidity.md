# CLMM — Liquidity Operations

SDK and Move examples for adding and removing liquidity. Parameter tables are in [SKILL.md](../SKILL.md).

## Contents

- [Two approaches: by liquidity vs by coin amount](#two-approaches-by-liquidity-vs-by-coin-amount)
- [add_liquidity_fix_coin_with_all](#add_liquidity_fix_coin_with_all)
- [remove_liquidity](#remove_liquidity)

## Two approaches: by liquidity vs by coin amount

| Approach | Function family | Input | Behavior |
|----------|-----------------|-------|----------|
| By liquidity | `add_liquidity_*` | `delta_liquidity` (u128) | Specify exact liquidity, SDK derives required coins |
| By coin amount | `add_liquidity_fix_coin_*` | `amount` (u64) + `fix_amount_a` (bool) | Specify coin amount, SDK derives liquidity |

Default to `add_liquidity_fix_coin_*` — users think in coin amounts, not liquidity units.

## add_liquidity_fix_coin_with_all

```typescript
import BN from 'bn.js'
import { ClmmPoolUtil } from '@cetusprotocol/common-sdk'

const position = await sdk.Position.getPosition(positionAddress)
const pool = await sdk.Pool.getPool(position.pool)

const fix_coin_amount = new BN(500000000) // 0.5 SUI
const fix_amount_a = true
const slippage = 0.05

const liquidity_input = ClmmPoolUtil.estLiquidityAndCoinAmountFromOneAmounts(
  position.tick_lower_index,
  position.tick_upper_index,
  fix_coin_amount,
  fix_amount_a,
  true,
  slippage,
  pool.current_sqrt_price,
)

const amount_a = fix_amount_a ? fix_coin_amount.toNumber() : Number(liquidity_input.coin_amount_limit_a)
const amount_b = fix_amount_a ? Number(liquidity_input.coin_amount_limit_b) : fix_coin_amount.toNumber()

const add_liquidity_payload = await sdk.Position.createAddLiquidityFixTokenPayload({
  coin_type_a: pool.coin_type_a,
  coin_type_b: pool.coin_type_b,
  pool_id: pool.id,
  tick_lower: position.tick_lower_index.toString(),
  tick_upper: position.tick_upper_index.toString(),
  fix_amount_a,
  amount_a,
  amount_b,
  slippage,
  is_open: false,
  pos_id: position.pos_object_id ?? positionAddress,
  rewarder_coin_types: [],
  collect_fee: true,
})

const txn = await sdk.FullClient.sendTransaction(signer, add_liquidity_payload)
```

**Move (`cetus_integrate::pool_script`)**:

```move
pool_script::add_liquidity_fix_coin_with_all<SUI, USDC>(
    config, pool, position_nft,
    coins_a, coins_b,
    500000000, 1250000,        // amount_a (0.5 SUI), amount_b (1.25 USDC)
    true,                       // fix_amount_a
    clock, ctx,
);
```

## remove_liquidity

```typescript
import BN from 'bn.js'
import { ClmmPoolUtil, TickMath, Percentage, adjustForCoinSlippage } from '@cetusprotocol/common-sdk'

const pool = await sdk.Pool.getPool(pool_id)
const position = await sdk.Position.getPositionById(pos_id)
const delta_liquidity = new BN('...') // u128, e.g. half the position liquidity

const lower_sqrt_price = TickMath.tickIndexToSqrtPriceX64(Number(position.tick_lower_index))
const upper_sqrt_price = TickMath.tickIndexToSqrtPriceX64(Number(position.tick_upper_index))

const slippage_tolerance = new Percentage(new BN(5), new BN(100)) // 5%
const coin_amounts = ClmmPoolUtil.getCoinAmountFromLiquidity(
  delta_liquidity,
  new BN(pool.current_sqrt_price),
  lower_sqrt_price,
  upper_sqrt_price,
  false,
)
const { coin_amount_limit_a, coin_amount_limit_b } = adjustForCoinSlippage(coin_amounts, slippage_tolerance, false)

const rewarder_coin_types = pool.rewarder_infos.map((r) => r.coin_type)

const remove_liquidity_payload = await sdk.Position.removeLiquidityPayload({
  pool_id: pool.id,
  pos_id,
  coin_type_a: pool.coin_type_a,
  coin_type_b: pool.coin_type_b,
  delta_liquidity: delta_liquidity.toString(),
  min_amount_a: coin_amount_limit_a.toString(),
  min_amount_b: coin_amount_limit_b.toString(),
  rewarder_coin_types,
  collect_fee: true,
})

const txn = await sdk.FullClient.sendTransaction(signer, remove_liquidity_payload)
```

**Move (`cetus_integrate::pool_script`)**:

```move
pool_script::remove_liquidity<SUI, USDC>(
    config, pool, position_nft,
    500000,      // delta_liquidity
    0, 0,        // min_amount_a, min_amount_b (set realistic limits in production)
    clock, ctx,
);
```
