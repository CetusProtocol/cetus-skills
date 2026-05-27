# Cetus CLMM — Reference

Detailed parameter schemas, Move contract examples, and integration patterns.

## SDK Setup & Initialization

### Installation

```bash
npm install @cetusprotocol/common-sdk@1.3.3 @cetusprotocol/sui-clmm-sdk@1.4.1
```

### SDK Initialization

```typescript
import { CetusClmmSDK } from '@cetusprotocol/sui-clmm-sdk'
import { clmmMainnet } from '@cetusprotocol/common-sdk'
import { Ed25519Keypair } from '@mysten/sui/keypairs/ed25519'

// Initialize SDK for mainnet (SDK v2)
const sdk = CetusClmmSDK.createSDK(clmmMainnet)

// Set signer (for sending transactions)
const signer = Ed25519Keypair.fromSecretKey(yourSecretKey)
sdk.setSenderAddress(signer.getPublicKey().toSuiAddress())
```

### Contract Object IDs (Mainnet)

```typescript
// These are automatically configured in the SDK, but can be referenced:
const MAINNET_CONFIG = {
  clmmPackage: '0x1eabed72c53feb3805120a081dc15963c204dc8d091542592abaf7a35689b2fb',
  integratePackage: '0x996c4d9480708fb8b92aa7acf819fb0497b5ec8e65ba06601cae2fb6db3312c3',
  globalConfig: '0xdaa46292632c3c4d8f31f23ea0f9b36a28ff3677e9684980e4438403a67a3d8f',
  pools: '0xf699e7f2276f5c9a75944b37a0c5b5d9ddfd2471bf6242483b03ab2887d198d0',
}
```

### Getting Pool Object

```typescript
// Fetch pool by address
const poolAddress = '0x...' // Pool object ID
const pool = await sdk.Pool.getPool(poolAddress)

console.log(pool.coin_type_a)     // Coin A type
console.log(pool.coin_type_b)     // Coin B type
console.log(pool.current_sqrt_price) // Current price
console.log(pool.tick_spacing)     // Tick spacing
```

---

## Pool Operations

### create_pool

Create a new CLMM pool with specified tick spacing and initial price.

**SDK Example (TypeScript)**:

```typescript
import BN from 'bn.js'
import { ClmmPoolUtil, TickMath, d } from '@cetusprotocol/common-sdk'

// Define coin types
const coin_type_a = '0x2::sui::SUI'
const coin_type_b = '0xdba34672e30cb065b1f93e3ab55318768fd6fef66c15942c9f7cb846e2f900e7::usdc::USDC'

// Calculate initial sqrt price (1 SUI = 2.5 USDC)
const initialize_sqrt_price = TickMath.priceToSqrtPriceX64(
  d(2.5),  // price
  9,       // decimals A (SUI)
  6        // decimals B (USDC)
).toString()

const tick_spacing = 10
const current_tick_index = TickMath.sqrtPriceX64ToTickIndex(new BN(initialize_sqrt_price))

// Calculate tick range for initial liquidity
const tick_lower = TickMath.getPrevInitializeTickIndex(
  current_tick_index.toNumber(),
  tick_spacing
)
const tick_upper = TickMath.getNextInitializeTickIndex(
  current_tick_index.toNumber(),
  tick_spacing
)

// Estimate liquidity from coin amount
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
  new BN(initialize_sqrt_price)
)

const amount_a = fix_amount_a ? fix_coin_amount.toNumber() : liquidity_input.coin_amount_limit_a.toNumber()
const amount_b = fix_amount_a ? liquidity_input.coin_amount_limit_b.toNumber() : fix_coin_amount.toNumber()

// Get coin metadata
const coinMetadataA = await sdk.FullClient.getCoinMetadata({ coinType: coin_type_a })
const coinMetadataB = await sdk.FullClient.getCoinMetadata({ coinType: coin_type_b })

// Build transaction
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

// Execute transaction
const txn = await sdk.FullClient.sendTransaction(signer, create_pool_payload)
console.log('Pool created:', txn.digest)
```

**Module**: `cetus_integrate::pool_script`

**Parameters**:

| Name | Type | Required | Description |
|------|------|----------|-------------|
| global_config | &GlobalConfig | Y | Global CLMM config object |
| pools | &mut Pools | Y | Pools registry object |
| tick_spacing | u32 | Y | Minimum tick interval (1, 2, 10, 60, 200) |
| initialize_price | u128 | Y | Initial sqrt price of pool |
| url | String | Y | Position NFT metadata URI |
| clock | &Clock | Y | Sui clock object (0x6) |

**Move Example**:

