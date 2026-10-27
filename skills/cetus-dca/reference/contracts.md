# Contract reference

## Deployment provenance

Checked 2026-10-26 against the user-provided `cetus-clmm-sui/cetus_dca` checkout at commit `6909b262aac6b54013df8efd967d359b46512feb` and published npm SDK tarballs. The source checkout was read only; unrelated untracked audit files were not used. These are recorded/configured addresses, not an independent live-chain deployment attestation.

Source fingerprints (SHA-256):

| Source | Hash |
|---|---|
| `cetus_dca/sources/order.move` | `0766549bf12ca3cae2e228ad5907447511e99c69984bdce588389c799dfbc989` |
| `cetus_dca/sources/config.move` | `97a9f58f17b3cafc42f153c24211e38327414ed154a76650a6a6181655e52635` |

Sources: local `cetus_dca/Published.toml`, `sources/{order,config}.move`, and `Audit/mainnet-v4-source.md`; [dca-sdk 1.2.5 metadata](https://registry.npmjs.org/@cetusprotocol/dca-sdk/1.2.5) and its published mainnet configuration source map.

| Item | Snapshot |
|---|---|
| Original package / type identity | `0x587614620d0d30aed66d86ffd3ba385a661a86aa573a4d579017068f561c6d8f` |
| Local v4 published-at and SDK call target | `0xa893af5f1eb804fc4fb0dd3ca35d3d2668293f5902e1c4bd82a3bc0ffa1bd6c2` |
| SDK GlobalConfig | `0x5db218756f8486fa2ac26fab590c4be4e439be54e6d932c9a30b20573a5b706a` |
| SDK OrderIndexer | `0x713f0968d042b48f4ec57e4e21bd7e346d06355f59776faedc9497ca990a9f77` |
| SDK user-table handle | `0x0ae365f60f2fa692831f9496c9e49b2440c74f14e8eab6f88dbb418c443b5020` |
| ProtocolFeeVault | Resolve `config::InitEvent.protocol_fee_vault_id`; not supplied by SDK config |
| Clock | `0x6` |

Local publication version and source `VERSION` are 4; the SDK's `dca.version` field remains 2 despite targeting the same v4 published-at address. It is not the package gate. The local alignment report records earlier source/linkage verification, which was not rerun for this documentation change. Check live config/ACL state before execution.

`checked_package_version` requires source `VERSION >= config.package_version`. Initialization defaults (60-second minimum frequency, 2-cycle minimum, 300-second signature duration, threshold 2) are mutable config, not universal integration constants. Admin pause/role/fee-vault management is outside the user-order workflow.

## Order state and discovery

`Order` stores `user`, deposit/withdrawal accounting, `in_balance`, `out_balance`, `cycle_frequency`, `in_amount_per_cycle`, `amount_left_next_cycle`, `next_cycle_at`, output bounds, fee rate, status and `created_at`. Times are seconds. Status: 0 pending, 1 finished, 2 canceled.

`OrderIndexer.open_orders` holds active order IDs. `user_orders` maps users to ID/bool tables; the boolean is set false for completed/canceled orders. Objects remain shared and historical records can still be read. Most source getters after the test section are `#[test_only]`; use object JSON/indexers instead of inventing production Move getter calls.

## Production Move signatures

`ctx` is implicit in a PTB; all other arguments below preserve source order. The blocks are declarations for reference, not standalone compilable Move modules. `Clock` is shared object `0x6`. Load keeper semantics before composing borrow/repay operations.

### `open_order`

```move
public fun open_order<InCoin, OutCoin>(
    config: &GlobalConfig,
    in_coin: Coin<InCoin>,
    cycle_frequency: u64,
    cycle_count: u64,
    min_out_amount_per_cycle: u64,
    max_out_amount_per_cycle: u64,
    in_amount_limit_per_cycle: u64,
    fee_rate: u64,
    timestamp: u64,
    signature: String,
    clk: &Clock,
    indexer: &mut OrderIndexer,
    ctx: &mut TxContext
);
```

### `flash_loan_for_make_deal_v2`

```move
public fun flash_loan_for_make_deal_v2<InCoin, OutCoin>(
    config: &GlobalConfig,
    fee_vault: &mut ProtocolFeeVault,
    order: &mut Order<InCoin, OutCoin>,
    promise_out_amount:  u64,
    timestamp: u64,
    signatures: vector<String>,
    clk: &Clock,
    ctx: &mut TxContext,
): (Coin<InCoin>, MakeDealReceipt);
```

### `repay_for_make_deal`

```move
public fun repay_for_make_deal<InCoin, OutCoin>(
    config: &GlobalConfig,
    order: &mut Order<InCoin, OutCoin>,
    indexer: &mut OrderIndexer,
    out_coin: Coin<OutCoin>,
    receipt: MakeDealReceipt,
    clk: &Clock,
    ctx: &mut TxContext
);
```

### `withdraw`

```move
public fun withdraw<InCoin, OutCoin>(
    config: &GlobalConfig,
    order: &mut Order<InCoin, OutCoin>,
    clk: &Clock,
    ctx: &mut TxContext
): Coin<OutCoin>;
```

### `cancel_order`

```move
public fun cancel_order<InCoin, OutCoin>(
    config: &GlobalConfig,
    order: &mut Order<InCoin, OutCoin>,
    indexer: &mut OrderIndexer,
    clk: &Clock,
    ctx: &mut TxContext
): (Coin<InCoin>, Coin<OutCoin>);
```

## Module abort codes

Codes are module-local; decode against the package and module that aborted.

| Code | Constant |
|---|---|
| 0 | `ECycleCountLimit` |
| 1 | `ECycleFrequencyLimit` |
| 2 | `EOrderCycleAmountLeftIsZero` |
| 3 | `ENotYetTimeForMakeDeal` |
| 4 | `EOutAmountLtMinLimit` |
| 5 | `EOutAmountGtMaxLimit` |
| 6 | `EOutAmountLtPromise` |
| 7 | `EPerCycleMinInAmountLimit` |
| 8 | `EInvalidOrderId` |
| 9 | `EIsNotOrderOwner` |
| 10 | `ESchemeNotSupport` |
| 11 | `EOracleSignatureExpired` |
| 12 | `EInvalidOracleSignature` |
| 13 | `EOrderNotPending` |
| 14 | `EKeeperValidate` |
| 15 | `ETradePairUnSupported` |
| 16 | `EOutAmountLimitRange` |
| 17 | `EDeprecatedUsage` |
| 18 | `EInvalidFeeRate` |
| 19 | `EInvalidOrderFrequency` |
| 20 | `ESameCoinType` |
| 21 | `EInvalidAmountIn` |
| 22 | `EInvalidSignatureLength` |
| 24 | `ETotalOutAmountOverflow` |

Legacy `flash_loan_for_make_deal` and `cancle_order` always abort with `EDeprecatedUsage` (17). Code 23 is test-only and is not a production withdraw precondition.
