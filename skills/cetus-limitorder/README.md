# Cetus Limit Order Skill

Place target-price orders on Sui, inspect fills, claim accrued proceeds, and cancel orders with the Cetus limit-order SDK. Advanced references cover keeper settlement and cleanup using the Move interface.

Install the skill from this repository:

```bash
npx skills add CetusProtocol/cetus-skills --skill cetus-limitorder
```

Install runtime dependencies for TypeScript examples:

```bash
npm install @cetusprotocol/limit-sdk@1.2.6 @cetusprotocol/common-sdk@1.4.3 @mysten/sui@2.31.2 blakejs
```

Example requests:

- “Place a Cetus limit order selling 1 SUI for at least 2.5 USDC, expiring tomorrow.”
- “Show my partially filled Cetus limit orders and claim the available proceeds.”
- “Build a cancellation transaction for this limit order.”

Price is human **target per pay**, while the contract uses an inverse rate scaled by 10^18 and adjusted for coin decimals. Expiry is Unix milliseconds. Orders are shared objects; filling, claiming, cancellation, and keeper deletion are separate operations. Builders return unsigned transactions; wallet signing is a separate action.

Start with [SKILL.md](SKILL.md), then load [user operations](reference/orders.md), [keeper integration](reference/keeper.md), or [contract signatures and deployment provenance](reference/contracts.md) as needed. The local contract publication record and current SDK call target differ; the provenance reference explains the boundary.
