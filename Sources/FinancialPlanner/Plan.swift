import FinanceCore
import Foundation

struct InvestingInputs: Codable, Hashable {
    var monthlyContribution: Double
    var years: Int
    /// When true, the growth projection uses the portfolio's blended return.
    var useBlendedReturn: Bool
    var customReturn: Double
}

struct DebtInputs: Codable, Hashable {
    var debts: [Debt]
    var monthlyBudget: Double
    var strategy: PayoffStrategy
}

/// Everything the user has entered. Saved as JSON on disk.
struct Plan: Codable, Hashable {
    var holdings: [Holding]
    var investing: InvestingInputs
    var retirement: RetirementInputs
    var debt: DebtInputs

    static let sample = Plan(
        holdings: [
            Holding(name: "Total market index fund", assetClass: .usStocks, value: 85_000),
            Holding(name: "International index fund", assetClass: .internationalStocks, value: 25_000),
            Holding(name: "Bond fund", assetClass: .bonds, value: 30_000),
            Holding(name: "High-yield savings", assetClass: .cash, value: 15_000),
        ],
        investing: InvestingInputs(monthlyContribution: 1_000, years: 20, useBlendedReturn: true, customReturn: 0.07),
        retirement: RetirementInputs(
            currentAge: 45, retirementAge: 65, lifeExpectancy: 92,
            currentSavings: 155_000, monthlyContribution: 1_000,
            preRetirementReturn: 0.07, postRetirementReturn: 0.05, inflation: 0.03,
            annualSpending: 70_000, otherAnnualIncome: 28_000
        ),
        debt: DebtInputs(
            debts: [
                Debt(name: "Credit card", balance: 6_500, apr: 0.229, minimumPayment: 150),
                Debt(name: "Car loan", balance: 14_000, apr: 0.069, minimumPayment: 350),
                Debt(name: "Student loan", balance: 22_000, apr: 0.045, minimumPayment: 240),
            ],
            monthlyBudget: 1_100,
            strategy: .avalanche
        )
    )
}
