# Cetus Skills

Claude Code skills for interacting with the [Cetus Protocol](https://www.cetus.zone/) — a leading DeFi protocol on the Sui blockchain.

## Overview

This repository covers five Cetus capabilities on Sui:

- **Aggregator** - Smart order routing across multiple DEX providers for best swap prices
- **CLMM** (Concentrated Liquidity Market Maker) - Capital-efficient liquidity provision with continuous tick ranges
- **DLMM** (Dynamic Liquidity Market Maker) - Discrete bin-based liquidity with dynamic fees
- **Limit Orders** - Escrow tokens for execution at a specified target price
- **DCA** (Dollar-Cost Averaging) - Recurring token purchases executed by authorized keepers

These skills let AI agents quote swaps, manage liquidity, and build limit-order and DCA transactions programmatically.

## Skills

| Skill | Type | Description | Documentation |
|-------|------|-------------|---------------|
| **[cetus-aggregator](skills/cetus-aggregator/)** | API | Find optimal swap routes across multiple DEX providers and build swap transactions | [README](skills/cetus-aggregator/README.md) · [SKILL.md](skills/cetus-aggregator/SKILL.md) |
| **[cetus-clmm](skills/cetus-clmm/)** | SDK | Create pools, manage positions, add/remove liquidity, swap tokens, flash loans on CLMM | [README](skills/cetus-clmm/README.md) · [SKILL.md](skills/cetus-clmm/SKILL.md) |
| **[cetus-dlmm](skills/cetus-dlmm/)** | SDK | Create pools, manage positions with strategies (Spot/Curve/BidAsk), swap on DLMM | [README](skills/cetus-dlmm/README.md) · [SKILL.md](skills/cetus-dlmm/SKILL.md) |
| **[cetus-limitorder](skills/cetus-limitorder/)** | SDK + Move | Place, query, claim and cancel target-price orders; integrate atomic fills | [README](skills/cetus-limitorder/README.md) · [SKILL.md](skills/cetus-limitorder/SKILL.md) |
| **[cetus-dca](skills/cetus-dca/)** | SDK + Move | Open, inspect, withdraw and cancel recurring orders; integrate signed keeper execution | [README](skills/cetus-dca/README.md) · [SKILL.md](skills/cetus-dca/SKILL.md) |

## Quick Comparison

| Feature | Aggregator | CLMM | DLMM |
|---------|------------|------|------|
| **Use Case** | Token swaps | Liquidity provision | Liquidity provision |
| **Liquidity Model** | Multi-protocol routing | Continuous ticks | Discrete bins |
| **Fee Structure** | Provider-dependent | Fixed per pool | Base + Variable (dynamic) |
| **Integration** | REST API | TypeScript SDK + Move | TypeScript SDK + Move |
| **Best For** | Traders seeking best rates | Stable pairs, passive LPs | Volatile pairs, market making |
| **Providers** | Multiple DEX protocols | Cetus CLMM only | Cetus DLMM only |

### Order strategies

| Feature | Limit Orders | DCA |
|---|---|---|
| Trigger | Target price and available liquidity | Due cycle plus keeper execution |
| Time unit | Expiry in milliseconds | Frequency and timestamps in seconds |
| User controls | Pay amount, minimum target/pay price, expiry | Deposit, cycles, frequency, output bounds |
| Opening authorization | Wallet owner | Wallet owner + authorized oracle signature |
| Execution | Atomic pay-coin borrow / target-coin repayment | Authorized keeper + threshold signatures + atomic repayment |
| Skill | [cetus-limitorder](skills/cetus-limitorder/SKILL.md) | [cetus-dca](skills/cetus-dca/SKILL.md) |

Order objects are shared and indexed. Execution depends on external fillers/keepers; neither strategy guarantees a fill or deploys a background service.

## Installation

### From GitHub

```bash
npx skills add CetusProtocol/cetus-skills
```

### Local Development

```bash
git clone https://github.com/CetusProtocol/cetus-skills.git
cd cetus-skills
# Point Claude Code at the skills/ directory
```

### SDK Installation

For CLMM and DLMM skills, install the respective SDKs:

```bash
# Version snapshot: 2026-10-21
npm install @mysten/sui@2.31.2 blakejs @cetusprotocol/common-sdk@1.4.3 @cetusprotocol/dlmm-sdk@1.3.3 @cetusprotocol/sui-clmm-sdk@1.4.9
```

These are the npm `latest` versions checked on 2026-10-21. The SDKs require `@mysten/sui >=2.28.0`; the examples use 2.31.2. CLMM/DLMM require `blakejs` as a peer dependency. Mainnet configurations are exported by their respective SDK packages. Sui 2.x integrations use gRPC and GraphQL. See [upstream verification](UPSTREAM.md) for sources and validation scope.

For limit orders and DCA, use the dedicated installation commands in their skill guides. Their contract/source snapshots and SDK verification were added on 2026-10-26; see [upstream verification](UPSTREAM.md#limit-order-and-dca-skills-2026-10-26).

## Environment Variables

| Variable | Required For | Description |
|----------|--------------|-------------|
| `SUI_WALLET_ADDRESS` | cetus-aggregator | Your Sui wallet address for transaction building |

## Repository Structure

```
cetus-skills/
├── README.md                    # This file - project overview
├── CLAUDE.md                    # Claude Code guidance
├── skills/
│   ├── cetus-aggregator/
│   │   ├── README.md            # User-friendly guide
│   │   ├── SKILL.md             # Agent-optimized reference
│   │   └── reference.md         # Detailed API schemas
│   ├── cetus-clmm/
│   │   ├── README.md            # User-friendly guide
│   │   ├── SKILL.md             # Agent-optimized reference
│   │   └── reference/           # Topic-specific SDK & Move examples
│   ├── cetus-dlmm/
│   │   ├── README.md            # User-friendly guide
│   │   ├── SKILL.md             # Agent-optimized reference
│   │   └── reference/           # Topic-specific SDK & Move examples
│   ├── cetus-limitorder/
│   │   ├── README.md
│   │   ├── SKILL.md
│   │   └── reference/           # User orders, keeper flow, contract ABI/provenance
│   └── cetus-dca/
│       ├── README.md
│       ├── SKILL.md
│       └── reference/           # User orders, signatures/keepers, contract ABI/provenance
└── UPSTREAM.md                  # Version snapshot, sources & verification
```

Each skill contains:
- **README.md** - User-friendly documentation with examples and quick start
- **SKILL.md** - Concise, agent-optimized reference (YAML frontmatter, tables, flows)
- **reference.md** (Aggregator) or **reference/** (SDK/Move skills) - Detailed schemas, payloads, and edge cases

## Getting Started

### For Traders (Aggregator)

```bash
# Get best swap quote for 1 SUI → USDC
curl "https://api-sui.cetus.zone/router_v3/find_routes?\
from=0x2::sui::SUI&\
target=0xdba34672e30cb065b1f93e3ab55318768fd6fef66c15942c9f7cb846e2f900e7::usdc::USDC&\
amount=1000000000&\
by_amount_in=true&\
v=1999999"
```

See [cetus-aggregator README](skills/cetus-aggregator/README.md) for full integration flow.

### For Liquidity Providers (CLMM)

```typescript
import { CetusClmmSDK, clmmMainnet } from '@cetusprotocol/sui-clmm-sdk'
import { TickMath } from '@cetusprotocol/common-sdk'

const sdk = CetusClmmSDK.createSDK(clmmMainnet)
const pool = await sdk.Pool.getPool('0x...') // replace with a CLMM pool ID
const tick = Number(pool.current_tick_index)
const spacing = Number(pool.tick_spacing)
const payload = sdk.Position.openPositionPayload({
  pool_id: pool.id,
  coin_type_a: pool.coin_type_a,
  coin_type_b: pool.coin_type_b,
  tick_lower: TickMath.getPrevInitializeTickIndex(tick, spacing).toString(),
  tick_upper: TickMath.getNextInitializeTickIndex(tick, spacing).toString(),
}) // unsigned transaction opening an empty position
```

See [cetus-clmm README](skills/cetus-clmm/README.md) for full examples.

### For Market Makers (DLMM)

```typescript
import { CetusDlmmSDK, StrategyType, dlmmMainnet } from '@cetusprotocol/dlmm-sdk'

const sdk = CetusDlmmSDK.createSDK(dlmmMainnet)
sdk.setSenderAddress('0x...') // replace with wallet address


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

See [cetus-dlmm README](skills/cetus-dlmm/README.md) for full examples.

## Resources

### Official Documentation
- [Cetus Protocol](https://www.cetus.zone/)
- [Cetus Developer Docs](https://cetus-1.gitbook.io/cetus-developer-docs/)
- [Sui Documentation](https://docs.sui.io/)

### API & SDKs
- [Aggregator API](https://cetus-1.gitbook.io/cetus-developer-docs/developer/cetus-aggregator)
- [CLMM SDK](https://www.npmjs.com/package/@cetusprotocol/sui-clmm-sdk)
- [DLMM SDK](https://www.npmjs.com/package/@cetusprotocol/dlmm-sdk)

### Source Code
- [CLMM Contracts](https://github.com/CetusProtocol/cetus-contracts)
- [DLMM Interface](https://github.com/CetusProtocol/cetus-dlmm-interface)
- [Cetus SDK V2](https://github.com/CetusProtocol/cetus-sdk-v2)

### Move Registry
- [CLMM Package](https://www.moveregistry.com/package/@cetuspackages/clmm)
- [DLMM Package](https://www.moveregistry.com/package/@cetuspackages/dlmm)
- [Integrate Package](https://www.moveregistry.com/package/@cetuspackages/integrate)

## License

This skill documentation is provided as-is for use with Claude Code.