```move
use cetus_integrate::pool_script;
use sui::clock::Clock;

public entry fun create_sui_usdc_pool(
    config: &GlobalConfig,
    pools: &mut Pools,
    clock: &Clock,
    ctx: &mut TxContext
) {
    // tick_spacing = 10 (0.1% per tick)
    // initialize_price = sqrt(2.5) * 2^64 ≈ 29189415097064819712 (1 SUI = 2.5 USDC)
    pool_script::create_pool<SUI, USDC>(
        config,
        pools,
        10,
        29189415097064819712,
        string::utf8(b"https://example.com/position"),
        clock,
        ctx
    );
}
```

### create_pool_v3

Create pool with initial liquidity position in one transaction.

**Module**: `cetus_integrate::pool_creator_v3`

**Parameters**:

| Name | Type | Required | Description |
|------|------|----------|-------------|
| config | &GlobalConfig | Y | Global CLMM config object |
| pools | &mut Pools | Y | Pools registry object |
| tick_spacing | u32 | Y | Minimum tick interval |
| initialize_price | u128 | Y | Initial sqrt price |
| url | String | Y | Position NFT metadata URI |
| tick_lower_idx | u32 | Y | Lower tick of initial position |
| tick_upper_idx | u32 | Y | Upper tick of initial position |
| coin_a | &mut Coin<A> | Y | Coin A to provide liquidity |
| coin_b | &mut Coin<B> | Y | Coin B to provide liquidity |
| fix_amount_a | bool | Y | true = fix A amount, false = fix B amount |
| clock | &Clock | Y | Sui clock object |

**Move Example**:

```move
use cetus_integrate::pool_creator_v3;

public entry fun create_pool_with_liquidity(
    config: &GlobalConfig,
    pools: &mut Pools,
    coin_a: &mut Coin<SUI>,
    coin_b: &mut Coin<USDC>,
    clock: &Clock,
    ctx: &mut TxContext
) {
    pool_creator_v3::create_pool_v3<SUI, USDC>(
        config,
        pools,
        10,                                    // tick_spacing
        29189415097064819712,                  // initialize_price
        string::utf8(b"https://example.com"), // url
        0,                                     // tick_lower_idx (full range)
        443580,                                // tick_upper_idx (full range)
        coin_a,
        coin_b,
        true,                                  // fix_amount_a
        clock,
        ctx
    );
}
```

### fetch_pools

Query pool list with pagination.

**Module**: `cetus_integrate::fetcher_script`

**Parameters**:

| Name | Type | Required | Description |
|------|------|----------|-------------|
| pools | &Pools | Y | Pools registry object |
| start | vector<ID> | Y | Starting pool ID (empty for first page) |
| limit | u64 | Y | Max pools to return |

**Move Example**:

```move
use cetus_integrate::fetcher_script;

public entry fun query_pools(
    pools: &Pools
) {
    // Fetch first 10 pools
    fetcher_script::fetch_pools(
        pools,
        vector::empty<ID>(),
        10
    );
    // Result emitted as FetchPoolsEvent
}
```

---

## Position Management

### open_position

Open empty position NFT within specified tick range.

**SDK Example (TypeScript)**:

```typescript
import BN from 'bn.js'
import { TickMath } from '@cetusprotocol/common-sdk'

// Get pool
const pool = await sdk.Pool.getPool(poolAddress)

// Define tick range (example: ±10% around current price)
const current_tick_index = new BN(pool.current_tick_index).toNumber()
const tick_spacing = new BN(pool.tick_spacing).toNumber()

const tick_lower = TickMath.getPrevInitializeTickIndex(current_tick_index, tick_spacing)
const tick_upper = TickMath.getNextInitializeTickIndex(current_tick_index, tick_spacing)

// Build open position payload
const open_position_payload = sdk.Position.openPositionPayload({
  pool_id: pool.id,
  tick_lower: tick_lower.toString(),
  tick_upper: tick_upper.toString(),
  coin_type_a: pool.coin_type_a,
  coin_type_b: pool.coin_type_b,
})

const txn = await sdk.FullClient.sendTransaction(signer, open_position_payload)
console.log('Position opened:', txn.digest)
```

**Module**: `cetus_integrate::pool_script`

**Parameters**:

| Name | Type | Required | Description |
|------|------|----------|-------------|
| config | &GlobalConfig | Y | Global CLMM config object |
| pool | &mut Pool<A, B> | Y | Pool object for coin pair |
| tick_lower | u32 | Y | Lower tick index |
| tick_upper | u32 | Y | Upper tick index |

**Move Example**:

```move
use cetus_integrate::pool_script;

public entry fun open_narrow_position(
    config: &GlobalConfig,
    pool: &mut Pool<SUI, USDC>,
    ctx: &mut TxContext
) {
    // Open position in range [100, 200]
    pool_script::open_position<SUI, USDC>(
        config,
        pool,
        100,  // tick_lower
        200,  // tick_upper
        ctx
    );
    // Position NFT transferred to sender
}
```

