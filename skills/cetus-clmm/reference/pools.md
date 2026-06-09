# CLMM — Pool Operations

SDK and Move examples for pool creation and queries. Parameter tables are in [SKILL.md](../SKILL.md).

## Contents

- [create_pool](#create_pool)
- [create_pool_v3](#create_pool_v3)
- [fetch_pools](#fetch_pools)

## create_pool

Create a new CLMM pool with specified tick spacing and initial price.

```typescript
import BN from 'bn.js'
import { ClmmPoolUtil, TickMath, d } from '@cetusprotocol/common-sdk'

const coin_type_a = '0x2::sui::SUI'
const coin_type_b = '0xdba34672e30cb065b1f93e3ab55318768fd6fef66c15942c9f7cb846e2f900e7::usdc::USDC'

// sqrt(price) * 2^64 where price is B-per-A adjusted for decimals
const initialize_sqrt_price = TickMath.priceToSqrtPriceX64(d(2.5), 9, 6).toString()

const tick_spacing = 10
const current_tick_index = TickMath.sqrtPriceX64ToTickIndex(new BN(initialize_sqrt_price))

const tick_lower = TickMath.getPrevInitializeTickIndex(current_tick_index.toNumber(), tick_spacing)
const tick_upper = TickMath.getNextInitializeTickIndex(current_tick_index.toNumber(), tick_spacing)

const fix_coin_amount = new BN(1000000000) // 1 SUI
const fix_amount_a = true
const slippage = 0.05

const liquidity_input = ClmmPoolUtil.estLiquidityAndCoinAmountFromOneAmounts(
  tick_lower,
  tick_upper,
  fix_coin_amount,
  fix_amount_a,
  true,
  slippage,
  new BN(initialize_sqrt_price),
)

const amount_a = fix_amount_a ? fix_coin_amount.toNumber() : liquidity_input.coin_amount_limit_a.toNumber()
const amount_b = fix_amount_a ? liquidity_input.coin_amount_limit_b.toNumber() : fix_coin_amount.toNumber()

const coinMetadataA = await sdk.FullClient.getCoinMetadata({ coinType: coin_type_a })
const coinMetadataB = await sdk.FullClient.getCoinMetadata({ coinType: coin_type_b })

const create_pool_payload = sdk.Pool.createPoolPayload({
  coin_type_a,
  coin_type_b,
  tick_spacing,
  initialize_sqrt_price,
  uri: '',
  amount_a,
  amount_b,
  fix_amount_a,
  tick_lower,
  tick_upper,
  metadata_a: coinMetadataA.id,
  metadata_b: coinMetadataB.id,
})

const txn = await sdk.FullClient.sendTransaction(signer, create_pool_payload)
```

**Move (`cetus_integrate::pool_script`)**:

```move
pool_script::create_pool<SUI, USDC>(
    config,
    pools,
    10,                                    // tick_spacing
    29189415097064819712,                  // initialize_sqrt_price (1 SUI = 2.5 USDC)
    string::utf8(b"https://example.com/position"),
    clock,
    ctx,
);
```

## create_pool_v3

Create pool and seed an initial liquidity position in a single transaction.

**Move (`cetus_integrate::pool_creator_v3`)**:

```move
pool_creator_v3::create_pool_v3<SUI, USDC>(
    config,
    pools,
    10,                                    // tick_spacing
    29189415097064819712,                  // initialize_price
    string::utf8(b"https://example.com"),
    0,                                     // tick_lower_idx (full range)
    443580,                                // tick_upper_idx (full range)
    coin_a,
    coin_b,
    true,                                  // fix_amount_a
    clock,
    ctx,
);
```

## fetch_pools

Paginated pool listing — emits `FetchPoolsEvent`.

**Move (`cetus_integrate::fetcher_script`)**:

```move
fetcher_script::fetch_pools(
    pools,
    vector::empty<ID>(),  // empty = start of list
    10,                   // limit
);
```

TypeScript helper:

```typescript
const pool = await sdk.Pool.getPool(poolAddress)
// pool.coin_type_a, pool.coin_type_b, pool.current_sqrt_price, pool.tick_spacing
```
