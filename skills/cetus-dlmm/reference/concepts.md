# DLMM — Concepts & Utilities

Cross-cutting reference data: bins, strategy types, dynamic fees, common coins. Error codes and contract addresses live in [SKILL.md](../SKILL.md).

## Contents

- [Bin structure](#bin-structure)
- [BinUtils helpers](#binutils-helpers)
- [Strategy types](#strategy-types)
- [Dynamic fee structure](#dynamic-fee-structure)
- [Common coin types](#common-coin-types)
- [Range selection trade-offs](#range-selection-trade-offs)

## Bin structure

Bins are discrete price levels where liquidity is concentrated.

| Field | Type | Description |
|-------|------|-------------|
| bin_id | I32 | Bin identifier (signed) |
| amount_a | u64 | Amount of coin A in bin |
| amount_b | u64 | Amount of coin B in bin |
| liquidity | u128 | Total liquidity shares in bin |

```typescript
type BinAmount = {
  bin_id: number
  amount_a: string
  amount_b: string
  liquidity?: string
  price_per_lamport: string
}
```

## BinUtils helpers

```typescript
import { BinUtils } from '@cetusprotocol/dlmm-sdk'

// Price ↔ bin_id (decimals-aware)
const bin_id = BinUtils.getBinIdFromPrice('2.5', 2, true, 9, 6)  // round_up=true
const price = BinUtils.getPriceFromBinId(bin_id, 2, 9, 6)
```

## Strategy types

| Strategy | Value | Distribution | Use case |
|---|---|---|---|
| Spot | 0 | Uniform across all bins | Passive LPs, wide ranges |
| Curve | 1 | Concentrated near active bin | Balanced risk / reward |
| BidAsk | 2 | Concentrated on both ends of range | Market makers, tight spreads |

```typescript
enum StrategyType {
  Spot = 0,
  Curve = 1,
  BidAsk = 2,
}
```

## Dynamic fee structure

```
Total Fee = Base Fee + Variable Fee
Base Fee:     fixed per pool (e.g., 0.1%)
Variable Fee: scales with realized volatility (0% → cap)
```

Query the current rate:

```typescript
const fee_rate = await sdk.Pool.getTotalFeeRate({
  pool_id: pool.id,
  bin_step: pool.bin_step,
})
// fee_rate.base_fee_rate, fee_rate.var_fee_rate, fee_rate.total_fee_rate
```

The variable component widens during volatile periods — protective for LPs, punishing for swappers.

## Common coin types

| Token | Decimals | Coin type | 1 token = |
|-------|----------|-----------|-----------|
| SUI | 9 | `0x0000000000000000000000000000000000000000000000000000000000000002::sui::SUI` | 1,000,000,000 |
| USDC | 6 | `0xdba34672e30cb065b1f93e3ab55318768fd6fef66c15942c9f7cb846e2f900e7::usdc::USDC` | 1,000,000 |
| USDT | 6 | `0xc060006111016b8a020ad5b33834984a437aaa7d3c74c18e09a95d48aceab08c::coin::COIN` | 1,000,000 |
| CETUS | 9 | `0x06864a6f921804860930db6ddbe2e16acdf8504495ea7481637a1c8b9a8fe54b::cetus::CETUS` | 1,000,000,000 |
| DEEP | 6 | `0xdeeb7a4662eec9f2f3def03fb937a663dddaa2e215b8078a284d026b7946c270::deep::DEEP` | 1,000,000 |

Amount formula: `amount = human_amount * 10^decimals`.

## Range selection trade-offs

- **Narrow range (±5 bins)** → high capital efficiency and fee yield in-range, higher IL, needs active rebalancing.
- **Wide range (±50 bins)** → passive, lower IL, lower fee yield.
- **Strategy choice** scales with the range: `Spot` for wide passive positions, `Curve` for balanced, `BidAsk` for tight market-making spreads.