### open_position_with_liquidity_with_all

Open position and add liquidity using both coins.

**Module**: `cetus_integrate::pool_script`

**Parameters**:

| Name | Type | Required | Description |
|------|------|----------|-------------|
| config | &GlobalConfig | Y | Global CLMM config object |
| pool | &mut Pool<A, B> | Y | Pool object |
| tick_lower_idx | u32 | Y | Lower tick index |
| tick_upper_idx | u32 | Y | Upper tick index |
| coins_a | vector<Coin<A>> | Y | Coin A vector to merge |
| coins_b | vector<Coin<B>> | Y | Coin B vector to merge |
| amount_a | u64 | Y | Max coin A to use |
| amount_b | u64 | Y | Max coin B to use |
| fix_amount_a | bool | Y | true = fix A, false = fix B |
| clock | &Clock | Y | Sui clock object |

**Move Example**:

```move
public entry fun open_and_add_liquidity(
    config: &GlobalConfig,
    pool: &mut Pool<SUI, USDC>,
    coins_a: vector<Coin<SUI>>,
    coins_b: vector<Coin<USDC>>,
    clock: &Clock,
    ctx: &mut TxContext
) {
    pool_script::open_position_with_liquidity_with_all<SUI, USDC>(
        config,
        pool,
        100,                    // tick_lower_idx
        200,                    // tick_upper_idx
        coins_a,
        coins_b,
        1000000000,             // amount_a (1 SUI)
        2500000,                // amount_b (2.5 USDC)
        true,                   // fix_amount_a
        clock,
        ctx
    );
}
```

### close_position

Close position, remove all liquidity, and collect fees.

**SDK Example (TypeScript)**:
```typescript
import BN from 'bn.js'
import { ClmmPoolUtil, TickMath, Percentage, adjustForCoinSlippage } from '@cetusprotocol/common-sdk'

// Inputs
const pos_id = '0x...' // Position NFT object id
const pool_id = '0x...' // Pool object id

const pool = await sdk.Pool.getPool(pool_id)
const position = await sdk.Position.getPositionById(pos_id)

// Compute minimum amounts with slippage protection
const lower_tick = Number(position.tick_lower_index)
const upper_tick = Number(position.tick_upper_index)
const lower_sqrt_price = TickMath.tickIndexToSqrtPriceX64(lower_tick)
const upper_sqrt_price = TickMath.tickIndexToSqrtPriceX64(upper_tick)

const liquidity = new BN(position.liquidity)
const slippage_tolerance = new Percentage(new BN(5), new BN(100)) // 5%
const cur_sqrt_price = new BN(pool.current_sqrt_price)

const coin_amounts = ClmmPoolUtil.getCoinAmountFromLiquidity(
  liquidity,
  cur_sqrt_price,
  lower_sqrt_price,
  upper_sqrt_price,
  false
)
const { coin_amount_limit_a, coin_amount_limit_b } = adjustForCoinSlippage(coin_amounts, slippage_tolerance, false)

// Collect pending rewards when closing
const rewarder_coin_types = pool.rewarder_infos.map((rewarder) => rewarder.coin_type)

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
console.log('Position closed:', txn.digest)
```

**Module**: `cetus_integrate::pool_script`

**Parameters**:

| Name | Type | Required | Description |
|------|------|----------|-------------|
| config | &GlobalConfig | Y | Global CLMM config object |
| pool | &mut Pool<A, B> | Y | Pool object |
| position_nft | Position | Y | Position NFT (consumed) |
| min_amount_a | u64 | Y | Min coin A to receive (slippage) |
| min_amount_b | u64 | Y | Min coin B to receive (slippage) |
| clock | &Clock | Y | Sui clock object |

**Move Example**:

```move
public entry fun close_my_position(
    config: &GlobalConfig,
    pool: &mut Pool<SUI, USDC>,
    position_nft: Position,
    clock: &Clock,
    ctx: &mut TxContext
) {
    pool_script::close_position<SUI, USDC>(
        config,
        pool,
        position_nft,
        0,      // min_amount_a (no slippage protection)
        0,      // min_amount_b
        clock,
        ctx
    );
    // Coins transferred to sender, NFT burned
}
```

---

## Liquidity Operations

### add_liquidity vs add_liquidity_fix_coin

Two approaches to adding liquidity:

| Approach | Function | Input | Behavior |
|----------|----------|-------|----------|
| By Liquidity | add_liquidity_* | delta_liquidity (u128) | Specify exact liquidity amount, calculates required coins |
| By Coin Amount | add_liquidity_fix_coin_* | amount (u64), fix_amount_a (bool) | Specify coin amount, calculates liquidity |

