# Contract reference

## Deployment provenance

Checked 2026-10-26 against the user-provided `cetus-clmm-sui/limitorder` checkout at commit `6909b262aac6b54013df8efd967d359b46512feb` and published npm SDK tarballs. The source checkout was read only; unrelated untracked audit files were not used. These are recorded/configured addresses, not an independent live-chain deployment attestation.

Source fingerprints (SHA-256):

| Source | Hash |
|---|---|
| `limitorder/sources/limit_order.move` | `3711f7b62b9679a278748fa8c64d55d3b52b0445179b3930c6fe9a8188ef4fac` |
| `limitorder/sources/config.move` | `ad49eaef852c16d34b1d0a1f3b564b668438b0cef153d61ef5df75fa6bab3869` |

Sources: local `limitorder/Published.toml`, `Move.toml`, and `sources/{limit_order,config}.move`; [limit-sdk 1.2.6 metadata](https://registry.npmjs.org/@cetusprotocol/limit-sdk/1.2.6) and its published `src/config/mainnet.ts` source map.

| Item | Snapshot |
|---|---|
| Original package / type identity | `0x533fab9a116080e2cb1c87f1832c1bf4231ab4c32318ced041e75cc28604bba9` |
| SDK call target, configured v4 | `0xd364848574d24c3413579b36ed073c38d4b6118138bbb345caf792430f94f7dd` |
| Local published-at record, v3 | `0x37d6284f2c6cdeb5663124be7e44016399b1b657bc51564d67ec480bdff15491` |
| SDK GlobalConfig | `0xd3403f23a053b52e5c4ef0c2a8be316120c435ec338f2596647b6befd569fd9c` |
| SDK global RateOrdersIndexers | `0xe7fa62b6fc095ed5659b85c735f4322059e1f4616dcf3343adece6e7eb52bf47` |
| SDK UserOrdersIndexer | `0x7f851ac19e438f97e78a5335eed4f12766a3a0ae94340bab7956a402f0e6212e` |
| Clock | `0x6` |

Local `config.move` has `VERSION = 4` while local publication metadata records v3. Treat the ABI below as a local-source snapshot; its equality to SDK-target bytecode was not verified. Prefer `limitMainnet` for SDK examples, and resolve/verify the deployment and live `package_version` before signing. Do not replace the call target with the original type package or assume the local v3 record is latest.

`checked_package_version` requires source `VERSION >= config.package_version`. Pair token whitelist enforcement follows `require_check_token_white_list`; the configured minimum amount is enforced during filling, not as a blanket opening minimum. Admin emergency-pause/ACL/config changes are outside the user-order workflow.

## Order state and discovery

`LimitOrder` stores `owner`, `rate_order_indexer_id`, pay/target balances, `total_pay_amount`, `obtained_amount`, `claimed_amount`, inverse `rate`, and millisecond `created_ts`, `expire_ts`, `canceled_ts`. Canceled sentinel is u64::MAX on-chain. `claimed_amount` is not updated by the production claim implementation.

`RateOrdersIndexers.list` indexes directional pairs to pair indexers. A pair indexer maps rates to order tables; `UserOrdersIndexer.indexer` maps owners to their order tables. Read shared objects via those indexes and events. Preserve generic type argument order; this is not CLMM's sorted coin ordering.

## Production Move signatures

`ctx` is implicit in a PTB; all other arguments below preserve source order. The blocks are declarations for reference, not standalone compilable Move modules. `Clock` is shared object `0x6`. Load keeper semantics before composing borrow/repay operations.

### `create_rate_orders_indexer`

```move
public entry fun create_rate_orders_indexer<PayCoin, TargetCoin>(
    config: &GlobalConfig,
    rate_orders_indexers: &mut RateOrdersIndexers,
    clock: &Clock,
    ctx: &mut TxContext,
);
```

### `place_limit_order`

```move
public entry fun place_limit_order<PayCoin, TargetCoin>(
    config: &GlobalConfig,
    rate_orders_indexer: &mut RateOrdersIndexer<PayCoin, TargetCoin>,
    user_orders_indexer: &mut UserOrdersIndexer,
    pay_coin: Coin<PayCoin>,
    rate: u128,
    expire_ts: u64,
    clock: &Clock,
    ctx: &mut TxContext,
);
```

### `create_indexer_and_place_limit_order`

```move
public entry fun create_indexer_and_place_limit_order<PayCoin, TargetCoin>(
    config: &GlobalConfig,
    rate_orders_indexers: &mut RateOrdersIndexers,
    user_orders_indexer: &mut UserOrdersIndexer,
    pay_coin: Coin<PayCoin>,
    rate: u128,
    expire_ts: u64,
    clock: &Clock,
    ctx: &mut TxContext,
);
```

### `cancel_order_by_owner`

```move
public fun cancel_order_by_owner<PayCoin, TargetCoin>(
    config: &GlobalConfig,
    rate_orders_indexer: &mut RateOrdersIndexer<PayCoin, TargetCoin>,
    limit_order: &mut LimitOrder<PayCoin, TargetCoin>,
    clock: &Clock,
    ctx: &mut TxContext,
);
```

### `cancel_order_by_keeper`

```move
public fun cancel_order_by_keeper<PayCoin, TargetCoin>(
    config: &GlobalConfig,
    rate_orders_indexer: &mut RateOrdersIndexer<PayCoin, TargetCoin>,
    limit_order: &mut LimitOrder<PayCoin, TargetCoin>,
    clock: &Clock,
    ctx: &mut TxContext,
);
```

### `delete_order`

```move
public fun delete_order<PayCoin, TargetCoin>(
    config: &GlobalConfig,
    order: LimitOrder<PayCoin, TargetCoin>,
    user_order_indexer: &mut UserOrdersIndexer,
    clock: &Clock,
    ctx: &TxContext,
);
```

### `flash_loan`

```move
public fun flash_loan<PayCoin, TargetCoin>(
    config: &GlobalConfig,
    limit_order: &mut LimitOrder<PayCoin, TargetCoin>,
    amount: u64,
    clock: &Clock,
    ctx: &mut TxContext,
): (Coin<PayCoin>, FlashLoanReceipt<TargetCoin>);
```

### `repay_flash_loan`

```move
public fun repay_flash_loan<PayCoin, TargetCoin>(
    config: &GlobalConfig,
    coin: &mut Coin<TargetCoin>,
    limit_order: &mut LimitOrder<PayCoin, TargetCoin>,
    receipt: FlashLoanReceipt<TargetCoin>,
    ctx: &mut TxContext,
);
```

### `claim_target_coin`

```move
public fun claim_target_coin<PayCoin, TargetCoin>(
    config: &GlobalConfig,
    limit_order: &mut LimitOrder<PayCoin, TargetCoin>,
    ctx: &mut TxContext,
);
```

### `get_orders_indexer_by_owner`

```move
public entry fun get_orders_indexer_by_owner(
    owner: address,
    user_orders_indexer: &UserOrdersIndexer,
);
```

### `get_orders_indexer_by_rate`

```move
public entry fun get_orders_indexer_by_rate<PayCoin, TargetCoin>(
    rate: u128,
    rate_orders_indexer: &RateOrdersIndexer<PayCoin, TargetCoin>,
);
```

## Module abort codes

Codes are module-local; decode against the package and module that aborted.

| Code | Constant |
|---|---|
| 0 | `EOrderPoolAlreadyExisted` |
| 1 | `ECreatePriceIndexerDuplicateCoinType` |
| 3 | `ENoLimitOrderPriceIndexes` |
| 4 | `ENoLimitUserOrderIndexes` |
| 5 | `EIncorrectFlashLoanAmount` |
| 6 | `ELimitOrderExpired` |
| 7 | `EIncorrectReceiptAmount` |
| 8 | `ELimitOrderNoCancel` |
| 9 | `ENoCancelOrderCondition` |
| 10 | `EOrderPriceIndexsAlreadyExisted` |
| 11 | `EOrderUserIndexsAlreadyExisted` |
| 12 | `ELimitOrderNotExpiredForDeletion` |
| 13 | `ENoOrderOwnerPermission` |
| 14 | `EInvalidTokenTypeOrMinTradeAmount` |
| 15 | `EInvalidFlashLoanRate` |
| 16 | `ETotalTargetAmountExceed` |
| 17 | `EReceiptOrderIdMismatch` |
| 18 | `ECreatedTimeGreaterThanExpireTime` |
| 19 | `EInsufficientBalance` |
