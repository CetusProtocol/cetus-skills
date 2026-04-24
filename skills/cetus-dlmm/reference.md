# Cetus DLMM — Reference

Detailed parameter schemas, SDK v2 examples, Move contract examples, and integration patterns.

## SDK Setup & Initialization

### Installation

```bash
npm install @cetusprotocol/common-sdk@1.3.3 @cetusprotocol/dlmm-sdk@1.2.6 @cetusprotocol/sui-clmm-sdk@1.4.1
```

Use the pinned versions above when CLMM and DLMM are installed together. Other dependency combinations have been observed to break `sdk.Pool.getPool(...)` and `sdk.Swap.preSwapQuote(...)`.

### SDK Initialization

```typescript
import { CetusDlmmSDK } from '@cetusprotocol/dlmm-sdk'
import { dlmmMainnet } from '@cetusprotocol/common-sdk'
import { Ed25519Keypair } from '@mysten/sui/keypairs/ed25519'

// Initialize SDK for mainnet (SDK v2)
const sdk = CetusDlmmSDK.createSDK(dlmmMainnet)

// Set signer (for sending transactions)
const signer = Ed25519Keypair.fromSecretKey(yourSecretKey)
sdk.setSenderAddress(signer.getPublicKey().toSuiAddress())
```

### Contract Object IDs (Mainnet)

```typescript
// These are automatically configured in the SDK, but can be referenced:
const MAINNET_CONFIG = {
  dlmmPackage: '0x5664f9d3fd82c84023870cfbda8ea84e14c8dd56ce557ad2116e0668581a682b',
  routerPackage: '0x36d7c12e8497cee9259dd6b0da9f8bbe955134d658a1e3e7c682d43c7a955125',
  globalConfig: '0xf31b605d117f959b9730e8c07b08b856cb05143c5e81d5751c90d2979e82f599',
  registry: '0xb1d55e7d895823c65f98d99b81a69436cf7d1638629c9ccb921326039cda1f1b',
  versioned: '0x05370b2d656612dd5759cbe80463de301e3b94a921dfc72dd9daa2ecdeb2d0a8',
  partners: '0x5c0affc8d363b6abb1f32790c229165215f4edead89a9bc7cd95dad717b4296a',
}
```

### Getting Pool Object

```typescript
// Fetch pool by address
const poolAddress = '0x...' // Pool object ID
const pool = await sdk.Pool.getPool(poolAddress)

console.log(pool.coin_type_a)     // Coin A type
console.log(pool.coin_type_b)     // Coin B type
console.log(pool.active_id)       // Current active bin ID
console.log(pool.bin_step)        // Bin step
```

---

## Pool Operations

### create_pool

Create a new DLMM pool with specified bin step and initial active bin.

**SDK Example (TypeScript)**:

```typescript
import BN from 'bn.js'
import { BinUtils } from '@cetusprotocol/dlmm-sdk'
import { Transaction } from '@mysten/sui/transactions'

// Define coin types
const coin_type_a = '0x2::sui::SUI'
const coin_type_b = '0xdba34672e30cb065b1f93e3ab55318768fd6fef66c15942c9f7cb846e2f900e7::usdc::USDC'

// Calculate active bin ID from price
const bin_step = 2  // Price interval
const price = '2.5'  // 1 SUI = 2.5 USDC
const decimals_a = 9  // SUI decimals
const decimals_b = 6  // USDC decimals

const active_id = BinUtils.getBinIdFromPrice(price, bin_step, true, decimals_a, decimals_b)

// Build transaction
const create_pool_payload = sdk.Pool.createPoolPayload({
  coin_type_a,
  coin_type_b,
  bin_step,
  active_id,
}, new Transaction())

// Execute transaction
const txn = await sdk.FullClient.sendTransaction(signer, create_pool_payload)
console.log('Pool created:', txn.digest)
```

**Module**: `cetusdlmm::pool`

**Parameters**:

| Name | Type | Required | Description |
|------|------|----------|-------------|
| config | &GlobalConfig | Y | Global DLMM config object |
| registry | &mut Registry | Y | Pool registry object |
| bin_step | u16 | Y | Minimum price interval between bins |
| active_id | I32 | Y | Initial active bin ID |
| versioned | &Versioned | Y | Version control object |