**Recommendation**: Use `add_liquidity_fix_coin_*` for simpler UX (users think in coin amounts, not liquidity units).

### add_liquidity_fix_coin_with_all

Add liquidity by specifying fixed coin amount.

**SDK Example (TypeScript)**:

```typescript
import BN from 'bn.js'
import { ClmmPoolUtil } from '@cetusprotocol/common-sdk'

// Get position info
const positionAddress = '0x...' // Position NFT object ID
const position = await sdk.Position.getPosition(positionAddress)
const pool = await sdk.Pool.getPool(position.pool)

// Define liquidity to add
const fix_coin_amount = new BN(500000000) // 0.5 SUI
const fix_amount_a = true
const slippage = 0.05

// Calculate required amounts
const liquidity_input = ClmmPoolUtil.estLiquidityAndCoinAmountFromOneAmounts(
  position.tick_lower_index,
  position.tick_upper_index,
  fix_coin_amount,
  fix_amount_a,
  true,
  slippage,
  pool.current_sqrt_price
)

const amount_a = fix_amount_a ? fix_coin_amount.toNumber() : Number(liquidity_input.coin_amount_limit_a)
const amount_b = fix_amount_a ? Number(liquidity_input.coin_amount_limit_b) : fix_coin_amount.toNumber()

// Build add liquidity transaction
const add_liquidity_payload_params = {
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
}
const add_liquidity_payload = await sdk.Position.createAddLiquidityFixTokenPayload(add_liquidity_payload_params)

const txn = await sdk.FullClient.sendTransaction(signer, add_liquidity_payload)
console.log('Liquidity added:', txn.digest)
```

**Module**: `cetus_integrate::pool_script`

**Parameters**:

| Name | Type | Required | Description |
|------|------|----------|-------------|
| config | &GlobalConfig | Y | Global CLMM config object |
| pool | &mut Pool<A, B> | Y | Pool object |
| position_nft | &mut Position | Y | Position NFT |
| coins_a | vector<Coin<A>> | Y | Coin A vector |
| coins_b | vector<Coin<B>> | Y | Coin B vector |
| amount_a | u64 | Y | Max coin A to use |
| amount_b | u64 | Y | Max coin B to use |
| fix_amount_a | bool | Y | true = fix A, false = fix B |
| clock | &Clock | Y | Sui clock object |

**Move Example**:

```move
public entry fun add_more_liquidity(
    config: &GlobalConfig,
    pool: &mut Pool<SUI, USDC>,
    position_nft: &mut Position,
    coins_a: vector<Coin<SUI>>,
    coins_b: vector<Coin<USDC>>,
    clock: &Clock,
    ctx: &mut TxContext
) {
    pool_script::add_liquidity_fix_coin_with_all<SUI, USDC>(
        config,
        pool,
        position_nft,
        coins_a,
        coins_b,
        500000000,   // amount_a (0.5 SUI)
        1250000,     // amount_b (1.25 USDC)
        true,        // fix_amount_a
        clock,
        ctx
    );
}
```

### remove_liquidity

Remove liquidity from position with slippage protection.

**SDK Example (TypeScript)**:
```typescript
import BN from 'bn.js'
import { ClmmPoolUtil, TickMath, Percentage, adjustForCoinSlippage } from '@cetusprotocol/common-sdk'

// Inputs
const pos_id = '0x...' // Position NFT object id
const pool_id = '0x...' // Pool object id
const delta_liquidity = new BN('...') // u128, e.g. remove half

const pool = await sdk.Pool.getPool(pool_id)
const position = await sdk.Position.getPositionById(pos_id)

const lower_tick = Number(position.tick_lower_index)
const upper_tick = Number(position.tick_upper_index)

const lower_sqrt_price = TickMath.tickIndexToSqrtPriceX64(lower_tick)
const upper_sqrt_price = TickMath.tickIndexToSqrtPriceX64(upper_tick)

const liquidity = delta_liquidity
const slippage_tolerance = new Percentage(new BN(5), new BN(100)) // 5%
const cur_sqrt_price = new BN(pool.current_sqrt_price)

// slippage-protected min amounts
const coin_amounts = ClmmPoolUtil.getCoinAmountFromLiquidity(
  liquidity,
  cur_sqrt_price,
  lower_sqrt_price,
  upper_sqrt_price,
  false
)
const { coin_amount_limit_a, coin_amount_limit_b } = adjustForCoinSlippage(coin_amounts, slippage_tolerance, false)

const rewarder_coin_types = pool.rewarder_infos.map((rewarder) => rewarder.coin_type)

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
console.log('Liquidity removed:', txn.digest)
```

**Module**: `cetus_integrate::pool_script`

