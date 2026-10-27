# Limit-order keeper and filler integration

This is an advanced atomic settlement path, not the CLMM flash-loan API. Exact production function signatures and error codes are in [contracts](contracts.md).

## Preconditions

Read `GlobalConfig`, the directional pair indexer, and the order immediately before building. Confirm the package gate, token policy, nonzero remaining pay, `canceled_ts` sentinel, expiry, and intended fill amount. The fill must be positive, fit the remaining balance, and satisfy the configured pay-token minimum when whitelist checking is enabled.

`flash_loan` and `repay_flash_loan` check the keeper ACL **only when `require_flash_loan_auth` is true**. Do not describe this as always permissionless or always keeper-only. Keeper cancellation and deletion always check the keeper role. Pair token whitelist checks and minimum fill checks are separate: opening checks the configured pair policy, while the borrow path calls `check_token_and_min_trade_amount` for the pay coin.

## Atomic fill

In a single PTB:

1. Call `limit_order::flash_loan<PayCoin, TargetCoin>(config, order, amount, clock)`. It returns a `Coin<PayCoin>` and a non-droppable `FlashLoanReceipt<TargetCoin>`.
2. Route that pay coin through a real swap integration to produce the target coin. Use actual route liquidity and transaction composition; this skill supplies no router service or filler infrastructure.
3. Call `limit_order::repay_flash_loan<PayCoin, TargetCoin>(config, &mut target_coin, order, receipt)`. It splits the required repayment from the target coin and retains it in the order. The receipt is consumed in this same transaction.
4. Transfer or otherwise consume any residual target coin and every other returned object. When the pay balance reaches zero, repayment automatically pays the order's accumulated target balance to its owner.

Per-fill nominal repayment is `ceil(amount × 10^18 / rate)`. The contract caps cumulative obtained amount at `ceil(total_pay_amount × 10^18 / rate)`, so later fills can owe less than the nominal ceil calculation. Receipt fields are module-private with no production getter; do not assume a JS receipt object can be inspected before execution. Route enough target for the receipt, then let repayment split the exact obligation. Surplus remains in the mutable coin supplied by the filler; this contract does not automatically gift all execution surplus to the order owner.

Do not leave a flash-loan receipt between transactions or substitute a fabricated receipt. Atomic repayment failure reverts the whole PTB. There is no protocol fee argument in this limit-order fill interface; do not import DCA/CLMM fee formulas.

## Cancellation and cleanup

- `cancel_order_by_keeper`: remaining pay is zero **or** chain time is strictly greater than expiry. Merely being a keeper does not allow arbitrary early cancellation of a funded unexpired order. Owner cancellation has its own owner check.
- `cancel_order` is internal. Use the public owner/keeper variants. It removes the rate index and stamps cancellation time; it does not remove the user index or destroy the shared object.
- `delete_order`: keeper-only, canceled order, and `clock_ms > canceled_ts + deletion_grace_period`; consumes the order, removes its user index, and destroys zero balances. Check the current grace period instead of hardcoding one.
- Query helpers `get_orders_indexer_by_owner` and `get_orders_indexer_by_rate` emit table IDs in events; they do not return a list of orders. Iterate dynamic fields and follow pagination to read the indexed shared objects.

Monitor `FlashLoanEvent`, `RepayFlashLoanEvent`, `OrderCanceledEvent`, and `ClaimTargetCoinEvent` together with current object balances. A full fill can be completed financially before keeper cancellation/deletion removes its indexes.
