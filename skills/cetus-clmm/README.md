# Cetus CLMM Skill

Claude Code skill for interacting with Cetus Protocol's Concentrated Liquidity Market Maker (CLMM) on Sui blockchain.

## Overview

This skill enables you to:
- Create and manage CLMM pools with custom tick spacing
- Open and manage liquidity positions with specific price ranges
- Add and remove liquidity using delta_liquidity or fixed coin amounts
- Swap tokens with slippage protection
- Collect LP fees and reward tokens
- Query pool and position data

## Quick Start

### Installation

```bash
npm install @cetusprotocol/common-sdk@1.3.3 @cetusprotocol/sui-clmm-sdk@1.4.1
```

Tested version pair: `@cetusprotocol/common-sdk@1.3.3` + `@cetusprotocol/sui-clmm-sdk@1.4.1`.

### Basic Usage

**Create a pool:**
```move
use cetus_integrate::pool_script;

pool_script::create_pool<SUI, USDC>(
    config,
    pools,
    10,                        // tick_spacing
    29189415097064819712,      // initialize_sqrt_price
    string::utf8(b"https://example.com/position"),
    clock,
    ctx
);
```

**Open position and add liquidity:**
```move
pool_script::open_position_with_liquidity_with_all<SUI, USDC>(
    config,
    pool,
    100,                       // tick_lower
    200,                       // tick_upper
    coins_a,
    coins_b,
    1000000000,                // amount_a (1 SUI)
    2500000,                   // amount_b (2.5 USDC)
    true,                      // fix_amount_a
    clock,
    ctx
);
```

**Swap tokens:**
```move
pool_script::swap_a2b<SUI, USDC>(
    config,
    pool,
    coins_a,
    true,                      // by_amount_in
    1000000000,                // amount (1 SUI)
    2450000,                   // amount_limit (min 2.45 USDC)
    0,                         // sqrt_price_limit
    clock,
    ctx
);
```

## Documentation

- **[SKILL.md](SKILL.md)** - Concise reference with operations table, parameters, and integration flows
- **[reference/](reference/)** - Domain-specific detail loaded on demand: pools, positions, liquidity, swaps, fees-rewards, concepts

## Key Concepts

### Concentrated Liquidity

Unlike traditional AMMs that spread liquidity across all prices, CLMM allows LPs to concentrate liquidity within specific price ranges (tick ranges). This provides:
- Higher capital efficiency
- More fees for in-range positions
- Customizable risk/reward profiles

### Tick Spacing

Minimum price interval between ticks. Common values:
- `1` - 0.01% (stablecoins)
- `10` - 0.1% (standard pairs)
- `60` - 0.6% (volatile pairs)

### Position NFT

Each liquidity position is represented as an NFT containing:
- Pool reference
- Tick range (tick_lower, tick_upper)
- Liquidity amount
- Fee and reward tracking

## Contract Addresses (Mainnet)

| Object | Address |
|--------|---------|
| CLMM Package | `0x1eabed72c53feb3805120a081dc15963c204dc8d091542592abaf7a35689b2fb` |
| Integrate Package | `0x996c4d9480708fb8b92aa7acf819fb0497b5ec8e65ba06601cae2fb6db3312c3` |
| GlobalConfig | `0xdaa46292632c3c4d8f31f23ea0f9b36a28ff3677e9684980e4438403a67a3d8f` |
| Pools | `0xf699e7f2276f5c9a75944b37a0c5b5d9ddfd2471bf6242483b03ab2887d198d0` |
| Partners | `0xac30897fa61ab442f6bff518c5923faa1123c94b36bd4558910e9c783adfa204` |
| RewardVault | `0xce7bceef26d3ad1f6d9b6f13a953f053e6ed3ca77907516481ce99ae8e588f2b` |

### Package Version Tracking

Check Move Registry for latest package addresses:
- **CLMM**: https://www.moveregistry.com/package/@cetuspackages/clmm
- **Integrate**: https://www.moveregistry.com/package/@cetuspackages/integrate

Note: `published_at` addresses change with contract upgrades. Other object IDs remain stable.

## Common Operations

### Pool Management
- `create_pool` - Create new CLMM pool
- `create_pool_v3` - Create pool with initial liquidity
- `fetch_pools` - Query pool list

### Position Management
- `open_position` - Open empty position NFT
- `open_position_with_liquidity_*` - Open position with liquidity
- `close_position` - Close position and collect all
- `fetch_positions` - Query position info

### Liquidity Operations
- `add_liquidity_*` - Add liquidity by delta_liquidity
- `add_liquidity_fix_coin_*` - Add liquidity by coin amount
- `remove_liquidity` - Remove liquidity with slippage protection

### Swap Operations
- `swap_a2b` / `swap_b2a` - Single-pool swaps
- `swap_*_with_partner` - Swaps with partner fee sharing
- `calculate_swap_result` - Calculate expected output

### Fee & Reward Collection
- `collect_fee` - Collect LP fees
- `collect_reward` - Collect reward tokens
- `fetch_position_fees/rewards` - Query claimable amounts

## Resources

- **Official Docs**: [Cetus Developer Docs](https://cetus-1.gitbook.io/cetus-developer-docs)
- **SDK**: [@cetusprotocol/sui-clmm-sdk](https://www.npmjs.com/package/@cetusprotocol/sui-clmm-sdk)
- **Contracts**: [CetusProtocol/cetus-contracts](https://github.com/CetusProtocol/cetus-contracts/tree/main/packages/cetus_clmm)
- **SDK Source**: [CetusProtocol/cetus-sdk-v2](https://github.com/CetusProtocol/cetus-sdk-v2/tree/main/packages/clmm)
- **Move Registry**: [CLMM](https://www.moveregistry.com/package/@cetuspackages/clmm) | [Integrate](https://www.moveregistry.com/package/@cetuspackages/integrate)

## License

This skill documentation is provided as-is for use with Claude Code.
