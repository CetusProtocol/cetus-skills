# Cetus DLMM Skill

Claude Code skill for interacting with Cetus Protocol's Dynamic Liquidity Market Maker (DLMM) on Sui blockchain.

## Overview

This skill enables you to:
- Create and manage DLMM pools with dynamic fees
- Open and manage liquidity positions with three distribution strategies (Spot, Curve, BidAsk)
- Add and remove liquidity across discrete price bins
- Swap tokens with slippage protection
- Collect LP fees and reward tokens
- Query pool and position data

## Quick Start

### Installation

```bash
npm install @mysten/sui@2.31.2 blakejs @cetusprotocol/common-sdk@1.4.3 @cetusprotocol/dlmm-sdk@1.3.3 @cetusprotocol/sui-clmm-sdk@1.4.9
```

Version snapshot checked against npm on 2026-10-21: `@cetusprotocol/common-sdk@1.4.3`, `@cetusprotocol/dlmm-sdk@1.3.3`, `@cetusprotocol/sui-clmm-sdk@1.4.9`.

Migration note: this snapshot uses Sui SDK 2.x (gRPC + GraphQL). Import `dlmmMainnet` from `@cetusprotocol/dlmm-sdk`. Opening with liquidity uses `addLiquidityPayload`; pass the complete `BinLiquidityInfo`, range, active bin, bin step, and price slippage. See [positions](reference/positions.md).

### Basic Usage

**Create a pool:**
```typescript
import { CetusDlmmSDK, BinUtils } from '@cetusprotocol/dlmm-sdk'
import { dlmmMainnet } from '@cetusprotocol/dlmm-sdk'
import { Transaction } from '@mysten/sui/transactions'

const sdk = CetusDlmmSDK.createSDK(dlmmMainnet)
sdk.setSenderAddress(walletAddress) // wallet used for funded transaction building

const bin_step = 2
const active_id = BinUtils.getBinIdFromPrice('2.5', bin_step, true, 9, 6)

// Build pool transaction payload
const tx = new Transaction()
const create_pool_payload = sdk.Pool.createPoolPayload({
  coin_type_a: '0x2::sui::SUI',
  coin_type_b: '0xdba34672e30cb065b1f93e3ab55318768fd6fef66c15942c9f7cb846e2f900e7::usdc::USDC',
  bin_step,
  base_factor: 1000, // example; choose a supported fee configuration
  active_id,
}, tx)
```

**Open position with liquidity (Spot strategy):**
```typescript
import { StrategyType } from '@cetusprotocol/dlmm-sdk'

// Fetch pool
const poolAddress = '0x...' // DLMM pool object id
const pool = await sdk.Pool.getPool(poolAddress)

// Calculate liquidity distribution
const bin_infos = await sdk.Position.calculateAddLiquidityInfo({
  active_id: pool.active_id,
  bin_step: pool.bin_step,
  lower_bin_id: pool.active_id - 10,
  upper_bin_id: pool.active_id + 10,
  pool_id: pool.id, // fetch real active-bin balances
  strategy_type: StrategyType.Spot,
  coin_amount: '1000000000',  // 1 SUI
  fix_amount_a: true,
})

// Open position
const tx = await sdk.Position.addLiquidityPayload({
  pool_id: pool.id,
  coin_type_a: pool.coin_type_a,
  coin_type_b: pool.coin_type_b,
  lower_bin_id: pool.active_id - 10,
  upper_bin_id: pool.active_id + 10,
  active_id: pool.active_id,
  bin_step: pool.bin_step,
  max_price_slippage: 0.01,
  bin_infos,
  strategy_type: StrategyType.Spot,
})
```

**Swap tokens:**
```typescript
// Fetch pool
const poolAddress = '0x...' // DLMM pool object id
const pool = await sdk.Pool.getPool(poolAddress)

// Get quote
const quote = await sdk.Swap.preSwapQuote({
  pool_id: pool.id,
  coin_type_a: pool.coin_type_a,
  coin_type_b: pool.coin_type_b,
  a2b: true,
  by_amount_in: true,
  in_amount: '1000000000',  // 1 SUI
})

// Execute swap
const tx = sdk.Swap.swapPayload({
  quote_obj: quote,
  coin_type_a: pool.coin_type_a,
  coin_type_b: pool.coin_type_b,
  by_amount_in: true,
  slippage: 0.01,  // 1%
})
```

## Documentation

- **[SKILL.md](SKILL.md)** - Concise reference with operations table, parameters, and integration flows
- **[reference/](reference/)** - Domain-specific detail loaded on demand: pools, positions, liquidity, swaps, fees-rewards, concepts

## Key Concepts

### Bins

Discrete price levels where liquidity is concentrated. Each bin has a bin_id (I32) representing a specific price point.

```
Bin 23000: 1 SUI = 2.48 USDC
Bin 23001: 1 SUI = 2.49 USDC  ← Active bin (current price)
Bin 23002: 1 SUI = 2.50 USDC
```