**Move Example**:

```move
use cetusdlmm::pool;
use integer_mate::i32;

public entry fun create_sui_usdc_pool(
    config: &GlobalConfig,
    registry: &mut Registry,
    versioned: &Versioned,
    ctx: &mut TxContext
) {
    // bin_step = 2 (0.02% per bin)
    // active_id = calculated from price 1 SUI = 2.5 USDC
    pool::create_pool<SUI, USDC>(
        config,
        registry,
        2,
        i32::from(23000),  // Example active_id
        versioned,
        ctx
    );
}
```

---

## Position Management

### open_position (Router)

Open position with liquidity using router wrapper for simplified flow.

**SDK Example - Spot Strategy (TypeScript)**:

```typescript
import BN from 'bn.js'
import { StrategyType, BinUtils } from '@cetusprotocol/dlmm-sdk'

// Get pool
const pool = await sdk.Pool.getPool(poolAddress)

// Define position range
const active_id = pool.active_id
const lower_bin_id = active_id - 10
const upper_bin_id = active_id + 10

// Calculate liquidity distribution (Spot strategy)
const bin_infos = await sdk.Position.calculateAddLiquidityInfo({
  active_id,
  bin_step: pool.bin_step,
  lower_bin_id,
  upper_bin_id,
  amount_a_in_active_bin: '0',
  amount_b_in_active_bin: '0',
  strategy_type: StrategyType.Spot,
  coin_amount: '1000000000',  // 1 SUI
  fix_amount_a: true,
})

// Build open position payload
const open_position_payload = await sdk.Position.openPositionPayload({
  pool_id: pool.id,
  coin_type_a: pool.coin_type_a,
  coin_type_b: pool.coin_type_b,
  bin_infos: bin_infos.bins,
  strategy_type: StrategyType.Spot,
})

const txn = await sdk.FullClient.sendTransaction(signer, open_position_payload)
console.log('Position opened:', txn.digest)
```

**SDK Example - Curve Strategy (TypeScript)**:

```typescript
// Curve strategy: More liquidity near active bin
const bin_infos_curve = await sdk.Position.calculateAddLiquidityInfo({
  active_id,
  bin_step: pool.bin_step,
  lower_bin_id,
  upper_bin_id,
  amount_a_in_active_bin: '0',
  amount_b_in_active_bin: '0',
  strategy_type: StrategyType.Curve,
  coin_amount: '1000000000',
  fix_amount_a: true,
})

const open_position_curve = await sdk.Position.openPositionPayload({
  pool_id: pool.id,
  coin_type_a: pool.coin_type_a,
  coin_type_b: pool.coin_type_b,
  bin_infos: bin_infos_curve.bins,
  strategy_type: StrategyType.Curve,
})
```

**SDK Example - BidAsk Strategy (TypeScript)**:

```typescript
// BidAsk strategy: Liquidity on both sides of active bin
const bin_infos_bidask = await sdk.Position.calculateAddLiquidityInfo({
  active_id,
  bin_step: pool.bin_step,
  lower_bin_id,
  upper_bin_id,
  amount_a_in_active_bin: '0',
  amount_b_in_active_bin: '0',
  strategy_type: StrategyType.BidAsk,
  coin_amount: '1000000000',
  fix_amount_a: true,
})

const open_position_bidask = await sdk.Position.openPositionPayload({
  pool_id: pool.id,
  coin_type_a: pool.coin_type_a,
  coin_type_b: pool.coin_type_b,
  bin_infos: bin_infos_bidask.bins,
  strategy_type: StrategyType.BidAsk,
})
```

**Module**: `dlmmrouter::add_liquidity`

**Parameters**:

| Name | Type | Required | Description |
|------|------|----------|-------------|
| pool | &mut Pool<A, B> | Y | Pool object |
| coin_a | &mut Coin<A> | Y | Coin A to provide liquidity |
| coin_b | &mut Coin<B> | Y | Coin B to provide liquidity |
| bins | vector<u32> | Y | Vector of bin IDs |
| amounts_a | vector<u64> | Y | Coin A amounts for each bin |
| amounts_b | vector<u64> | Y | Coin B amounts for each bin |
| config | &GlobalConfig | Y | Global DLMM config object |
| versioned | &Versioned | Y | Version control object |
| clk | &Clock | Y | Sui clock object (0x6) |

