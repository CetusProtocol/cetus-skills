# CLMM — Flash Loan

SDK and Move examples for borrowing from a CLMM pool and repaying within the same transaction.
Parameter tables are in [SKILL.md](../SKILL.md).

> **Flash loan is CLMM-only.** The DLMM protocol has **no** `flash_loan` — it only exposes a
> swap-specific `flash_swap` at the Move level. Do not look for a DLMM flash loan.

A flash loan lets you borrow either coin of a pool (no collateral) on the condition that you repay
the principal **plus a fee** before the transaction ends. The obligation is enforced by a
`FlashLoanReceipt` hot-potato struct: it has no `drop` ability, so the transaction cannot succeed
unless a matching `repay_flash_loan` consumes it.

## Contents

- [flash_loan / repay_flash_loan (Move)](#flash_loan--repay_flash_loan-move)
- [TypeScript (PTB / raw moveCall)](#typescript-ptb--raw-movecall)
- [Partner variants](#partner-variants)
- [Fees & safety](#fees--safety)

## flash_loan / repay_flash_loan (Move)

```move
// Borrow `amount` of coin A (loan_a = true) or coin B (loan_a = false).
public fun flash_loan<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    loan_a: bool,
    amount: u64,
): (Balance<CoinTypeA>, Balance<CoinTypeB>, FlashLoanReceipt);

// Repay principal + fee. Consumes (destroys) the receipt.
public fun repay_flash_loan<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    balance_a: Balance<CoinTypeA>,
    balance_b: Balance<CoinTypeB>,
    receipt: FlashLoanReceipt,
);
```

The hot-potato receipt (no `drop` — must be repaid in the same tx):

```move
public struct FlashLoanReceipt {
    pool_id: ID,
    loan_a: bool,
    partner_id: ID,
    amount: u64,       // principal borrowed
    fee_amount: u64,   // fee owed on top of principal
    ref_fee_amount: u64,
}
```

Borrow → use → repay skeleton (single atomic transaction):

```move
// 1) Borrow `amount` of coin A from the pool.
let (balance_a, balance_b, receipt) =
    pool::flash_loan<CoinTypeA, CoinTypeB>(config, pool, true /* loan_a */, amount);

// 2) ... use balance_a here (arbitrage, liquidation, etc.) ...
//    The unused side (balance_b) is a zero balance and is destroyed during repay.

// 3) Repay principal + fee. The coin-A balance handed back must equal amount + fee_amount.
pool::repay_flash_loan<CoinTypeA, CoinTypeB>(config, pool, repay_balance_a, balance_b, receipt);
```

**`FlashLoanReceipt` exposes no public accessor** — its fields are module-private and are only
destructured inside `repay_flash_loan`. You cannot read `fee_amount` off the receipt at runtime;
compute it yourself from the principal and the pool fee rate (see [Fees & safety](#fees--safety))
before assembling repayment. Repayment on the borrowed side must equal `amount + fee_amount`
**exactly**.

> The `swap_pay_amount(...)` / `ref_fee_amount(...)` getters in `pool.move` are for
> `FlashSwapReceipt`, **not** `FlashLoanReceipt` — they do not apply to a flash-loan receipt.

## TypeScript (PTB / raw moveCall)

The core CLMM SDK (`@cetusprotocol/sui-clmm-sdk`) exposes **no** flash-loan builder, so build the
borrow/repay calls directly as a Programmable Transaction Block. The `FlashLoanReceipt` flows
between the two `moveCall`s as a transaction result and is never owned off-chain.

```typescript
import { Transaction } from '@mysten/sui/transactions'

import { clmmMainnet } from '@cetusprotocol/sui-clmm-sdk'

const CLMM_PACKAGE = clmmMainnet.clmm_pool.published_at
const GLOBAL_CONFIG = '0xdaa46292632c3c4d8f31f23ea0f9b36a28ff3677e9684980e4438403a67a3d8f'

const coinTypeA = '0x2::sui::SUI'
const coinTypeB = '0x...::usdc::USDC'
const loanA = true            // borrow coin A
const amount = '1000000000'   // 1 SUI (smallest unit)

const tx = new Transaction()

// 1) Borrow → returns [balance_a, balance_b, receipt]
const [balanceA, balanceB, receipt] = tx.moveCall({
  target: `${CLMM_PACKAGE}::pool::flash_loan`,
  arguments: [tx.object(GLOBAL_CONFIG), tx.object(poolId), tx.pure.bool(loanA), tx.pure.u64(amount)],
  typeArguments: [coinTypeA, coinTypeB],
})

// 2) ... arbitrage leg: route `balanceA` through other pools/DEXs so it comes back as MORE
//    coin A. Repay `amount + fee_amount`; whatever is left over is your profit.

// 3) Repay → consumes the receipt. Pass the borrowed side filled, the other side as the
//    untouched zero balance returned by flash_loan.
tx.moveCall({
  target: `${CLMM_PACKAGE}::pool::repay_flash_loan`,
  arguments: [tx.object(GLOBAL_CONFIG), tx.object(poolId), repayBalanceA, balanceB, receipt],
  typeArguments: [coinTypeA, coinTypeB],
})
```

`flash_loan` returns Move `Balance` values, not `Coin`. Keep them inside the PTB (split/join via
`pool`/`balance` helpers or wrap into a `Coin` as your logic needs); the unused side is a zero
balance that `repay_flash_loan` destroys.

## Partner variants

`flash_loan_with_partner` / `repay_flash_loan_with_partner` route a referral-fee share to a
`Partner` object (the same partner mechanism as `swap_a2b_with_partner`):

```move
public fun flash_loan_with_partner<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    partner: &Partner,
    loan_a: bool,
    amount: u64,
    clock: &Clock,
): (Balance<CoinTypeA>, Balance<CoinTypeB>, FlashLoanReceipt);

public fun repay_flash_loan_with_partner<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    partner: &mut Partner,
    balance_a: Balance<CoinTypeA>,
    balance_b: Balance<CoinTypeB>,
    receipt: FlashLoanReceipt,
);
```

Use the partner repay with a partner loan and the plain repay with a plain loan — they are not
interchangeable: plain `repay_flash_loan` asserts `ref_fee_amount == 0`, and the partner repay
asserts the receipt's `partner_id` matches the passed `Partner`.

## Fees & safety

### Fee formula (verified against `flash_loan_internal` in `pool.move`)

The fee is charged on the **borrowed principal** using the pool's own fee rate — the same
`pool.fee_rate` field that swaps use (i.e. the pool's fee tier), **not** a separate flash-loan rate:

```
fee_amount = ceil(amount * pool.fee_rate / 1_000_000)   // FEE_RATE_DENOMINATOR = 1e6, rounded UP
total_repay = amount + fee_amount                        // on the borrowed coin only
```

Compute this yourself: you know `amount`, and you read `pool.fee_rate` from the fetched pool
(e.g. `const pool = await sdk.Pool.getPool(poolId); pool.fee_rate`). Example: `fee_rate = 2500`
→ 0.25%; borrowing `1_000_000_000` costs `2_500_000` in fee, repay `1_002_500_000`.

The internal split of `fee_amount` (protocol fee → `protocol_fee_rate / 10_000`; remainder → LPs via
fee growth; partner ref fee carved from the protocol portion) is pool/LP accounting and **does not
change what the borrower repays** — the borrower always owes exactly `amount + fee_amount`.

### Safety

| Behavior | Detail |
|---|---|
| Exact repayment | Repaid balance on the borrowed side must equal `amount + fee_amount` exactly, else `EAmountIncorrect`. The other side must be passed as a zero balance. |
| Atomic enforcement | `FlashLoanReceipt` has no `drop`; if it isn't consumed by a matching repay, the tx aborts and the borrow reverts. |
| Pool gating | Disabled when the pool's `disable_flash_loan` status is set — `flash_loan` asserts `is_allow_flash_loan(pool)` (`EOperationNotPermitted`). |
| Receipt match | Repay asserts `receipt.pool_id == pool`; plain `repay_flash_loan` also asserts `ref_fee_amount == 0`, and the partner repay asserts `partner_id` matches — else `EFlashLoanReceiptNotMatch` (code 20). |
