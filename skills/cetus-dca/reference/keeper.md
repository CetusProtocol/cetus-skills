# DCA keeper execution and signatures

Use production `order.move`, not its test helpers. Test helpers differ materially in fee denomination and timestamp handling. Exact entrypoint argument order appears in [contracts](contracts.md).

## Oracle opening authorization

`open_order` needs an authorized oracle's Ed25519 signature over this concatenation, with **no Sui personal-message prefix or transaction intent**:

| Order | Encoding |
|---|---|
| 1 | UTF-8 bytes of `type_name::get<InCoin>().into_string()`; no BCS length prefix |
| 2 | Sender address, exactly 32 raw bytes |
| 3 | `cycle_frequency`, BCS u64 little-endian |
| 4 | `cycle_count`, BCS u64 little-endian |
| 5 | `fee_rate`, BCS u64 little-endian |
| 6 | `in_amount_limit_per_cycle`, BCS u64 little-endian |
| 7 | `timestamp`, BCS u64 little-endian, Unix seconds |

The payload does not include output coin type, total deposit, or output bounds; do not add fields and expect the contract to verify them. Use the exact Move type-name representation for the deployed coin, not a display ticker or a casually shortened address. The contract separately checks the chosen pair, deposit, and bounds.

The signature parameter is a **hex string** encoding 97 bytes: `0x00` scheme byte, 64-byte Ed25519 signature, 32-byte public key. It is not the wallet's base64 transaction signature. Address authorization uses `blake2b256(0x00 || public_key)` and the config's oracle ACL. The oracle's public authorization does not provide its private signing capability.

Opening accepts `abs(chain_now_seconds - timestamp) <= oracle_valid_duration` (including a small future timestamp). Fetch fresh service authorization matching the actual sender and signed parameters. Never generate a test signature or reuse an example key for a production order.

## Keeper threshold authorization

Only `flash_loan_for_make_deal_v2` is supported. The sender must itself hold the keeper role, and the signatures must include at least `keeper_threshold` distinct authorized keeper addresses. Count distinct verified signers, not vector length. Read the threshold from config.

Keeper signed bytes concatenate:

| Order | Encoding |
|---|---|
| 1 | `object::id_bytes(order)`, raw 32-byte ID |
| 2 | BCS `TypeName` for `InCoin` (includes BCS string length) |
| 3 | BCS `TypeName` for `OutCoin` |
| 4 | `order.next_cycle_at`, BCS u64 |
| 5 | `order.amount_left_next_cycle`, BCS u64 |
| 6 | `promise_out_amount`, BCS u64 |
| 7 | `timestamp`, BCS u64, Unix seconds |

Signatures use the same hex-encoded 97-byte envelope as the oracle. Keeper freshness requires `timestamp <= chain_now_seconds` and `chain_now_seconds - timestamp <= oracle_valid_duration`, unlike the symmetric opening window. Refresh state and signatures after any cycle changes; changing signed amount, order, pair or next-cycle state invalidates them. The SDK offers no keeper-signing service or high-level keeper execution builder.

## Atomic borrow, swap and repay

Preflight status 0, positive `amount_left_next_cycle`, sufficient input balance, due time, supported package gate, sender ACL, fresh threshold signatures, and promised output within the configured min/max bounds.

In one PTB call `flash_loan_for_make_deal_v2(config, fee_vault, order, promise_out_amount, timestamp, signatures, clock)`. It returns `Coin<InCoin>` and a `MakeDealReceipt`. The fee vault is a shared `ProtocolFeeVault`, discovered from the deployment's `config::InitEvent.protocol_fee_vault_id` or verified deployment records; it is not the admin cap and is not included in the SDK's DCA config interface.

For gross cycle input `g` and fee rate `f`, the fee is `floor(g × f / 1000000)` **in InCoin**; only `g - fee` is returned for routing. Quote the net input, not the gross amount. Route the returned input coin through a real swap integration, then pass the resulting output coin and receipt to `repay_for_make_deal(config, order, indexer, out_coin, receipt, clock)` in the same PTB. Repayment requires:

```
out_coin.value >= promise_out_amount
min_out_amount_per_cycle <= out_coin.value <= max_out_amount_per_cycle
receipt.order_id == order.id
order.status == 0
```

The entire supplied output coin enters the order. If routing returns more than the upper bound, split an appropriate coin and handle the surplus explicitly according to the authorized execution policy; do not simply omit the upper-bound check. Handle every returned coin and consume the receipt atomically.

After borrowing, the next scheduled gross input equals the normal per-cycle input when the remaining deposit is at least twice that amount; otherwise it becomes the entire remaining deposit. That final cycle can therefore be larger than the normal amount. Bounds and fees must be evaluated against the actual cycle. `next_cycle_at` becomes actual execution time + frequency, or 0 if no input remains. Repayment of the final cycle sets status 1 and transfers accumulated output to the order owner.

Observe `MakeDealEvent` for gross input, fee, actual output, promised output, resulting balances and execution time. Output withdrawal and cancellation have separate events. No keeper process, timer, retry service, or authorization backend is deployed by installing this skill.