**Move Example**:

```move
use dlmmrouter::add_liquidity;
use sui::clock::Clock;

public entry fun open_position_spot(
    pool: &mut Pool<SUI, USDC>,
    coin_a: &mut Coin<SUI>,
    coin_b: &mut Coin<USDC>,
    config: &GlobalConfig,
    versioned: &Versioned,
    clock: &Clock,
    ctx: &mut TxContext
) {
    // Example: 3 bins with Spot strategy
    let bins = vector[23000, 23001, 23002];
    let amounts_a = vector[333333333, 333333333, 333333334];  // ~1 SUI total
    let amounts_b = vector[0, 0, 0];  // No USDC needed for bins above active

    add_liquidity::open_position<SUI, USDC>(
        pool,
        coin_a,
        coin_b,
        bins,
        amounts_a,
        amounts_b,
        config,
        versioned,
        clock,
        ctx
    );
    // Position NFT transferred to sender
}
```

### add_liquidity (Router)

Add liquidity to existing position using router wrapper.

**SDK Example (TypeScript)**:

```typescript
// Get position
const positionAddress = '0x...' // Position NFT object ID
const position = await sdk.Position.getPosition(positionAddress)
const pool = await sdk.Pool.getPool(position.pool_id)

// Calculate additional liquidity
const bin_infos = await sdk.Position.calculateAddLiquidityInfo({
  active_id: pool.active_id,
  bin_step: pool.bin_step,
  lower_bin_id: position.lower_bin_id,
  upper_bin_id: position.upper_bin_id,
  amount_a_in_active_bin: '0',
  amount_b_in_active_bin: '0',
  strategy_type: StrategyType.Spot,
  coin_amount: '500000000',  // 0.5 SUI
  fix_amount_a: true,
})

// Build add liquidity payload
const add_liquidity_payload = await sdk.Position.addLiquidityPayload({
  pool_id: pool.id,
  position_id: positionAddress,
  coin_type_a: pool.coin_type_a,
  coin_type_b: pool.coin_type_b,
  bin_infos: bin_infos.bins,
  strategy_type: StrategyType.Spot,
})

const txn = await sdk.FullClient.sendTransaction(signer, add_liquidity_payload)
console.log('Liquidity added:', txn.digest)
```

**Module**: `dlmmrouter::add_liquidity`

**Parameters**:

| Name | Type | Required | Description |
|------|------|----------|-------------|
| pool | &mut Pool<A, B> | Y | Pool object |
| position | &mut Position | Y | Position NFT |
| coin_a | &mut Coin<A> | Y | Coin A to add |
| coin_b | &mut Coin<B> | Y | Coin B to add |
| bins | vector<u32> | Y | Vector of bin IDs |
| amounts_a | vector<u64> | Y | Coin A amounts for each bin |
| amounts_b | vector<u64> | Y | Coin B amounts for each bin |
| config | &GlobalConfig | Y | Global DLMM config object |
| versioned | &Versioned | Y | Version control object |
| clk | &Clock | Y | Sui clock object |

**Move Example**:

```move
public entry fun add_more_liquidity(
    pool: &mut Pool<SUI, USDC>,
    position: &mut Position,
    coin_a: &mut Coin<SUI>,
    coin_b: &mut Coin<USDC>,
    config: &GlobalConfig,
    versioned: &Versioned,
    clock: &Clock,
    ctx: &mut TxContext
) {
    let bins = vector[23000, 23001, 23002];
    let amounts_a = vector[166666666, 166666667, 166666667];  // ~0.5 SUI
    let amounts_b = vector[0, 0, 0];

    add_liquidity::add_liquidity<SUI, USDC>(
        pool,
        position,
        coin_a,
        coin_b,
        bins,
        amounts_a,
        amounts_b,
        config,
        versioned,
        clock,
        ctx
    );
}
```

### remove_liquidity

Remove liquidity from position (direct call).

**SDK Example (TypeScript)**:

```typescript
// Get position
const position = await sdk.Position.getPosition(positionAddress)
const pool = await sdk.Pool.getPool(position.pool_id)

// Calculate removal amounts
const remove_info = await sdk.Position.calculateRemoveLiquidityBothOption({
  pool_id: pool.id,
  position_id: positionAddress,
  bin_ids: [23000, 23001, 23002],  // Bins to remove from
  liquidity_shares: ['50000000', '50000000', '50000000'],  // Shares to remove
})

// Build remove liquidity payload
const remove_payload = await sdk.Position.removeLiquidityPayload({
  pool_id: pool.id,
  position_id: positionAddress,
  coin_type_a: pool.coin_type_a,
  coin_type_b: pool.coin_type_b,
  bin_ids: [23000, 23001, 23002],
  liquidity_shares: ['50000000', '50000000', '50000000'],
})

const txn = await sdk.FullClient.sendTransaction(signer, remove_payload)
console.log('Liquidity removed:', txn.digest)
```

**Module**: `cetusdlmm::pool`

**Parameters**:

| Name | Type | Required | Description |
|------|------|----------|-------------|
| config | &GlobalConfig | Y | Global DLMM config object |
| pool | &mut Pool<A, B> | Y | Pool object |
| position | &mut Position | Y | Position NFT |
| bins | vector<I32> | Y | Bin IDs to remove from |
| liquidity_shares | vector<u128> | Y | Shares to remove from each bin |
| versioned | &Versioned | Y | Version control object |
| clock | &Clock | Y | Sui clock object |

**Move Example**:

```move
use cetusdlmm::pool;
use integer_mate::i32;

public entry fun remove_half_liquidity(
    config: &GlobalConfig,
    pool: &mut Pool<SUI, USDC>,
    position: &mut Position,
    versioned: &Versioned,
    clock: &Clock,
    ctx: &mut TxContext
) {
    let bins = vector[i32::from(23000), i32::from(23001), i32::from(23002)];
    let shares = vector[50000000, 50000000, 50000000];

    let (coin_a, coin_b) = pool::remove_liquidity<SUI, USDC>(
        config,
        pool,
        position,
        bins,
        shares,
        versioned,
        clock,
        ctx
    );

    // Coins transferred to sender
    transfer::public_transfer(coin_a, ctx.sender());
    transfer::public_transfer(coin_b, ctx.sender());
}
```

### remove_liquidity_by_percent

Remove a percentage of liquidity from position bins (direct call).

**Module**: `cetusdlmm::pool`

**Parameters**:

| Name | Type | Required | Description |
|------|------|----------|-------------|
| config | &GlobalConfig | Y | Global DLMM config object |
| pool | &mut Pool<A, B> | Y | Pool object |
| position | &mut Position | Y | Position NFT |
| bins | vector<I32> | Y | Bin IDs to remove from |
| percent | u64 | Y | Percentage to remove (e.g., 5000 = 50%, basis points * 100) |
| versioned | &Versioned | Y | Version control object |
| clock | &Clock | Y | Sui clock object |

**Move Example**:

```move
use cetusdlmm::pool;
use integer_mate::i32;

public entry fun remove_half_by_percent(
    config: &GlobalConfig,
    pool: &mut Pool<SUI, USDC>,
    position: &mut Position,
    versioned: &Versioned,
    clock: &Clock,
    ctx: &mut TxContext
) {
    let bins = vector[i32::from(23000), i32::from(23001), i32::from(23002)];

    let (coin_a, coin_b) = pool::remove_liquidity_by_percent<SUI, USDC>(
        config,
        pool,
        position,
        bins,
        5000,   // 50% (basis points * 100: 10000 = 100%)
        versioned,
        clock,
        ctx
    );

    transfer::public_transfer(coin_a, ctx.sender());
    transfer::public_transfer(coin_b, ctx.sender());
}
```

---

### close_position

Close position, remove all liquidity, and collect fees.

**SDK Example (TypeScript)**:

```typescript
// Build close position payload
const close_payload = await sdk.Position.closePositionPayload({
  pool_id: pool.id,
  position_id: positionAddress,
  coin_type_a: pool.coin_type_a,
  coin_type_b: pool.coin_type_b,
})

const txn = await sdk.FullClient.sendTransaction(signer, close_payload)
console.log('Position closed:', txn.digest)
```