**Parameters**:

| Name | Type | Required | Description |
|------|------|----------|-------------|
| config | &GlobalConfig | Y | Global CLMM config object |
| pool | &mut Pool<A, B> | Y | Pool object |
| position_nft | &mut Position | Y | Position NFT |
| delta_liquidity | u128 | Y | Amount of liquidity to remove |
| min_amount_a | u64 | Y | Min coin A to receive |
| min_amount_b | u64 | Y | Min coin B to receive |
| clock | &Clock | Y | Sui clock object |

**Move Example**:

```move
public entry fun remove_half_liquidity(
    config: &GlobalConfig,
    pool: &mut Pool<SUI, USDC>,
    position_nft: &mut Position,
    clock: &Clock,
    ctx: &mut TxContext
) {
    // Assume position has 1000000 liquidity
    pool_script::remove_liquidity<SUI, USDC>(
        config,
        pool,
        position_nft,
        500000,      // delta_liquidity (remove half)
        0,           // min_amount_a
        0,           // min_amount_b
        clock,
        ctx
    );
}
```

---

## Swap Operations

### swap_a2b

Swap coin A to coin B in single pool.

**SDK Example (TypeScript)**:

```typescript
import BN from 'bn.js'
import { adjustForSlippage, d, Percentage } from '@cetusprotocol/common-sdk'

// Get pool
const poolAddress = '0x...' // SUI-USDC pool
const pool = await sdk.Pool.getPool(poolAddress)

// Swap parameters
const a2b = true              // SUI → USDC
const by_amount_in = true    // Fix input amount
const amount = new BN(1000000000) // 1 SUI
const slippage = Percentage.fromDecimal(d(0.02)) // 2% slippage

// Step 1: Calculate expected output (preSwap)
const res = await sdk.Swap.preSwap({
  pool,
  current_sqrt_price: pool.current_sqrt_price,
  coin_type_a: pool.coin_type_a,
  coin_type_b: pool.coin_type_b,
  decimals_a: 9,  // SUI decimals
  decimals_b: 6,  // USDC decimals
  a2b,
  by_amount_in,
  amount: amount.toString(),
})

console.log(
  'Estimated output:',
  (by_amount_in ? res.estimated_amount_out : res.estimated_amount_in).toString()
)

// Step 2: Calculate slippage-adjusted limit
const toAmount = by_amount_in ? res.estimated_amount_out : res.estimated_amount_in
const amountLimit = adjustForSlippage(toAmount, slippage, !by_amount_in)

// Step 3: Build and execute swap transaction
const swap_payload = sdk.Swap.createSwapPayload({
  pool_id: pool.id,
  coin_type_a: pool.coin_type_a,
  coin_type_b: pool.coin_type_b,
  a2b,
  by_amount_in,
  amount: res.amount.toString(),
  amount_limit: amountLimit.toString(),
})

const txn = await sdk.FullClient.sendTransaction(signer, swap_payload)
console.log('Swap completed:', txn.digest)
```

**Module**: `cetus_integrate::pool_script`

**Parameters**:

| Name | Type | Required | Description |
|------|------|----------|-------------|
| config | &GlobalConfig | Y | Global CLMM config object |
| pool | &mut Pool<A, B> | Y | Pool object |
| coins_a | vector<Coin<A>> | Y | Input coins to swap |
| by_amount_in | bool | Y | true = fix input, false = fix output |
| amount | u64 | Y | Input amount (if by_amount_in=true) or output amount (if false) |
| amount_limit | u64 | Y | Min output (if by_amount_in=true) or max input (if false) |
| sqrt_price_limit | u128 | Y | Price boundary (0 = no limit) |
| clock | &Clock | Y | Sui clock object |

**Move Example**:

```move
public entry fun swap_sui_to_usdc(
    config: &GlobalConfig,
    pool: &mut Pool<SUI, USDC>,
    coins_a: vector<Coin<SUI>>,
    clock: &Clock,
    ctx: &mut TxContext
) {
    pool_script::swap_a2b<SUI, USDC>(
        config,
        pool,
        coins_a,
        true,           // by_amount_in (fix input)
        1000000000,     // amount (1 SUI)
        2450000,        // amount_limit (min 2.45 USDC, 2% slippage)
        0,              // sqrt_price_limit (no limit)
        clock,
        ctx
    );
    // USDC transferred to sender
}
```

### Flash Swap Mechanism

CLMM uses flash swaps internally:
1. Pool lends output coins to user
2. User repays with input coins
3. Transaction reverts if repayment insufficient

This enables atomic swaps without upfront capital and powers multi-hop routing.

### Slippage Protection

**by_amount_in = true** (fix input):
- `amount` = exact input amount
- `amount_limit` = minimum output amount
- Example: Swap exactly 1 SUI, receive at least 2.45 USDC

