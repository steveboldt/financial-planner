import Charts
import FinanceCore
import SwiftUI

struct RetirementView: View {
    @Environment(PlanStore.self) private var store
    @State private var showTodaysDollars = true

    var body: some View {
        @Bindable var store = store
        let projection = store.retirementProjection
        let retirementAge = store.plan.retirement.retirementAge

        HSplitView {
            Form {
                Section("You") {
                    Stepper("Current age: \(store.plan.retirement.currentAge)",
                            value: $store.plan.retirement.currentAge, in: 18...90)
                    Stepper("Retire at: \(store.plan.retirement.retirementAge)",
                            value: $store.plan.retirement.retirementAge,
                            in: store.plan.retirement.currentAge...100)
                    Stepper("Plan until age: \(store.plan.retirement.lifeExpectancy)",
                            value: $store.plan.retirement.lifeExpectancy,
                            in: store.plan.retirement.retirementAge...110)
                }
                Section("Saving") {
                    CurrencyField("Saved so far", value: $store.plan.retirement.currentSavings)
                    CurrencyField("Monthly contribution", value: $store.plan.retirement.monthlyContribution)
                    Button("Use my investment total (\(store.investmentsTotal.currency))") {
                        store.plan.retirement.currentSavings = store.investmentsTotal
                    }
                    .buttonStyle(.link)
                }
                Section("Retirement spending (today's dollars)") {
                    CurrencyField("Yearly spending", value: $store.plan.retirement.annualSpending)
                    CurrencyField("Social Security / pension per year", value: $store.plan.retirement.otherAnnualIncome)
                }
                Section("Assumptions") {
                    rateSlider("Return before retiring", value: $store.plan.retirement.preRetirementReturn, range: 0...0.12)
                    rateSlider("Return after retiring", value: $store.plan.retirement.postRetirementReturn, range: 0...0.10)
                    rateSlider("Inflation", value: $store.plan.retirement.inflation, range: 0...0.08)
                }
            }
            .formStyle(.grouped)
            .frame(minWidth: 320, idealWidth: 360, maxWidth: 420)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 12)], spacing: 12) {
                        StatCard(title: "At retirement (today's $)",
                                 value: projection.realBalanceAtRetirement.currency,
                                 detail: "\(projection.balanceAtRetirement.currency) in future dollars")
                        StatCard(title: "Rough target (4% rule)",
                                 value: projection.targetNestEgg.currency,
                                 detail: "Covers \(store.plan.retirement.annualShortfall.currency)/yr from savings")
                        StatCard(title: "Money lasts",
                                 value: projection.depletionAge.map { "Until \($0)" }
                                    ?? "Past \(store.plan.retirement.lifeExpectancy)",
                                 tint: projection.lastsThroughLifeExpectancy ? .green : .orange)
                    }

                    Toggle("Show in today's dollars", isOn: $showTodaysDollars)

                    Chart {
                        ForEach(projection.years) { year in
                            let value = showTodaysDollars ? year.realBalance : year.balance
                            AreaMark(x: .value("Age", year.age), y: .value("Balance", value))
                                .foregroundStyle(by: .value("Phase", year.isRetired ? "Retired" : "Saving"))
                                .opacity(0.35)
                            LineMark(x: .value("Age", year.age), y: .value("Balance", value))
                                .foregroundStyle(.primary)
                        }
                        RuleMark(x: .value("Retire", retirementAge))
                            .lineStyle(StrokeStyle(dash: [4, 4]))
                            .annotation(position: .top, alignment: .leading) {
                                Text("Retire at \(retirementAge)").font(.caption)
                            }
                        if let depletion = projection.depletionAge {
                            RuleMark(x: .value("Runs out", depletion))
                                .foregroundStyle(.red)
                                .annotation(position: .top, alignment: .trailing) {
                                    Text("Runs out at \(depletion)").font(.caption).foregroundStyle(.red)
                                }
                        }
                    }
                    .chartForegroundStyleScale(["Saving": Color.blue, "Retired": Color.orange])
                    .chartYAxis { currencyAxis() }
                    .frame(minHeight: 320)

                    Text("Simple yearly model with steady returns. Real markets vary year to year, so treat this as a direction, not a promise.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding()
            }
            .frame(minWidth: 420)
        }
        .navigationTitle("Retirement")
    }

    private func rateSlider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
                Spacer()
                Text(value.wrappedValue.percent).monospacedDigit()
            }
            Slider(value: value, in: range, step: 0.0025)
        }
    }
}
