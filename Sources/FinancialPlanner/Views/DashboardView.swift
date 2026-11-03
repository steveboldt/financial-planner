import Charts
import FinanceCore
import SwiftUI

struct DashboardView: View {
    @Environment(PlanStore.self) private var store
    @Binding var selection: Screen?

    var body: some View {
        let retirement = store.retirementProjection
        let payoff = store.chosenPayoff

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: 12)], spacing: 12) {
                    StatCard(title: "Net worth", value: store.netWorth.currency,
                             detail: "\(store.investmentsTotal.currency) invested, \(store.debtTotal.currency) owed")
                    StatCard(title: "Expected portfolio return", value: store.blendedReturn.percent,
                             detail: "Blended across your holdings")
                    StatCard(title: "Debt-free",
                             value: payoff.monthsToDebtFree.map { $0.monthsFromNow } ?? "Not with this budget",
                             detail: payoff.monthsToDebtFree.map { "\($0.monthsDescription) · \(payoff.totalInterest.currency) interest" },
                             tint: payoff.isPaidOff ? .primary : .red)
                    StatCard(title: "Retirement",
                             value: retirement.lastsThroughLifeExpectancy
                                ? "On track"
                                : "Runs out at \(retirement.depletionAge ?? 0)",
                             detail: "\(retirement.realBalanceAtRetirement.currency) at \(store.plan.retirement.retirementAge) in today's dollars",
                             tint: retirement.lastsThroughLifeExpectancy ? .green : .orange)
                }

                HStack(alignment: .top, spacing: 16) {
                    chartCard("Retirement savings (today's dollars)", screen: .retirement) {
                        Chart(retirement.years) { year in
                            AreaMark(x: .value("Age", year.age), y: .value("Balance", year.realBalance))
                                .foregroundStyle(.blue.opacity(0.25))
                            LineMark(x: .value("Age", year.age), y: .value("Balance", year.realBalance))
                        }
                        .chartYAxis { currencyAxis() }
                    }
                    chartCard("Debt remaining", screen: .debt) {
                        Chart(payoff.months) { month in
                            AreaMark(x: .value("Month", month.month), y: .value("Balance", month.totalBalance))
                                .foregroundStyle(.red.opacity(0.25))
                            LineMark(x: .value("Month", month.month), y: .value("Balance", month.totalBalance))
                                .foregroundStyle(.red)
                        }
                        .chartYAxis { currencyAxis() }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Dashboard")
    }

    private func chartCard<C: View>(_ title: String, screen: Screen, @ViewBuilder chart: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                Button("Details") { selection = screen }
                    .buttonStyle(.link)
            }
            chart().frame(height: 200)
        }
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
    }
}