**by_amount_in = false** (fix output):
- `amount` = exact output amount
- `amount_limit` = maximum input amount
- Example: Receive exactly 2.5 USDC, spend at most 1.02 SUI

**Slippage calculation**:
```
slippage_tolerance = 0.02  // 2%
if by_amount_in:
    amount_limit = expected_output * (1 - slippage_tolerance)
else:
    amount_limit = expected_input * (1 + slippage_tolerance)
```

### swap_a2b_with_partner

Swap with partner fee sharing.

**Module**: `cetus_integrate::pool_script`

**Additional Parameter**:

| Name | Type | Required | Description |
|------|------|----------|-------------|
| partner | &mut Partner | Y | Partner object for fee collection |

**Move Example**:

```move
public entry fun swap_with_partner_fee(
    config: &GlobalConfig,
    pool: &mut Pool<SUI, USDC>,
    partner: &mut Partner,
    coins_a: vector<Coin<SUI>>,
    clock: &Clock,
    ctx: &mut TxContext
) {
    pool_script::swap_a2b_with_partner<SUI, USDC>(
        config,
        pool,
        partner,
        coins_a,
        true,
        1000000000,
        2450000,
        0,
        clock,
        ctx
    );
    // Partner earns fee share in Partner object
}
```

---

## Fee & Reward Collection

### collect_fee

Collect LP fees from position.

**SDK Example (TypeScript)**:

```typescript
// Get position
const positionAddress = '0x...' // Position NFT object ID
const position = await sdk.Position.getPosition(positionAddress)
const pool = await sdk.Pool.getPool(position.pool)

// Collect fees (and any available rewards) via rewarder collection
const rewarder_coin_types = pool.rewarder_infos.map((rewarder) => rewarder.coin_type)

const collect_rewarder_params = {
  pool_id: pool.id,
  pos_id: positionAddress,
  rewarder_coin_types,
  coin_type_a: pool.coin_type_a,
  coin_type_b: pool.coin_type_b,
  collect_fee: true,
}

const collect_rewarder_payload = await sdk.Rewarder.collectRewarderPayload(collect_rewarder_params)
const txn = await sdk.FullClient.sendTransaction(signer, collect_rewarder_payload)
console.log('Fees (and rewards) collected:', txn.digest)
```

**Module**: `cetus_integrate::pool_script`

**Parameters**:

| Name | Type | Required | Description |
|------|------|----------|-------------|
| config | &GlobalConfig | Y | Global CLMM config object |
| pool | &mut Pool<A, B> | Y | Pool object |
| position | &mut Position | Y | Position NFT |

**Move Example**:

```move
public entry fun collect_my_fees(
    config: &GlobalConfig,
    pool: &mut Pool<SUI, USDC>,
    position: &mut Position,
    ctx: &mut TxContext
) {
    pool_script::collect_fee<SUI, USDC>(
        config,
        pool,
        position,
        ctx
    );
    // Fees transferred to sender
}
```

### collect_reward

Collect reward tokens from position.

**SDK Example (TypeScript)**:
```typescript
// Collecting rewards is done via Rewarder on SDK v2
const pos_id = '0x...' // Position NFT object id
const pool_id = '0x...' // Pool object id

const pool = await sdk.Pool.getPool(pool_id)
const rewarder_coin_types = pool.rewarder_infos.map((rewarder) => rewarder.coin_type)

const collect_rewarder_params = {
  pool_id: pool.id,
  pos_id,
  rewarder_coin_types,
  coin_type_a: pool.coin_type_a,
  coin_type_b: pool.coin_type_b,
  collect_fee: true, // also collect LP fees if any
}

const collect_rewarder_payload = await sdk.Rewarder.collectRewarderPayload(collect_rewarder_params)
const txn = await sdk.FullClient.sendTransaction(signer, collect_rewarder_payload)
console.log('Rewards collected:', txn.digest)
```

**Module**: `cetus_integrate::pool_script`

**Parameters**:

| Name | Type | Required | Description |
|------|------|----------|-------------|
| config | &GlobalConfig | Y | Global CLMM config object |
| pool | &mut Pool<A, B> | Y | Pool object |
| position_nft | &mut Position | Y | Position NFT |
| vault | &mut RewarderGlobalVault | Y | Reward vault object |
| collect_fee | bool | Y | true = also collect LP fees in same call |
| clock | &Clock | Y | Sui clock object |

**Move Example**:

```move
public entry fun collect_cetus_rewards(
    config: &GlobalConfig,
    pool: &mut Pool<SUI, USDC>,
    position_nft: &mut Position,
    vault: &mut RewarderGlobalVault,
    clock: &Clock,
    ctx: &mut TxContext
) {
    pool_script::collect_reward<SUI, USDC, CETUS>(
        config,
        pool,
        position_nft,
        vault,
        true,
        clock,
        ctx
    );
    // CETUS rewards transferred to sender
}
```

