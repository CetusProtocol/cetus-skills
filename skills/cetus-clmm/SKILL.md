---
name: cetus-clmm
description: >
  Interact with Cetus CLMM (Concentrated Liquidity Market Maker) pools on Sui.
  Create pools, manage positions, add/remove liquidity, swap tokens, collect fees.
  Triggers: CLMM, concentrated liquidity, liquidity pool, position, tick range,
  add liquidity, remove liquidity, LP, liquidity provider, pool creation, Cetus pool,
  open position, close position, collect fee, collect reward, tick spacing, sqrt price
---

# Cetus CLMM

Concentrated Liquidity Market Maker (CLMM) on Sui. Create pools, manage liquidity positions with custom tick ranges, swap tokens, and earn LP fees.

## SDK Installation

```bash
npm install @cetusprotocol/sui-clmm-sdk
```

## Core Concepts

| Concept | Description |
|---------|-------------|
| Tick Spacing | Minimum price interval between ticks. Common values: 1, 2, 10, 60, 200 |
| Sqrt Price | Square root of price ratio, used for efficient on-chain calculations |
| Position | NFT representing liquidity within a specific tick range (tick_lower to tick_upper) |
| Liquidity | Amount of capital provided to a position, measured as delta_liquidity |
| Flash Swap | Borrow-repay mechanism allowing atomic swaps without upfront capital |

## Operations

### Pool Operations

| Function | Module | Description |
|----------|--------|-------------|
| create_pool | pool_script | Create new CLMM pool with tick spacing and initial sqrt price |
| create_pool_v3 | pool_creator_v3 | Create pool with initial liquidity position in one transaction |
| fetch_pools | fetcher_script | Query pool list with pagination |

### Position Management

| Function | Module | Description |
|----------|--------|-------------|
| open_position | pool_script | Open empty position NFT within tick range |
| open_position_with_liquidity_with_all | pool_script | Open position and add liquidity (both coins) |
| open_position_with_liquidity_only_a | pool_script | Open position and add liquidity (coin A only) |
| open_position_with_liquidity_only_b | pool_script | Open position and add liquidity (coin B only) |
| close_position | pool_script | Close position, remove all liquidity, collect fees |
| fetch_positions | fetcher_script | Query position info with pagination |

### Liquidity Operations

| Function | Module | Description |
|----------|--------|-------------|
| add_liquidity_with_all | pool_script | Add liquidity by delta_liquidity (both coins) |
| add_liquidity_only_a | pool_script | Add liquidity by delta_liquidity (coin A only) |
| add_liquidity_only_b | pool_script | Add liquidity by delta_liquidity (coin B only) |
| add_liquidity_fix_coin_with_all | pool_script | Add liquidity by fixed coin amount (both coins) |
| add_liquidity_fix_coin_only_a | pool_script | Add liquidity by fixed coin amount (coin A only) |
| add_liquidity_fix_coin_only_b | pool_script | Add liquidity by fixed coin amount (coin B only) |
| remove_liquidity | pool_script | Remove liquidity from position with slippage protection |

### Swap Operations

| Function | Module | Description |
|----------|--------|-------------|
| swap_a2b | pool_script | Swap coin A to coin B in single pool |
| swap_b2a | pool_script | Swap coin B to coin A in single pool |
| swap_a2b_with_partner | pool_script | Swap A→B with partner fee sharing |
| swap_b2a_with_partner | pool_script | Swap B→A with partner fee sharing |
| calculate_swap_result | fetcher_script | Calculate expected swap output without executing |

### Fee & Reward Collection

| Function | Module | Description |
|----------|--------|-------------|
| collect_fee | pool_script | Collect LP fees from position |
| collect_reward | pool_script | Collect reward tokens from position |
| fetch_position_fees | fetcher_script | Query claimable fees for position |
| fetch_position_rewards | fetcher_script | Query claimable rewards for position |

## Key Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| config | &GlobalConfig | Global CLMM configuration object |
| pool | &mut Pool<A, B> | Pool object for coin pair |
| position_nft | &mut Position | Position NFT object |
| tick_lower | u32 | Lower tick index of position range |
| tick_upper | u32 | Upper tick index of position range |
| delta_liquidity | u128 | Amount of liquidity to add/remove |
| amount | u64 | Coin amount (smallest unit) |
| fix_amount_a | bool | true = fix coin A amount, false = fix coin B amount |
| by_amount_in | bool | true = fix input amount, false = fix output amount |
| amount_limit | u64 | Slippage protection (min output or max input) |
| sqrt_price_limit | u128 | Price boundary for swap (0 = no limit) |

## Integration Flows

### Creating a Pool

```
1. Determine tick_spacing (1, 2, 10, 60, 200)
2. Calculate initialize_sqrt_price from desired price
3. Call create_pool<CoinA, CoinB>(config, pools, tick_spacing, initialize_sqrt_price, url, clock, ctx)
4. Pool is created and ready for liquidity
```

### Opening Position and Adding Liquidity

```
1. Choose tick range: tick_lower and tick_upper
2. Option A - Two-step:
   a. open_position(config, pool, tick_lower, tick_upper, ctx)
   b. add_liquidity_fix_coin_with_all(config, pool, position_nft, coins_a, coins_b, amount_a, amount_b, fix_amount_a, clock, ctx)
3. Option B - One-step:
   open_position_with_liquidity_with_all(config, pool, tick_lower, tick_upper, coins_a, coins_b, amount_a, amount_b, fix_amount_a, clock, ctx)
```

### Swapping Tokens

```
1. Determine swap direction: A→B or B→A
2. Set by_amount_in: true (fix input) or false (fix output)
3. Calculate amount_limit for slippage protection
4. Call swap_a2b or swap_b2a with parameters
5. Receive swapped coins automatically
```

### Removing Liquidity and Closing Position

```
1. Query position liquidity amount
2. remove_liquidity(config, pool, position_nft, delta_liquidity, min_amount_a, min_amount_b, clock, ctx)
3. Optionally: close_position to remove all liquidity and burn NFT
```

## Partner Integration

Partners holding a `Partner` object can earn fee share on swaps:

```move
// Use partner-enabled swap functions
swap_a2b_with_partner(config, pool, partner, coins_a, by_amount_in, amount, amount_limit, sqrt_price_limit, clock, ctx)
```

Partner fees accumulate in the Partner object and can be collected separately.

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| 0 | EAmountInAboveMaxLimit | Input amount exceeds max limit (slippage) |
| 1 | EAmountOutBelowMinLimit | Output amount below min limit (slippage) |
| 2 | ESwapAmountIncorrect | Swap amount mismatch |
| 4 | ECoinBelowThreshold | Coin balance below required threshold |

## Contract Addresses (Mainnet)

| Object | Address |
|--------|---------|
| CLMM Package | `0x1eabed72c53feb3805120a081dc15963c204dc8d091542592abaf7a35689b2fb` |
| Integrate Package | `0x996c4d9480708fb8b92aa7acf819fb0497b5ec8e65ba06601cae2fb6db3312c3` |
| GlobalConfig | `0xdaa46292632c3c4d8f31f23ea0f9b36a28ff3677e9684980e4438403a67a3d8f` |
| Pools | `0xf699e7f2276f5c9a75944b37a0c5b5d9ddfd2471bf6242483b03ab2887d198d0` |
| Partners | `0xac30897fa61ab442f6bff518c5923faa1123c94b36bd4558910e9c783adfa204` |
| RewardVault | `0xce7bceef26d3ad1f6d9b6f13a953f053e6ed3ca77907516481ce99ae8e588f2b` |

Detailed schemas and examples: [reference.md](reference.md).
