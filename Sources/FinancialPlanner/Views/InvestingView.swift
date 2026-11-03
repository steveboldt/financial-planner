import Charts
import FinanceCore
import SwiftUI

struct InvestingView: View {
    @Environment(PlanStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                holdingsSection
                allocationSection
                growthSection
            }
            .padding()
        }
        .navigationTitle("Investing")
    }

    // MARK: Holdings

    private var holdingsSection: some View {
        @Bindable var store = store
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Holdings").font(.title3.bold())
                Spacer()
                Text("Total \(store.investmentsTotal.currency)").foregroundStyle(.secondary)
                Button {
                    store.plan.holdings.append(Holding(name: "New holding", assetClass: .usStocks, value: 0))
                } label: { Label("Add", systemImage: "plus") }
            }
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                GridRow {
                    Text("Name"); Text("Type"); Text("Value"); Text("")
                }
                .font(.caption).foregroundStyle(.secondary)
                ForEach($store.plan.holdings) { $holding in
                    GridRow {
                        TextField("Name", text: $holding.name)
                        Picker("Type", selection: $holding.assetClass) {
                            ForEach(AssetClass.allCases) { Text($0.title).tag($0) }
                        }
                        .labelsHidden()
                        CurrencyField("Value", value: $holding.value).frame(width: 130)
                        Button(role: .destructive) {
                            store.plan.holdings.removeAll { $0.id == holding.id }
                        } label: { Image(systemName: "trash") }
                        .buttonStyle(.borderless)
                    }
                }
            }
        }
    }

    // MARK: Allocation

    private var allocationSection: some View {
        let slices = Portfolio.allocation(store.plan.holdings)
        return VStack(alignment: .leading, spacing: 8) {
            Text("Allocation").font(.title3.bold())
            if slices.isEmpty {
                Text("Add holdings to see your allocation.").foregroundStyle(.secondary)
            } else {
                HStack(alignment: .center, spacing: 24) {
                    Chart(slices) { slice in
                        SectorMark(angle: .value("Value", slice.value), innerRadius: .ratio(0.6), angularInset: 1)
                            .foregroundStyle(by: .value("Asset class", slice.assetClass.title))
                    }
                    .chartLegend(.hidden)
                    .frame(width: 200, height: 200)

                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(slices) { slice in
                            HStack {
                                Text(slice.assetClass.title)
                                Spacer()
                                Text(slice.share.percent).monospacedDigit()
                                Text("· assumes \(slice.assetClass.defaultExpectedReturn.percent)/yr")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Divider()
                        HStack {
                            Text("Blended expected return").bold()
                            Spacer()
                            Text(store.blendedReturn.percent).bold().monospacedDigit()
                        }
                    }
                    .frame(maxWidth: 420)
                }
            }
        }
    }

    // MARK: Growth

    private struct GrowthSeries: Identifiable {
        let year: Int
        let kind: String
        let amount: Double
        var id: String { "\(year)-\(kind)" }
    }

    private var growthSection: some View {
        @Bindable var store = store
        let points = store.growthProjection
        let series = points.flatMap {
            [GrowthSeries(year: $0.year, kind: "Contributions", amount: $0.contributions),
             GrowthSeries(year: $0.year, kind: "Growth", amount: max(0, $0.growth))]
        }
        let final = points.last

        return VStack(alignment: .leading, spacing: 12) {
            Text("Growth projection").font(.title3.bold())

            HStack(spacing: 24) {
                LabeledContent("Monthly contribution") {
                    CurrencyField("Monthly", value: $store.plan.investing.monthlyContribution).frame(width: 110)
                }
                Stepper("Years: \(store.plan.investing.years)", value: $store.plan.investing.years, in: 1...50)
                Toggle("Use blended return", isOn: $store.plan.investing.useBlendedReturn)
                if !store.plan.investing.useBlendedReturn {
                    LabeledContent("Return") {
                        PercentField("Return", value: $store.plan.investing.customReturn).frame(width: 70)
                    }
                }
            }

            if let final {
                Text("In \(final.year) years: **\(final.balance.currency)**, of which \(final.growth.currency) is growth (at \(store.growthReturn.percent)/yr).")
            }

            Chart(series) { point in
                AreaMark(x: .value("Year", point.year), y: .value("Amount", point.amount))
                    .foregroundStyle(by: .value("Source", point.kind))
            }
            .chartForegroundStyleScale(["Contributions": Color.blue, "Growth": Color.green])
            .chartYAxis { currencyAxis() }
            .frame(height: 260)
        }
    }
}
