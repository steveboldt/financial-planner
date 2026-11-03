import Charts
import FinanceCore
import SwiftUI

struct DebtView: View {
    @Environment(PlanStore.self) private var store

    private struct StrategyPoint: Identifiable {
        let strategy: String
        let month: Int
        let balance: Double
        var id: String { "\(strategy)-\(month)" }
    }

    var body: some View {
        @Bindable var store = store
        let minimums = DebtPlanner.minimumPaymentsTotal(store.plan.debt.debts)
        let results = Dictionary(uniqueKeysWithValues: PayoffStrategy.allCases.map { ($0, store.payoff($0)) })
        let chosen = results[store.plan.debt.strategy]!
        let points = PayoffStrategy.allCases.flatMap { strategy in
            results[strategy]!.months.map {
                StrategyPoint(strategy: strategy.title, month: $0.month, balance: $0.totalBalance)
            }
        }

        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Your debts").font(.title3.bold())
                        Spacer()
                        Text("Total \(store.debtTotal.currency)").foregroundStyle(.secondary)
                        Button {
                            store.plan.debt.debts.append(Debt(name: "New debt", balance: 0, apr: 0.1, minimumPayment: 0))
                        } label: { Label("Add", systemImage: "plus") }
                    }
                    Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                        GridRow {
                            Text("Name"); Text("Balance"); Text("APR"); Text("Minimum"); Text("Paid off"); Text("")
                        }
                        .font(.caption).foregroundStyle(.secondary)
                        ForEach($store.plan.debt.debts) { $debt in
                            GridRow {
                                TextField("Name", text: $debt.name)
                                CurrencyField("Balance", value: $debt.balance).frame(width: 110)
                                PercentField("APR", value: $debt.apr).frame(width: 70)
                                CurrencyField("Minimum", value: $debt.minimumPayment).frame(width: 90)
                                Text(chosen.payoffMonth[debt.id].map { $0.monthsFromNow } ?? "—")
                                    .foregroundStyle(.secondary)
                                Button(role: .destructive) {
                                    store.plan.debt.debts.removeAll { $0.id == debt.id }
                                } label: { Image(systemName: "trash") }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Payoff plan").font(.title3.bold())
                    HStack(spacing: 24) {
                        LabeledContent("Monthly budget for debt") {
                            CurrencyField("Budget", value: $store.plan.debt.monthlyBudget).frame(width: 110)
                        }
                        Picker("Strategy", selection: $store.plan.debt.strategy) {
                            ForEach(PayoffStrategy.allCases) { Text($0.title).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 240)
                    }
                    Text(store.plan.debt.strategy.explanation).foregroundStyle(.secondary)
                    if store.plan.debt.monthlyBudget < minimums {
                        Label("Your budget is below the minimum payments (\(minimums.currency)/mo).",
                              systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                    }
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 12)], spacing: 12) {
                    ForEach(PayoffStrategy.allCases) { strategy in
                        let result = results[strategy]!
                        StatCard(title: strategy.title + (strategy == store.plan.debt.strategy ? " (selected)" : ""),
                                 value: result.monthsToDebtFree.map { "Debt-free \($0.monthsFromNow)" } ?? "Never at this budget",
                                 detail: result.monthsToDebtFree.map {
                                     "\($0.monthsDescription) · \(result.totalInterest.currency) total interest"
                                 },
                                 tint: result.isPaidOff ? .primary : .red)
                    }
                }

                if let avalanche = results[.avalanche], let snowball = results[.snowball],
                   avalanche.isPaidOff, snowball.isPaidOff {
                    let savings = snowball.totalInterest - avalanche.totalInterest
                    Text(savings > 1
                         ? "Avalanche saves \(savings.currency) in interest compared with snowball."
                         : "Both strategies cost about the same in interest for these debts.")
                }

                Chart(points) { point in
                    LineMark(x: .value("Month", point.month), y: .value("Balance", point.balance))
                        .foregroundStyle(by: .value("Strategy", point.strategy))
                }
                .chartYAxis { currencyAxis() }
                .chartXAxisLabel("Months from now")
                .frame(height: 260)
            }
            .padding()
        }
        .navigationTitle("Debt")
    }
}
