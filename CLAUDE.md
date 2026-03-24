# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository (`CetusProtocol/cetus-skills`) contains Claude Code skills for interacting with the Cetus Protocol — a DEX aggregator on the Sui blockchain. The skills wrap the Cetus Aggregator V3 API to provide token swap routing and transaction building.

## Repository Structure

```
cetus-skills/
├── CLAUDE.md                               # This file — project guidance
├── README.md                               # Project overview & installation
├── requirments.md                          # Raw API documentation (source material)
├── .cursor/rules/                          # Cursor IDE rule files
└── skills/
    └── cetus-aggregator/
        ├── SKILL.md                        # Concise skill definition
        └── reference.md                    # Detailed payloads & examples
```

## Skill Format Conventions

Each skill is a folder under `skills/` containing two files:
- **SKILL.md** — Concise, agent-optimized: YAML frontmatter with trigger terms, endpoint tables, param tables (Y/N for required), integration flow, error codes. Ends with link to reference.md.
- **reference.md** — Detailed: full JSON response examples, field-by-field schema tables, curl examples, edge cases.

## Cetus Aggregator V3 API

Two core endpoints (see `skills/cetus-aggregator/SKILL.md` for full details):

| Endpoint | Method | URL |
|----------|--------|-----|
| find_routes | GET | `https://api-sui.cetus.zone/router_v3/find_routes` |
| swap_v3 | POST | `https://api-sui-mcp.cetus.zone/aggregator/swap_v3` |

**Flow:** find_routes → `request_id` → swap_v3 → unsigned tx bytes → sign & submit.

## Sui-Specific Context

- **Coin types** use full addresses: `{package_id}::{module}::{struct}` (e.g., `0x2::sui::SUI`)
- **Amounts** are always in smallest denomination (SUI: 9 decimals, USDC: 6 decimals)
- **Transaction bytes** from the API are unsigned — signing is client-side and SDK-dependent

## Adding New Skills

1. Create `skills/<skill-name>/` directory
2. Add `SKILL.md` with YAML frontmatter (`name`, `description` with trigger terms)
3. Add `reference.md` with full payload shapes and examples
4. Update `README.md` skills table
5. Follow conventions in `.cursor/rules/skills-token-optimization.mdc`