### fetch_position_fees

Query claimable fees before collecting.

**Module**: `cetus_integrate::fetcher_script`

**Parameters**:

| Name | Type | Required | Description |
|------|------|----------|-------------|
| config | &GlobalConfig | Y | Global CLMM config object |
| pool | &mut Pool<A, B> | Y | Pool object |
| position_id | ID | Y | Position NFT object ID |

**Move Example**:

```move
public entry fun query_fees(
    config: &GlobalConfig,
    pool: &mut Pool<SUI, USDC>,
    position_id: ID
) {
    fetcher_script::fetch_position_fees<SUI, USDC>(
        config,
        pool,
        position_id
    );
    // Result emitted as FetchPositionFeesEvent
}
```

---

## Important Types & Structures

### Tick Spacing

Common tick spacing values and their meanings:

| Tick Spacing | Fee Tier | Use Case |
|--------------|----------|----------|
| 1 | 0.01% | Stablecoin pairs (USDC/USDT) |
| 2 | 0.02% | Correlated assets |
| 10 | 0.1% | Standard pairs (SUI/USDC) |
| 60 | 0.6% | Volatile pairs |
| 200 | 2% | Exotic/high-risk pairs |

### Sqrt Price

Sqrt price represents `sqrt(price_B/price_A) * 2^64`.

**Conversion formulas**:

```typescript
// Price to sqrt price
function priceToSqrtPrice(price: number): bigint {
  return BigInt(Math.floor(Math.sqrt(price) * (2 ** 64)))
}

// Sqrt price to price
function sqrtPriceToPrice(sqrtPrice: bigint): number {
  return (Number(sqrtPrice) / (2 ** 64)) ** 2
}
```

**Example**:
- Price: 1 SUI = 2.5 USDC
- Sqrt price: `sqrt(2.5) * 2^64 ≈ 29189415097064819712`

### Position Structure

Position NFT contains:

| Field | Type | Description |
|-------|------|-------------|
| pool | ID | Pool object ID |
| tick_lower | I32 | Lower tick index (signed) |
| tick_upper | I32 | Upper tick index (signed) |
| liquidity | u128 | Current liquidity amount |

### Pool Coin Ordering

Pools derive `coin_type_a` / `coin_type_b` by lexicographic ASCII ordering: when the strings differ, the coin with the *larger* ASCII value becomes `coin_type_a`.

**Example**:
- ✅ Correct: `Pool<0xdba...::usdc::USDC, 0x2::sui::SUI>`  (coin_type_a is lexicographically larger)
- ❌ Wrong: `Pool<0x2::sui::SUI, 0xdba...::usdc::USDC>`

---

## Common Coin Types

| Token | Decimals | Coin Type | 1 token = |
|-------|----------|-----------|-----------|
| SUI | 9 | `0x0000000000000000000000000000000000000000000000000000000000000002::sui::SUI` | 1,000,000,000 |
| USDC | 6 | `0xdba34672e30cb065b1f93e3ab55318768fd6fef66c15942c9f7cb846e2f900e7::usdc::USDC` | 1,000,000 |
| USDT | 6 | `0xc060006111016b8a020ad5b33834984a437aaa7d3c74c18e09a95d48aceab08c::coin::COIN` | 1,000,000 |
| CETUS | 9 | `0x06864a6f921804860930db6ddbe2e16acdf8504495ea7481637a1c8b9a8fe54b::cetus::CETUS` | 1,000,000,000 |
| DEEP | 6 | `0xdeeb7a4662eec9f2f3def03fb937a663dddaa2e215b8078a284d026b7946c270::deep::DEEP` | 1,000,000 |

**Amount conversion**: `amount = human_amount * 10^decimals`

---

## Edge Cases & Best Practices

### Tick Range Selection

**Narrow ranges** (e.g., ±10 ticks):
- ✅ Higher capital efficiency
- ✅ More fees when price in range
- ❌ Higher impermanent loss risk
- ❌ Requires active management

**Wide ranges** (e.g., full range):
- ✅ Lower impermanent loss
- ✅ Passive management
- ❌ Lower capital efficiency
- ❌ Fewer fees

### Liquidity Concentration Strategies

1. **Full Range**: derive full-range ticks from `tick_spacing`
   - `tick_lower_index = -443636 + (443636 % tick_spacing)`
   - `tick_upper_index = 443636 - (443636 % tick_spacing)`
   - Behaves like traditional AMM (Uniswap V2)
   - Suitable for passive LPs

