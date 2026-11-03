# Financial Planner

A personal macOS app for planning investing, retirement and debt payoff. Built with SwiftUI and Swift Charts. Everything you enter stays on your Mac.

## What's in it

- **Dashboard**: net worth, expected portfolio return, debt-free date and whether retirement savings last, with quick charts.
- **Investing**: list your holdings, see your allocation by asset class and a blended expected return, and project growth with monthly contributions.
- **Retirement**: set your ages, savings, spending and assumptions with sliders, and see your balance year by year in today's dollars, plus the age your money runs out (if it does).
- **Debt**: list your debts and a monthly budget, compare avalanche and snowball payoff side by side, and see each debt's payoff date and the total interest.

Your plan is saved automatically to `~/Library/Application Support/FinancialPlanner/plan.json`. The first launch starts with sample numbers you can overwrite.

## Requirements

- macOS 14 (Sonoma) or later
- Xcode 15 or later (Xcode 16 recommended)

## Run it

In Xcode: open the folder (or `Package.swift`), choose the **FinancialPlanner** scheme and **My Mac**, then press ⌘R.

From Terminal:

```sh
swift run FinancialPlanner
```

Run the tests with `swift test` or ⌘U in Xcode.

## Project layout

```
Sources/FinanceCore/        Calculation engine (no UI): growth, portfolio, retirement, debt payoff
Sources/FinancialPlanner/   SwiftUI app: data store, screens, shared controls
Tests/FinanceCoreTests/     Unit tests for the engine
```

The math lives in `FinanceCore` so it can be tested on its own and reused as the app grows.

## Notes

The projections use steady average returns and simple yearly or monthly steps. They're for planning direction, not financial advice. Return assumptions per asset class are placeholders in `Portfolio.swift`.

## Ideas for next steps

- Research: pull live quotes and fund data, and summarize news or filings for holdings
- Monte Carlo retirement simulation with success rates
- Editable return assumptions and multiple saved scenarios
- Import holdings and balances from CSV