**Module**: `cetusdlmm::pool`

**Parameters**:

| Name | Type | Required | Description |
|------|------|----------|-------------|
| config | &GlobalConfig | Y | Global DLMM config object |
| pool | &mut Pool<A, B> | Y | Pool object |
| position | Position | Y | Position NFT (consumed) |
| versioned | &Versioned | Y | Version control object |
| clock | &Clock | Y | Sui clock object |

**Move Example**:

```move
public entry fun close_my_position(
    config: &GlobalConfig,
    pool: &mut Pool<SUI, USDC>,
    position: Position,
    versioned: &Versioned,
    clock: &Clock,
    ctx: &mut TxContext
) {
    let close_cert = pool::close_position<SUI, USDC>(
        config,
        pool,
        position,
        versioned,
        clock,
        ctx
    );

    // Destroy certificate and receive coins
    pool::destroy_close_position_cert(close_cert, versioned);
    // Coins and fees transferred to sender, NFT burned
}
```

---

## Swap Operations

### swap_a2b (Router)

Swap coin A to coin B using router wrapper.

**SDK Example (TypeScript)**:

```typescript
import { Percentage, d } from '@cetusprotocol/common-sdk'
// Get pool
const poolAddress = '0x...' // SUI-USDC pool
const pool = await sdk.Pool.getPool(poolAddress)

// Swap parameters
const a2b = true              // SUI → USDC
const by_amount_in = true    // Fix input amount
const amount = '1000000000'  // 1 SUI
const slippage = Percentage.fromDecimal(d(0.01)) // 1% slippage

// Step 1: Get quote
const quote = await sdk.Swap.preSwapQuote({
  pool_id: pool.id,
  coin_type_a: pool.coin_type_a,
  coin_type_b: pool.coin_type_b,
  a2b,
  by_amount_in,
  in_amount: amount,
})

console.log('Estimated output:', quote.out_amount)

// Step 2: Build and execute swap
const swap_payload = sdk.Swap.swapPayload({
  quote_obj: quote,
  coin_type_a: pool.coin_type_a,
  coin_type_b: pool.coin_type_b,
  by_amount_in,
  slippage: slippage, // 1%
})

const txn = await sdk.FullClient.sendTransaction(signer, swap_payload)
console.log('Swap completed:', txn.digest)
```

**Module**: `dlmmrouter::swap`

**Parameters**:

| Name | Type | Required | Description |
|------|------|----------|-------------|
| pool | &mut Pool<A, B> | Y | Pool object |
| coin_a | &mut Coin<A> | Y | Input coin (for A→B) |
| by_amount_in | bool | Y | true = fix input, false = fix output |
| amount | u64 | Y | Input amount (if by_amount_in=true) or output amount |
| amount_limit | u64 | Y | Min output (if by_amount_in=true) or max input |
| config | &GlobalConfig | Y | Global DLMM config object |
| versioned | &Versioned | Y | Version control object |
| clock | &Clock | Y | Sui clock object |

**Move Example**:

```move
use dlmmrouter::swap;

public entry fun swap_sui_to_usdc(
    pool: &mut Pool<SUI, USDC>,
    coin_a: &mut Coin<SUI>,
    config: &GlobalConfig,
    versioned: &Versioned,
    clock: &Clock,
    ctx: &mut TxContext
) {
    swap::swap_a2b<SUI, USDC>(
        pool,
        coin_a,
        true,           // by_amount_in (fix input)
        1000000000,     // amount (1 SUI)
        2475000,        // amount_limit (min 2.475 USDC, 1% slippage)
        config,
        versioned,
        clock,
        ctx
    );
    // USDC transferred to sender
}
```

---

## Fee & Reward Collection

### collect_position_fee

Collect LP fees from position.

**SDK Example (TypeScript)**:

```typescript
// Get position and pool
const position = await sdk.Position.getPosition(positionAddress)
const pool = await sdk.Pool.getPool(position.pool_id)

// Collect fees
const collect_fee_payload = await sdk.Position.collectFeePayload({
  pool_id: pool.id,
  position_id: positionAddress,
  coin_type_a: pool.coin_type_a,
  coin_type_b: pool.coin_type_b,
})

const txn = await sdk.FullClient.sendTransaction(signer, collect_fee_payload)
console.log('Fees collected:', txn.digest)
```

