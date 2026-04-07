# Cetus Aggregator Skill

Claude Code skill for interacting with Cetus Protocol's DEX Aggregator V3 on Sui blockchain.

## Overview

This skill enables you to:
- Find optimal swap routes across 28 DEX providers on Sui
- Get real-time price quotes for token pairs
- Build unsigned swap transactions with slippage protection
- Compare prices and liquidity across multiple protocols

## Quick Start

### API Endpoints

No SDK installation required. Direct API access:

| Endpoint | URL |
|----------|-----|
| find_routes | `https://api-sui.cetus.zone/router_v3/find_routes` |
| swap_v3 | `https://api-sui-mcp.cetus.zone/aggregator/swap_v3` |

### Basic Usage

**Get swap quote:**
```bash
curl "https://api-sui.cetus.zone/router_v3/find_routes?\
from=0x2::sui::SUI&\
target=0xdba34672e30cb065b1f93e3ab55318768fd6fef66c15942c9f7cb846e2f900e7::usdc::USDC&\
amount=1000000000&\
by_amount_in=true&\
v=1999999"
```

**Build swap transaction:**
```bash
curl -X POST "https://api-sui-mcp.cetus.zone/aggregator/swap_v3" \
  -H "Content-Type: application/json" \
  -d '{
    "request_id": "...",
    "wallet": "0x...",
    "slippage": 0.005
  }'
```

## Documentation

- **[SKILL.md](SKILL.md)** - Concise reference with endpoints, parameters, and integration flow
- **[reference.md](reference.md)** - Detailed response schemas and examples

## Key Concepts

### DEX Aggregation

The Cetus Aggregator scans 28 DEX providers on Sui to find the best swap price:
- Automatically splits orders across multiple pools for better rates
- Supports multi-hop routing (up to 3 hops)
- Compares liquidity depth across all providers

### Supported Providers (28)

CETUS, SCALLOP, AFTERMATH, FLOWXV3, AFSUI, VOLO, KRIYAV3, KRIYA, ALPHAFI, FLOWX, BLUEMOVE, DEEPBOOKV3, BLUEFIN, HAEDAL, TURBOS, SPRINGSUI, STEAMM, METASTABLE, HAWAL, OBRIC, STEAMM_OMM_V2, STEAMM_OMM, MOMENTUM, MAGMA, FERRADLMM, FERRACLMM, HAEDALPMM, HAEDALHMMV2

### Slippage Protection

Slippage controls how much price movement you accept during the swap:
- **Recommended**: 0.5% (0.005) for stablecoins, 1% (0.01) for volatile pairs
- **Maximum**: 50% (0.5) - values above this are rejected
- Higher slippage = higher risk of asset loss

## Common Token Types

| Token | Decimals | Coin Type |
|-------|----------|-----------|
| SUI | 9 | `0x2::sui::SUI` |
| USDC | 6 | `0xdba34672e30cb065b1f93e3ab55318768fd6fef66c15942c9f7cb846e2f900e7::usdc::USDC` |
| USDT | 6 | `0xc060006111016b8a020ad5b33834984a437aaa7d3c74c18e09a95d48aceab08c::coin::COIN` |
| CETUS | 9 | `0x06864a6f921804860930db6ddbe2e16acdf8504495ea7481637a1c8b9a8fe54b::cetus::CETUS` |
| DEEP | 6 | `0xdeeb7a4662eec9f2f3def03fb937a663dddaa2e215b8078a284d026b7946c270::deep::DEEP` |

**Amount conversion**: `amount = human_amount × 10^decimals`
- Example: 1 SUI = 1000000000 (9 decimals)
- Example: 5 USDC = 5000000 (6 decimals)

## Integration Flow

```
1. Collect user inputs:
   - Source token (from)
   - Target token (target)
   - Amount to swap
   - Wallet address
   - Slippage tolerance

2. Call find_routes:
   GET /find_routes?from=...&target=...&amount=...&by_amount_in=true&v=1999999
   → Returns: request_id, amount_in, amount_out, route details

3. Display quote to user (convert amounts to human-readable)

4. On user confirmation, call swap_v3:
   POST /swap_v3 { request_id, wallet, slippage }
   → Returns: unsigned transaction bytes (base64)

5. Sign transaction with user's wallet and submit to Sui blockchain
```

## Common Parameters

### find_routes

| Parameter | Required | Description |
|-----------|----------|-------------|
| from | Yes | Source coin type (full address) |
| target | Yes | Target coin type (full address) |
| amount | Yes | Amount in smallest unit |
| by_amount_in | No | `true` = fix input (default), `false` = fix output |
| v | Yes | Always use `1999999` for latest liquidity |
| split_count | No | Order splitting (1-50, default 50) |
| depth | No | Max routing hops (1-3, default 3) |

### swap_v3

| Parameter | Required | Description |
|-----------|----------|-------------|
| request_id | Yes | From find_routes response |
| wallet | Yes | User's Sui wallet address |
| slippage | Yes | Slippage tolerance (≤ 0.5) |

## Error Handling

| Code | Meaning | Action |
|------|---------|--------|
| 200 | Success | Proceed with transaction |
| 4000 | Bad Request | Check parameter format |
| 5000 | Insufficient liquidity | Try smaller amount or different pair |
| 5040 | Unsupported API version | Ensure `v=1999999` is set |

## Resources

- **Official Docs**: [Cetus Aggregator API](https://cetus-1.gitbook.io/cetus-developer-docs/developer/via-aggregator)
- **Cetus Protocol**: [cetus.zone](https://www.cetus.zone/)
- **Sui Documentation**: [docs.sui.io](https://docs.sui.io/)

## Aggregator vs CLMM/DLMM

| Feature | Aggregator | CLMM/DLMM |
|---------|------------|-----------|
| **Purpose** | Best-price token swaps | Liquidity provision & swaps |
| **Providers** | 28 DEX protocols | Single protocol (Cetus) |
| **Routing** | Multi-hop, order splitting | Direct pool access |
| **Best For** | Traders seeking best rates | LPs earning fees |
| **Integration** | REST API | SDK + Move contracts |

## License

This skill documentation is provided as-is for use with Claude Code.
