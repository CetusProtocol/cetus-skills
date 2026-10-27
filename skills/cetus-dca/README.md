# Cetus DCA Skill

Create recurring token-purchase orders on Sui, read their schedules and balances, withdraw accrued output, and cancel pending orders. Keeper references cover production signatures and atomic execution against the user-provided Cetus DCA contract.

Install the skill from this repository:

```bash
npx skills add CetusProtocol/cetus-skills --skill cetus-dca
```

Install runtime dependencies for TypeScript examples:

```bash
npm install @cetusprotocol/dca-sdk@1.2.5 @cetusprotocol/common-sdk@1.4.3 @mysten/sui@2.31.2
```

Example requests:

- “Build a Cetus DCA order spending 100 USDC across 10 daily purchases of SUI.”
- “Show my DCA orders, next execution times, and accrued output.”
- “Cancel this pending DCA order and refund the remaining balances.”

Opening authorization comes from the official GET `https://api-sui.cetus.zone/dca/quote` endpoint with `in_coin`, `freq`, `count`, and `sender`. The [opening example](reference/orders.md#open-an-order) maps its signed response into SDK parameters; keeper threshold signing is a separate integration. Schedule times are Unix seconds, fees are charged in the input coin, and the first cycle is eligible immediately. Execution depends on authorized keepers and liquidity. Installing a skill does not start a keeper service.

Start with [SKILL.md](SKILL.md), then load [user operations](reference/orders.md), [keeper and signature format](reference/keeper.md), or [contract signatures and deployment provenance](reference/contracts.md). The SDK's close-order builder calls cancellation, and deprecated `cancle_order` / legacy keeper borrow functions must not be used.
