---
name: cetus-dlmm
description: >
  Interact with Cetus DLMM (Dynamic Liquidity Market Maker) pools on Sui.
  Create pools, manage positions with bin strategies, swap tokens, collect fees.
  Triggers: DLMM, dynamic liquidity, bin, liquidity pool, position strategy,
  add liquidity, remove liquidity, LP, Cetus pool, open position, close position,
  collect fee, collect reward, bin step, active bin, Spot, Curve, BidAsk
---

# Cetus DLMM

Dynamic Liquidity Market Maker (DLMM) on Sui. Create pools with dynamic fees, manage liquidity positions across discrete price bins, swap tokens, and earn LP fees.

## SDK Installation

```bash
npm install @cetusprotocol/common-sdk@1.3.3 @cetusprotocol/dlmm-sdk@1.2.6 @cetusprotocol/sui-clmm-sdk@1.4.1
```

Tested compatible versions: `@cetusprotocol/common-sdk@1.3.3`, `@cetusprotocol/dlmm-sdk@1.2.6`, `@cetusprotocol/sui-clmm-sdk@1.4.1`.

## Core Concepts

| Concept | Description |
|---------|-------------|
| Bin | Discrete price level where liquidity is concentrated. Each bin has a bin_id (I32) |
| Active Bin | Current bin representing the market price |
| Bin Step | Minimum price interval between bins (similar to tick spacing in CLMM) |
| Strategy Type | Liquidity distribution strategy: Spot (uniform), Curve (curved), BidAsk (bid-ask spread) |
| Dynamic Fees | Base fee (fixed) + Variable fee (changes with volatility) |
| Position | NFT representing liquidity across multiple bins with liquidity_shares vector |

## Operations

### Pool Operations

| Function | Module | Description |
|----------|--------|-------------|
| create_pool | cetusdlmm::pool | Create new DLMM pool with bin step and initial active bin |
| fetch_bins | cetusdlmm::pool | Query bin information with pagination |
| get_total_fee_rate | cetusdlmm::pool | Get current total fee rate (base + variable) |

### Position Management

| Function | Module | Description |
|----------|--------|-------------|
| open_position | dlmmrouter::add_liquidity | Open position with liquidity (router wrapper) |
| add_liquidity | dlmmrouter::add_liquidity | Add liquidity to existing position (router wrapper) |
| remove_liquidity | cetusdlmm::pool | Remove liquidity from position (direct call) |
| remove_liquidity_by_percent | cetusdlmm::pool | Remove liquidity by percentage (direct call) |
| close_position | cetusdlmm::pool | Close position and collect all (direct call) |

### Swap Operations

| Function | Module | Description |
|----------|--------|-------------|
| swap_a2b | dlmmrouter::swap | Swap coin A to coin B (router wrapper) |
| swap_b2a | dlmmrouter::swap | Swap coin B to coin A (router wrapper) |
| swap_a2b_with_partner | dlmmrouter::swap | Swap A→B with partner fee sharing (router wrapper) |
| swap_b2a_with_partner | dlmmrouter::swap | Swap B→A with partner fee sharing (router wrapper) |

### Fee & Reward Collection

| Function | Module | Description |
|----------|--------|-------------|
| collect_position_fee | cetusdlmm::pool | Collect LP fees from position (direct call) |
| collect_position_reward | cetusdlmm::pool | Collect reward tokens from position (direct call) |
| update_position_fee_and_rewards | cetusdlmm::pool | Update fee/reward tracking (direct call) |

## Key Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| config | &GlobalConfig | Global DLMM configuration object |
| pool | &mut Pool<A, B> | Pool object for coin pair |
| position | &mut Position | Position NFT object |
| bins | vector<u32> | Vector of bin IDs to operate on |
| amounts_a | vector<u64> | Coin A amounts for each bin |
| amounts_b | vector<u64> | Coin B amounts for each bin |
| strategy_type | u8 | Liquidity distribution strategy (0=Spot, 1=Curve, 2=BidAsk) |
| by_amount_in | bool | true = fix input amount, false = fix output amount |
| amount | u64 | Swap amount (input or output depending on by_amount_in) |
| amount_limit | u64 | Slippage protection (min output or max input) |
| versioned | &Versioned | Version control object |