**Module**: `cetusdlmm::pool`

**Parameters**:

| Name | Type | Required | Description |
|------|------|----------|-------------|
| config | &GlobalConfig | Y | Global DLMM config object |
| pool | &mut Pool<A, B> | Y | Pool object |
| position | &mut Position | Y | Position NFT |
| versioned | &Versioned | Y | Version control object |

**Move Example**:

```move
public entry fun collect_my_fees(
    config: &GlobalConfig,
    pool: &mut Pool<SUI, USDC>,
    position: &mut Position,
    versioned: &Versioned,
    ctx: &mut TxContext
) {
    let (coin_a, coin_b) = pool::collect_position_fee<SUI, USDC>(
        config,
        pool,
        position,
        versioned,
        ctx
    );

    // Fees transferred to sender
    transfer::public_transfer(coin_a, ctx.sender());
    transfer::public_transfer(coin_b, ctx.sender());
}
```

### collect_position_reward

Collect reward tokens from position.

**SDK Example (TypeScript)**:

```typescript
// Get pool reward info
const pool = await sdk.Pool.getPool(pool_id)
const reward_coins = pool.reward_manager.rewards.map((r) => r.reward_coin)

// Collect all rewards and fees
const collect_payload = await sdk.Position.collectRewardAndFeePayload([{
  pool_id: pool.id,
  position_id: positionAddress,
  reward_coins,
  coin_type_a: pool.coin_type_a,
  coin_type_b: pool.coin_type_b,
}])

const txn = await sdk.FullClient.sendTransaction(signer, collect_payload)
console.log('Rewards and fees collected:', txn.digest)
```

**Module**: `cetusdlmm::pool`

**Parameters**:

| Name | Type | Required | Description |
|------|------|----------|-------------|
| config | &GlobalConfig | Y | Global DLMM config object |
| pool | &mut Pool<A, B> | Y | Pool object |
| position | &mut Position | Y | Position NFT |
| versioned | &Versioned | Y | Version control object |

**Move Example**:

```move
public entry fun collect_cetus_rewards(
    config: &GlobalConfig,
    pool: &mut Pool<SUI, USDC>,
    position: &mut Position,
    versioned: &Versioned,
    ctx: &mut TxContext
) {
    let reward_coin = pool::collect_position_reward<SUI, USDC, CETUS>(
        config,
        pool,
        position,
        versioned,
        ctx
    );

    // CETUS rewards transferred to sender
    transfer::public_transfer(reward_coin, ctx.sender());
}
```

---

## Important Types & Structures

### Bin Structure

Bins are discrete price levels where liquidity is concentrated.

| Field | Type | Description |
|-------|------|-------------|
| bin_id | I32 | Bin identifier (signed integer) |
| amount_a | u64 | Amount of coin A in bin |
| amount_b | u64 | Amount of coin B in bin |
| liquidity | u128 | Total liquidity shares in bin |

**Bin ID Calculation**:

```typescript
import { BinUtils } from '@cetusprotocol/dlmm-sdk'

// Price to bin ID
const bin_id = BinUtils.getBinIdFromPrice(
  '2.5',    // price (1 A = 2.5 B)
  2,        // bin_step
  true,     // round_up
  9,        // decimals_a
  6         // decimals_b
)

// Bin ID to price
const price = BinUtils.getPriceFromBinId(bin_id, 2, 9, 6)
```

### Strategy Types

Three liquidity distribution strategies:

| Strategy | Value | Description | Use Case |
|----------|-------|-------------|----------|
| Spot | 0 | Uniform distribution across bins | Passive LPs, wide ranges |
| Curve | 1 | Curved distribution (more near active) | Balanced risk/reward |
| BidAsk | 2 | Liquidity on both sides of active bin | Market makers, tight spreads |

**TypeScript Enum**:

```typescript
enum StrategyType {
  Spot = 0,
  Curve = 1,
  BidAsk = 2
}
```

### Dynamic Fee Structure

