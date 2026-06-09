# DLMM — Swap Operations

SDK and Move examples for single-pool swaps via the router. Parameter tables are in [SKILL.md](../SKILL.md).

## Contents

- [swap_a2b (router)](#swap_a2b-router)
- [Slippage protection semantics](#slippage-protection-semantics)
- [Flash swap (advanced)](#flash-swap-advanced)

## swap_a2b (router)

```typescript
import { Percentage, d } from '@cetusprotocol/common-sdk'

const pool = await sdk.Pool.getPool(poolAddress)

const slippage = Percentage.fromDecimal(d(0.01)) // 1%

// 1) Quote
const quote = await sdk.Swap.preSwapQuote({
  pool_id: pool.id,
  coin_type_a: pool.coin_type_a,
  coin_type_b: pool.coin_type_b,
  a2b: true,
  by_amount_in: true,
  in_amount: '1000000000', // 1 SUI
})

// 2) Build and execute
const swap_payload = sdk.Swap.swapPayload({
  quote_obj: quote,
  coin_type_a: pool.coin_type_a,
  coin_type_b: pool.coin_type_b,
  by_amount_in: true,
  slippage,
})

const txn = await sdk.FullClient.sendTransaction(signer, swap_payload)
```

**Move (`dlmmrouter::swap`)**:

```move
swap::swap_a2b<SUI, USDC>(
    pool, coin_a,
    true,           // by_amount_in (fix input)
    1000000000,     // amount (1 SUI)
    2475000,        // amount_limit (min 2.475 USDC, 1% slippage)
    config, versioned, clock, ctx,
);
```

`swap_b2a` mirrors this with `coin_b` and the reversed direction. Partner variants (`swap_a2b_with_partner`, `swap_b2a_with_partner`) take an additional `&mut Partner` argument and route the fee share to the partner object.

## Slippage protection semantics

| `by_amount_in` | `amount` is | `amount_limit` is |
|---|---|---|
| `true` (fix input) | exact input | minimum output |
| `false` (fix output) | exact output | maximum input |

The on-chain transaction reverts when the realized swap result violates `amount_limit`.

## Flash swap (advanced)

For custom routing logic, call `pool::flash_swap` + `pool::repay_flash_swap` directly instead of the router. The router wraps this borrow/repay loan for you in the standard `swap_a2b` / `swap_b2a` paths.
