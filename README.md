# Cetus Skills

Claude Code skills for interacting with the [Cetus Protocol](https://www.cetus.zone/) — a DEX aggregator on the Sui blockchain.

## Skills

| Skill | Description |
|-------|-------------|
| [cetus-aggregator](skills/cetus-aggregator/SKILL.md) | Find optimal swap routes and build transaction bytes via the Cetus Aggregator V3 API |

## Setup

### Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `CETUS_API_KEY` | For swap_v3 | API key for building swap transactions ([contact Cetus](https://www.cetus.zone/)) |
| `SUI_WALLET_ADDRESS` | For swap_v3 | Your Sui wallet address for transaction building |

### Installation

**From GitHub:**

```bash
claude install-skill https://github.com/CetusProtocol/cetus-skills
```

**Local:**

Clone the repo and point Claude Code at the `skills/` directory.

## API Base URLs

| Endpoint | Base URL |
|----------|----------|
| find_routes | `https://api-sui.cetus.zone/router_v3/find_routes` |
| swap_v3 | `https://api-sui-mcp.cetus.zone/aggregator/swap_v3` |

## Structure

```
skills/
└── cetus-aggregator/
    ├── SKILL.md        # Concise skill definition (endpoints, params, flow)
    └── reference.md    # Detailed payloads, examples, edge cases
```

Each skill folder contains a `SKILL.md` for quick agent consumption and a `reference.md` with full payload shapes and curl examples.

## Resources

- [Cetus Protocol](https://www.cetus.zone/)
- [Cetus Developer Docs](https://cetus-1.gitbook.io/cetus-developer-docs/)
- [Cetus Aggregator API](https://cetus-1.gitbook.io/cetus-developer-docs/developer/via-aggregator)
- [Sui Documentation](https://docs.sui.io/)