DLMM uses dynamic fees that adjust based on volatility:

```
Total Fee = Base Fee + Variable Fee

Base Fee: Fixed per pool (e.g., 0.1%)
Variable Fee: Changes with volatility (0% to max)
```

**Fee Calculation**:

```typescript
// Get current fee rate
const fee_rate = await sdk.Pool.getTotalFeeRate({
  pool_id: pool.id,
  bin_step: pool.bin_step,
})

console.log('Base fee:', fee_rate.base_fee_rate)
console.log('Variable fee:', fee_rate.var_fee_rate)
console.log('Total fee:', fee_rate.total_fee_rate)
```

### Position Structure

Position NFT contains:

| Field | Type | Description |
|-------|------|-------------|
| pool_id | ID | Pool object ID |
| lower_bin_id | I32 | Lower bound bin ID |
| upper_bin_id | I32 | Upper bound bin ID |
| liquidity_shares | vector<u128> | Liquidity shares for each bin |
| index | u64 | Position index within pool |

**Key Difference from CLMM**: DLMM positions have a vector of liquidity shares (one per bin), while CLMM positions have a single liquidity value.

### BinAmount Type

```typescript
type BinAmount = {
  bin_id: number
  amount_a: string
  amount_b: string
  liquidity?: string
  price_per_lamport: string
}
```

---

## Contract Addresses & Package Info

### Mainnet Objects

| Object | Address |
|--------|---------|
| DLMM Package | `0x5664f9d3fd82c84023870cfbda8ea84e14c8dd56ce557ad2116e0668581a682b` |
| DLMM Published At | `0x42e80880109d67373e4c7ca1dd4d148dcc71ae7354b2e07f642165bc32ac472d` |
| Router Package | `0x36d7c12e8497cee9259dd6b0da9f8bbe955134d658a1e3e7c682d43c7a955125` |
| GlobalConfig | `0xf31b605d117f959b9730e8c07b08b856cb05143c5e81d5751c90d2979e82f599` |
| Registry | `0xb1d55e7d895823c65f98d99b81a69436cf7d1638629c9ccb921326039cda1f1b` |
| Versioned | `0x05370b2d656612dd5759cbe80463de301e3b94a921dfc72dd9daa2ecdeb2d0a8` |
| AdminCap | `0xc4c42bc31cb54beb679dccd547f8bdb970cb6dc989bd1f85a4fed4812ed95d6e` |
| Partners | `0x5c0affc8d363b6abb1f32790c229165215f4edead89a9bc7cd95dad717b4296a` |

### Module Structure

**DLMM Package** (`0x5664...`):
- `cetusdlmm::pool` - Core pool logic
- `cetusdlmm::position` - Position NFT management
- `cetusdlmm::bin` - Bin management
- `cetusdlmm::config` - Global configuration
- `cetusdlmm::reward` - Reward distribution
- `cetusdlmm::partner` - Partner fee sharing

**Router Package** (`0x36d7...`):
- `dlmmrouter::add_liquidity` - Simplified liquidity operations
- `dlmmrouter::swap` - Simplified swap operations
- `dlmmrouter::spot` - Spot strategy helpers
- `dlmmrouter::curve` - Curve strategy helpers
- `dlmmrouter::bid_ask` - BidAsk strategy helpers

### Package Version Tracking

**Move Registry** (check for latest package addresses):
- DLMM: https://www.moveregistry.com/package/@cetuspackages/dlmm
- Router: https://www.moveregistry.com/package/@cetuspackages/dlmm-router

**Note**: `published_at` addresses change with contract upgrades. Other object IDs (GlobalConfig, Registry, etc.) remain stable across upgrades.

---

## Edge Cases & Best Practices

### Bin Range Selection

**Narrow ranges** (e.g., ±5 bins):
- ✅ Higher capital efficiency
- ✅ More fees when price in range
- ❌ Higher impermanent loss risk
- ❌ Requires active management

**Wide ranges** (e.g., ±50 bins):
- ✅ Lower impermanent loss
- ✅ Passive management
- ❌ Lower capital efficiency
- ❌ Fewer fees

### Strategy Type Selection

