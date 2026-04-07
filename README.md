# Cetus Skills

Claude Code skills for interacting with the [Cetus Protocol](https://www.cetus.zone/) — a leading DeFi protocol on the Sui blockchain.

## Overview

Cetus Protocol provides three main DeFi primitives on Sui:

- **Aggregator** - Smart order routing across 28 DEX providers for best swap prices
- **CLMM** (Concentrated Liquidity Market Maker) - Capital-efficient liquidity provision with continuous tick ranges
- **DLMM** (Dynamic Liquidity Market Maker) - Discrete bin-based liquidity with dynamic fees

This repository contains Claude Code skills for all three protocols, enabling AI agents to interact with Cetus programmatically.

## Skills

| Skill | Type | Description | Documentation |
|-------|------|-------------|---------------|
| **[cetus-aggregator](skills/cetus-aggregator/)** | API | Find optimal swap routes across 28 DEX providers and build swap transactions | [README](skills/cetus-aggregator/README.md) · [SKILL.md](skills/cetus-aggregator/SKILL.md) |
| **[cetus-clmm](skills/cetus-clmm/)** | SDK | Create pools, manage positions, add/remove liquidity, swap tokens on CLMM | [README](skills/cetus-clmm/README.md) · [SKILL.md](skills/cetus-clmm/SKILL.md) |
| **[cetus-dlmm](skills/cetus-dlmm/)** | SDK | Create pools, manage positions with strategies (Spot/Curve/BidAsk), swap on DLMM | [README](skills/cetus-dlmm/README.md) · [SKILL.md](skills/cetus-dlmm/SKILL.md) |

## Quick Comparison

| Feature | Aggregator | CLMM | DLMM |
|---------|------------|------|------|
| **Use Case** | Token swaps | Liquidity provision | Liquidity provision |
| **Liquidity Model** | Multi-protocol routing | Continuous ticks | Discrete bins |
| **Fee Structure** | Provider-dependent | Fixed per pool | Base + Variable (dynamic) |
| **Integration** | REST API | TypeScript SDK + Move | TypeScript SDK + Move |
| **Best For** | Traders seeking best rates | Stable pairs, passive LPs | Volatile pairs, market making |
| **Providers** | 28 DEX protocols | Cetus CLMM only | Cetus DLMM only |

## Installation

### From GitHub

```bash
claude install-skill https://github.com/CetusProtocol/cetus-skills
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
# CLMM SDK
npm install @cetusprotocol/sui-clmm-sdk

# DLMM SDK
npm install @cetusprotocol/dlmm-sdk
```

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
│   │   └── reference.md         # Detailed SDK & Move examples
│   └── cetus-dlmm/
│       ├── README.md            # User-friendly guide
│       ├── SKILL.md             # Agent-optimized reference
│       └── reference.md         # Detailed SDK & Move examples
└── .cursor/rules/               # Cursor IDE rules
```

Each skill contains:
- **README.md** - User-friendly documentation with examples and quick start
- **SKILL.md** - Concise, agent-optimized reference (YAML frontmatter, tables, flows)
- **reference.md** - Detailed schemas, payloads, and edge cases

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
import { CetusClmmSDK } from '@cetusprotocol/sui-clmm-sdk'

const sdk = new CetusClmmSDK({ network: 'mainnet' })

// Open position with liquidity
const payload = await sdk.Position.openPositionWithLiquidityPayload({
  pool_id: '0x...',
  tick_lower: 100,
  tick_upper: 200,
  amount_a: '1000000000',  // 1 SUI
  fix_amount_a: true,
})
```

See [cetus-clmm README](skills/cetus-clmm/README.md) for full examples.

### For Market Makers (DLMM)

```typescript
import { CetusDlmmSDK, StrategyType } from '@cetusprotocol/dlmm-sdk'

const sdk = CetusDlmmSDK.createSDK({ env: 'mainnet' })

// Open position with Spot strategy
const payload = await sdk.Position.openPositionPayload({
  pool_id: '0x...',
  bin_infos: [...],
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
- [Aggregator API](https://cetus-1.gitbook.io/cetus-developer-docs/developer/via-aggregator)
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