### Strategy Types

Three liquidity distribution strategies:

| Strategy | Description | Use Case |
|----------|-------------|----------|
| **Spot** | Uniform distribution across bins | Passive LPs, wide ranges |
| **Curve** | More liquidity near active bin | Balanced risk/reward |
| **BidAsk** | Liquidity on both sides of active | Market makers, tight spreads |

### Dynamic Fees

DLMM uses dynamic fees that adjust based on volatility:

```
Total Fee = Base Fee + Variable Fee

Base Fee: Fixed per pool (e.g., 0.1%)
Variable Fee: Changes with volatility (0% to max)
```

This protects LPs during volatile periods and incentivizes liquidity provision.

### Position NFT

Each liquidity position is represented as an NFT containing:
- Pool reference
- Bin range (lower_bin_id to upper_bin_id)
- Liquidity shares vector (one per bin)
- Fee and reward tracking

## Contract Addresses (Mainnet)

Snapshot from the SDK mainnet configuration on 2026-10-21. `Package` is the original type identity; `Published At` is the upgrade used for Move calls. Prefer the SDK configuration over hardcoded call targets.

| Object | Address |
|--------|---------|
| DLMM Package | `0x5664f9d3fd82c84023870cfbda8ea84e14c8dd56ce557ad2116e0668581a682b` |
| DLMM Published At | `0x6b989f9b05bd11a00f1c7779443d66802c5e71631f59e87be5d2a616991f151e` |
| Router Package | `0x8d389fa25cb08ebc5e520bc520ed394eed9e62b56b7868acb398bf298b8a76f3` |
| Router Published At | `0x8937cf16447e9fd8f0db24f1e05364be0422585e0954b86afb18693510b6ca5b` |
| GlobalConfig | `0xf31b605d117f959b9730e8c07b08b856cb05143c5e81d5751c90d2979e82f599` |
| Registry | `0xb1d55e7d895823c65f98d99b81a69436cf7d1638629c9ccb921326039cda1f1b` |
| Versioned | `0x05370b2d656612dd5759cbe80463de301e3b94a921dfc72dd9daa2ecdeb2d0a8` |
| Partners | `0x5c0affc8d363b6abb1f32790c229165215f4edead89a9bc7cd95dad717b4296a` |

### Package Version Tracking

Check Move Registry for latest package addresses:
- **DLMM**: https://www.moveregistry.com/package/@cetuspackages/dlmm
- **Router**: https://www.moveregistry.com/package/@cetuspackages/dlmm-router

Note: `published_at` addresses change with contract upgrades. Other object IDs remain stable.

## Common Operations

### Pool Management
- `create_pool` - Create new DLMM pool
- `fetch_bins` - Query bin information
- `get_total_fee_rate` - Get current fee rate

### Position Management
- `open_position` - Open position with liquidity (router)
- `add_liquidity` - Add liquidity to position (router)
- `remove_liquidity` - Remove liquidity from position
- `close_position` - Close position and collect all

### Swap Operations
- `swap_a2b` / `swap_b2a` - Single-pool swaps (router)
- `swap_*_with_partner` - Swaps with partner fee sharing (router)
- `preSwapQuote` - Calculate expected output

### Fee & Reward Collection
- `collect_position_fee` - Collect LP fees
- `collect_position_reward` - Collect reward tokens
- `collectRewardAndFeePayload` - Collect both together

## Router vs Direct Call

**Router wrappers** (dlmmrouter package):
- Simplified operations with automatic repayment
- Available for: open_position, add_liquidity, swap operations
- Recommended for standard use cases

**Direct calls** (cetusdlmm::pool):
- All other operations (remove_liquidity, close_position, collect_fee, etc.)
- Advanced users can use flash_swap + repay_flash_swap for custom logic

## Resources

- **SDK**: [@cetusprotocol/dlmm-sdk](https://www.npmjs.com/package/@cetusprotocol/dlmm-sdk)
- **Contract Interface**: [CetusProtocol/cetus-dlmm-interface](https://github.com/CetusProtocol/cetus-dlmm-interface)
- **SDK Source**: [CetusProtocol/cetus-sdk-v2/packages/dlmm](https://github.com/CetusProtocol/cetus-sdk-v2/tree/main/packages/dlmm)
- **Move Registry**: [DLMM](https://www.moveregistry.com/package/@cetuspackages/dlmm) | [Router](https://www.moveregistry.com/package/@cetuspackages/dlmm-router)

## DLMM vs CLMM

| Feature | DLMM | CLMM |
|---------|------|------|
| **Liquidity Model** | Discrete bins | Continuous ticks |
| **Fee Structure** | Base + Variable (dynamic) | Fixed per pool |
| **Strategies** | Spot, Curve, BidAsk | Single continuous range |
| **Best For** | Volatile pairs, market making | Stable pairs, passive LPs |

## License

This skill documentation is provided as-is for use with Claude Code.
