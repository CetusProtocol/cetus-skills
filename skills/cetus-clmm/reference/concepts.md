# CLMM — Concepts & Utilities

Cross-cutting reference data: tick math, sqrt price, coin ordering, common coins. Error codes and contract addresses live in [SKILL.md](../SKILL.md).

## Contents

- [Tick spacing tiers](#tick-spacing-tiers)
- [Sqrt price conversion](#sqrt-price-conversion)
- [Pool coin ordering rule](#pool-coin-ordering-rule)
- [Common coin types](#common-coin-types)
- [Range selection trade-offs](#range-selection-trade-offs)

## Tick spacing tiers

| Tick spacing | Fee tier | Use case |
|---|---|---|
| 1 | 0.01% | Stablecoin pairs (USDC/USDT) |
| 2 | 0.02% | Correlated assets |
| 10 | 0.1% | Standard pairs (SUI/USDC) |
| 60 | 0.6% | Volatile pairs |
| 200 | 2% | Exotic / high-risk pairs |

## Sqrt price conversion

Sqrt price stored on-chain is `sqrt(price_B / price_A) * 2^64`.

```typescript
function priceToSqrtPrice(price: number): bigint {
  return BigInt(Math.floor(Math.sqrt(price) * 2 ** 64))
}

function sqrtPriceToPrice(sqrtPrice: bigint): number {
  return (Number(sqrtPrice) / 2 ** 64) ** 2
}
```

Example: price `2.5` → sqrt price `≈ 29189415097064819712`.

For decimals-aware conversion, prefer `TickMath.priceToSqrtPriceX64(d(price), decimalsA, decimalsB)` from `@cetusprotocol/common-sdk`.

**Full-range ticks** (derived from `tick_spacing`):

```
tick_lower_index = -443636 + (443636 % tick_spacing)
tick_upper_index =  443636 - (443636 % tick_spacing)
```

## Pool coin ordering rule

Pools derive `coin_type_a` / `coin_type_b` by lexicographic ASCII ordering of the coin type strings: the coin with the **larger** ASCII value becomes `coin_type_a`.

- Correct: `Pool<0xdba...::usdc::USDC, 0x2::sui::SUI>` (USDC > SUI lexicographically)
- Wrong: `Pool<0x2::sui::SUI, 0xdba...::usdc::USDC>`

If you build type tags by hand, sort them first or the SDK will reject the pool lookup.

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

- **Narrow range** → higher capital efficiency, more fees in-range, but higher IL and requires active rebalancing.
- **Wide / full range** → passive, lower IL, but lower fee yield per unit of capital.
- **Multiple positions** → split capital across ranges to diversify and capture fees at multiple price bands.