## Integration Flows

### Creating a Pool

```
1. Determine bin_step (price interval between bins)
2. Calculate active_id (initial bin representing starting price)
3. Call create_pool<CoinA, CoinB>(config, registry, bin_step, active_id, versioned, ctx)
4. Pool is created and ready for liquidity
```

### Opening Position with Liquidity

```
1. Choose bin range: lower_bin_id to upper_bin_id
2. Select strategy_type: Spot (0), Curve (1), or BidAsk (2)
3. Calculate bins and amounts for each bin based on strategy
4. Router approach (recommended):
   dlmmrouter::add_liquidity::open_position(pool, coin_a, coin_b, bins, amounts_a, amounts_b, config, versioned, clock, ctx)
5. Direct approach (advanced):
   a. pool::open_position() to get position and certificate
   b. pool::repay_open_position() to finalize
```

### Swapping Tokens

```
1. Determine swap direction: A→B or B→A
2. Set by_amount_in: true (fix input) or false (fix output)
3. Calculate amount_limit for slippage protection
4. Router approach (recommended):
   dlmmrouter::swap::swap_a2b(pool, coin_a, by_amount_in, amount, amount_limit, config, versioned, clock, ctx)
5. Direct approach (advanced):
   a. pool::flash_swap() to borrow coins
   b. pool::repay_flash_swap() to repay
```

### Collecting Fees and Rewards

```
1. Update position fee/reward tracking:
   pool::update_position_fee_and_rewards(pool, position, config, versioned, clock)
2. Collect fees:
   pool::collect_position_fee(pool, position, config, versioned, ctx)
3. Collect rewards (for each reward type):
   pool::collect_position_reward<CoinA, CoinB, RewardType>(pool, position, config, versioned, ctx)
```

## Router vs Direct Call

**Router wrappers** (dlmmrouter package):
- open_position - Simplified position opening with automatic repayment
- add_liquidity - Simplified liquidity addition with automatic repayment
- swap_a2b / swap_b2a - Simplified swaps with automatic flash swap repayment
- swap_*_with_partner - Partner fee sharing variants

**Direct calls** (cetusdlmm::pool):
- All other operations (remove_liquidity, close_position, collect_fee, etc.)
- Advanced users can use flash_swap + repay_flash_swap directly for custom logic

**Recommendation**: Use router wrappers for standard operations, direct calls for advanced use cases.

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| EPoolIsBlocked | Pool operations blocked | Pool is paused or restricted |
| EPositionPoolNotMatch | Position pool mismatch | Position doesn't belong to this pool |
| EInvalidAmountsOrBinsLength | Invalid arrays | bins, amounts_a, amounts_b length mismatch |
| ENotEnoughLiquidity | Insufficient liquidity | Not enough liquidity for swap |
| EAmountInZero | Zero input | Input amount is zero |
| EAmountOutIsZero | Zero output | Output amount is zero |
| EAmountInNotEnough | Insufficient coins | Not enough coins for operation |
| EAmountOutBelowMinLimit | Slippage exceeded | Output below minimum (slippage) |
| EAmountInAboveMaxLimit | Slippage exceeded | Input above maximum (slippage) |

## Contract Addresses (Mainnet)

| Object | Address |
|--------|---------|
| DLMM Package | `0x5664f9d3fd82c84023870cfbda8ea84e14c8dd56ce557ad2116e0668581a682b` |
| DLMM Published At | `0x0489a4b326c17428d9ae6f10023468109b097f10e705af30ccc27bbb18ead065` |
| Router Package | `0x36d7c12e8497cee9259dd6b0da9f8bbe955134d658a1e3e7c682d43c7a955125` |
| GlobalConfig | `0xf31b605d117f959b9730e8c07b08b856cb05143c5e81d5751c90d2979e82f599` |
| Registry | `0xb1d55e7d895823c65f98d99b81a69436cf7d1638629c9ccb921326039cda1f1b` |
| Versioned | `0x05370b2d656612dd5759cbe80463de301e3b94a921dfc72dd9daa2ecdeb2d0a8` |
| Partners | `0x5c0affc8d363b6abb1f32790c229165215f4edead89a9bc7cd95dad717b4296a` |

Detailed schemas and examples: [reference.md](reference.md).
