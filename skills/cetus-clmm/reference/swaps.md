# CLMM — Swap Operations

SDK and Move examples for single-pool swaps. Parameter tables are in [SKILL.md](../SKILL.md).

## Contents

- [swap_a2b](#swap_a2b)
- [Slippage protection semantics](#slippage-protection-semantics)
- [swap_a2b_with_partner](#swap_a2b_with_partner)
- [Flash swap mechanism](#flash-swap-mechanism)

## swap_a2b

```typescript
import BN from 'bn.js'
import { adjustForSlippage, d, Percentage } from '@cetusprotocol/common-sdk'

const pool = await sdk.Pool.getPool(poolAddress)

const a2b = true
const by_amount_in = true
const amount = new BN(1000000000) // 1 SUI
const slippage = Percentage.fromDecimal(d(0.02)) // 2%

// 1) Quote
const res = await sdk.Swap.preSwap({
  pool,
  current_sqrt_price: pool.current_sqrt_price,
  coin_type_a: pool.coin_type_a,
  coin_type_b: pool.coin_type_b,
  decimals_a: 9,
  decimals_b: 6,
  a2b,
  by_amount_in,
  amount: amount.toString(),
})

// 2) Slippage-adjusted limit
const toAmount = by_amount_in ? res.estimated_amount_out : res.estimated_amount_in
const amountLimit = adjustForSlippage(toAmount, slippage, !by_amount_in)

// 3) Build and execute
const swap_payload = sdk.Swap.createSwapPayload({
  pool_id: pool.id,
  coin_type_a: pool.coin_type_a,
  coin_type_b: pool.coin_type_b,
  a2b,
  by_amount_in,
  amount: res.amount.toString(),
  amount_limit: amountLimit.toString(),
})

const txn = await sdk.FullClient.sendTransaction(signer, swap_payload)
```

**Move (`cetus_integrate::pool_script`)**:

```move
pool_script::swap_a2b<SUI, USDC>(
    config, pool,
    coins_a,
    true,           // by_amount_in (fix input)
    1000000000,     // amount (1 SUI)
    2450000,        // amount_limit (min 2.45 USDC, 2% slippage)
    0,              // sqrt_price_limit (0 = no limit)
    clock, ctx,
);
```

`swap_b2a` mirrors this with `coins_b` and reversed direction.

## Slippage protection semantics

| `by_amount_in` | `amount` is | `amount_limit` is | Slippage formula |
|---|---|---|---|
| `true` (fix input) | exact input | minimum output | `expected_out * (1 - slippage)` |
| `false` (fix output) | exact output | maximum input | `expected_in * (1 + slippage)` |

`sqrt_price_limit` of `0` means no boundary; set a non-zero value to halt the swap if price crosses it.

## swap_a2b_with_partner

Identical to `swap_a2b` but routes the partner fee share to a `Partner` object.

**Move (`cetus_integrate::pool_script`)**:

```move
pool_script::swap_a2b_with_partner<SUI, USDC>(
    config, pool, partner,
    coins_a,
    true, 1000000000, 2450000, 0,
    clock, ctx,
);
```

Partner fees accumulate on the Partner object and are collected separately.

## Flash swap mechanism

CLMM swaps use a borrow-then-repay pattern internally:

1. Pool lends output coins to the caller.
2. Caller repays with input coins (auto-handled by `swap_*`).
3. Transaction reverts atomically if repayment is insufficient.

This enables zero-capital atomic routing and powers multi-hop aggregators.
