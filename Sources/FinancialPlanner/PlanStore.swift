import FinanceCore
import Foundation
import Observation

/// Holds the user's plan, saves it to disk on every change, and exposes
/// derived results for the views.
@MainActor
@Observable
final class PlanStore {
    var plan: Plan {
        didSet { save() }
    }

    private let fileURL: URL

    init(fileURL: URL = PlanStore.defaultFileURL) {
        self.fileURL = fileURL
        if let data = try? Data(contentsOf: fileURL),
           let saved = try? JSONDecoder().decode(Plan.self, from: data) {
            plan = saved
        } else {
            plan = .sample
        }
    }

    nonisolated static var defaultFileURL: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return support.appendingPathComponent("FinancialPlanner", isDirectory: true)
            .appendingPathComponent("plan.json")
    }

    private func save() {
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(),
                                                    withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(plan).write(to: fileURL, options: .atomic)
        } catch {
            print("Could not save plan: \(error)")
        }
    }

    func resetToSample() { plan = .sample }

    // MARK: Derived values

    var investmentsTotal: Double { Portfolio.total(plan.holdings) }
    var debtTotal: Double { plan.debt.debts.reduce(0) { $0 + max(0, $1.balance) } }
    var netWorth: Double { investmentsTotal - debtTotal }

    var blendedReturn: Double { Portfolio.blendedReturn(plan.holdings) }

    var growthReturn: Double {
        plan.investing.useBlendedReturn ? blendedReturn : plan.investing.customReturn
    }

    var growthProjection: [GrowthPoint] {
        Growth.project(initial: investmentsTotal,
                       monthlyContribution: plan.investing.monthlyContribution,
                       annualReturn: growthReturn,
                       years: plan.investing.years)
    }

    var retirementProjection: RetirementProjection {
        RetirementPlanner.project(plan.retirement)
    }

    func payoff(_ strategy: PayoffStrategy) -> PayoffResult {
        DebtPlanner.simulate(debts: plan.debt.debts, monthlyBudget: plan.debt.monthlyBudget, strategy: strategy)
    }

    var chosenPayoff: PayoffResult { payoff(plan.debt.strategy) }
}