2. **Tight Range**: ±5-10% around current price
   - Maximizes fees for stable pairs
   - Requires frequent rebalancing

3. **Multiple Positions**: Split capital across ranges
   - Diversifies risk
   - Captures fees at different price levels

### Impermanent Loss

CLMM amplifies impermanent loss in narrow ranges:

```
IL_clmm = IL_v2 * concentration_factor
concentration_factor = full_range_liquidity / narrow_range_liquidity
```

**Mitigation**:
- Use wider ranges for volatile pairs
- Rebalance positions regularly
- Collect fees frequently to offset IL

### Gas Optimization

**Batch operations**:
- Merge multiple coins before swapping
- Collect fees + rewards in single transaction
- Use `open_position_with_liquidity_*` instead of separate calls

**Avoid**:
- Opening many small positions (high NFT overhead)
- Frequent small liquidity additions (gas > fees earned)

### Position Management Lifecycle

1. **Open**: Choose tick range based on volatility and strategy
2. **Monitor**: Track price movement and fee accumulation
3. **Rebalance**: Close out-of-range positions, open new ones
4. **Collect**: Harvest fees regularly to compound or realize gains
5. **Close**: Remove liquidity when strategy complete

---

## Contract Addresses & Package Info

### Mainnet Objects

| Object | Address |
|--------|---------|
| CLMM Package | `0x1eabed72c53feb3805120a081dc15963c204dc8d091542592abaf7a35689b2fb` |
| CLMM Published At | `0x25ebb9a7c50eb17b3fa9c5a30fb8b5ad8f97caaf4928943acbcff7153dfee5e3` |
| Integrate Package | `0x996c4d9480708fb8b92aa7acf819fb0497b5ec8e65ba06601cae2fb6db3312c3` |
| GlobalConfig | `0xdaa46292632c3c4d8f31f23ea0f9b36a28ff3677e9684980e4438403a67a3d8f` |
| Pools | `0xf699e7f2276f5c9a75944b37a0c5b5d9ddfd2471bf6242483b03ab2887d198d0` |
| AdminCap | `0x89c1a321291d15ddae5a086c9abc533dff697fde3d89e0ca836c41af73e36a75` |
| Partners | `0xac30897fa61ab442f6bff518c5923faa1123c94b36bd4558910e9c783adfa204` |
| RewardVault | `0xce7bceef26d3ad1f6d9b6f13a953f053e6ed3ca77907516481ce99ae8e588f2b` |

### Module Structure

**CLMM Package** (`0x1eab...`):
- `cetus_clmm::pool` - Core pool logic
- `cetus_clmm::position` - Position NFT management
- `cetus_clmm::factory` - Pool creation
- `cetus_clmm::config` - Global configuration
- `cetus_clmm::partner` - Partner fee sharing

**Integrate Package** (`0x996c...`):
- `cetus_integrate::pool_script` - Entry functions for pool operations
- `cetus_integrate::pool_creator_v3` - Pool creation with liquidity
- `cetus_integrate::fetcher_script` - Query functions
- `cetus_integrate::router` - Multi-hop routing (not covered in this skill)

### Package Version Tracking

**Move Registry** (check for latest package addresses):
- CLMM: https://www.moveregistry.com/package/@cetuspackages/clmm
- Integrate: https://www.moveregistry.com/package/@cetuspackages/integrate

**Note**: `published_at` addresses change with contract upgrades. Other object IDs (GlobalConfig, Pools, etc.) remain stable across upgrades.

---

## Error Handling

### Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| EAmountInAboveMaxLimit | Input exceeds max (slippage) | Increase amount_limit or reduce input |
| EAmountOutBelowMinLimit | Output below min (slippage) | Decrease amount_limit or increase slippage tolerance |
| ESwapAmountIncorrect | Amount mismatch | Check by_amount_in flag matches amount parameter |
| ECoinBelowThreshold | Insufficient coin balance | Provide more coins or reduce amount |
| ECoinNotEnough | Not enough coins for liquidity | Increase coin balance or reduce liquidity |

### Error Handling Pattern

```move
public entry fun safe_swap(
    config: &GlobalConfig,
    pool: &mut Pool<SUI, USDC>,
    coins_a: vector<Coin<SUI>>,
    clock: &Clock,
    ctx: &mut TxContext
) {
    // Calculate expected output first
    fetcher_script::calculate_swap_result<SUI, USDC>(
        pool,
        true,   // a2b
        true,   // by_amount_in
        1000000000  // 1 SUI
    );
    // Check event result, then execute swap with appropriate slippage

    pool_script::swap_a2b<SUI, USDC>(
        config,
        pool,
        coins_a,
        true,
        1000000000,
        2450000,  // 2% slippage from expected output
        0,
        clock,
        ctx
    );
}
```