**Spot Strategy**:
- Uniform distribution across all bins
- Best for: Passive LPs, wide ranges, stable pairs
- Risk: Moderate IL, lower fees per bin

**Curve Strategy**:
- More liquidity near active bin
- Best for: Balanced risk/reward, moderate volatility
- Risk: Higher IL than Spot, higher fees

**BidAsk Strategy**:
- Liquidity concentrated on both sides of active bin
- Best for: Market makers, tight spreads, high volatility
- Risk: Highest IL, highest fees

### Dynamic Fee Impact

Dynamic fees increase with volatility:
- Low volatility: Base fee only (e.g., 0.1%)
- High volatility: Base + variable fee (e.g., 0.1% + 0.5% = 0.6%)

**Benefits**:
- Protects LPs during volatile periods
- Incentivizes liquidity provision
- Reduces impermanent loss impact

**Considerations**:
- Higher fees during volatility may reduce swap volume
- Monitor fee rates when providing liquidity

### Gas Optimization

**Batch operations**:
- Open position with liquidity in one transaction (use router)
- Collect fees + rewards together
- Remove liquidity from multiple bins at once

**Avoid**:
- Opening many small positions (high NFT overhead)
- Frequent small liquidity additions (gas > fees earned)
- Single-bin operations when multi-bin is possible

### Position Management Lifecycle

1. **Open**: Choose bin range and strategy based on volatility
2. **Monitor**: Track active bin movement and fee accumulation
3. **Rebalance**: Adjust position if price moves out of range
4. **Collect**: Harvest fees regularly to compound or realize gains
5. **Close**: Remove liquidity when strategy complete

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

## Error Handling

### Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| EPoolIsBlocked | Pool operations blocked | Wait for pool to be unblocked |
| EPositionPoolNotMatch | Position doesn't belong to pool | Use correct pool for position |
| EInvalidAmountsOrBinsLength | Array length mismatch | Ensure bins, amounts_a, amounts_b same length |
| ENotEnoughLiquidity | Insufficient liquidity for swap | Reduce swap amount or try different pool |
| EAmountInNotEnough | Not enough coins | Provide more coins or reduce amount |
| EAmountOutBelowMinLimit | Output below minimum (slippage) | Increase slippage tolerance or reduce amount |
| EAmountInAboveMaxLimit | Input above maximum (slippage) | Decrease slippage tolerance or reduce amount |

### Error Handling Pattern

```typescript
// TypeScript: Get quote before swap
const quote = await sdk.Swap.preSwapQuote({
  pool_id: pool.id,
  coin_type_a: pool.coin_type_a,
  coin_type_b: pool.coin_type_b,
  a2b: true,
  by_amount_in: true,
  in_amount: '1000000000',
})

// Calculate slippage-adjusted limit
const slippage = 0.02  // 2%
const amount_limit = Math.floor(Number(quote.out_amount) * (1 - slippage))

// Execute swap with protection
const swap_payload = sdk.Swap.swapPayload({
  quote_obj: quote,
  coin_type_a: pool.coin_type_a,
  coin_type_b: pool.coin_type_b,
  by_amount_in: true,
  slippage,
})
```

---

## Comparison: DLMM vs CLMM

| Feature | DLMM | CLMM |
|---------|------|------|
| **Liquidity Model** | Discrete bins | Continuous ticks |
| **Price Levels** | Bin IDs (I32) | Tick indices (I32) |
| **Fee Structure** | Base + Variable (dynamic) | Fixed per pool |
| **Position Liquidity** | Vector of shares (per bin) | Single liquidity value |
| **Strategies** | Spot, Curve, BidAsk | Single continuous range |
| **Capital Efficiency** | High (concentrated bins) | High (concentrated ticks) |
| **Volatility Protection** | Dynamic fees | Fixed fees |
| **Router Support** | Partial (add_liquidity, swap) | Full (integrate package) |
| **Use Cases** | Volatile pairs, market making | Stable pairs, passive LPs |

**When to use DLMM**:
- Volatile token pairs (dynamic fees protect LPs)
- Market making strategies (BidAsk)
- Active liquidity management

**When to use CLMM**:
- Stable pairs (fixed fees sufficient)
- Passive liquidity provision
- Simple continuous ranges
