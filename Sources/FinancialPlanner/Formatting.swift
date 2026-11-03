import Charts
import Foundation
import SwiftUI

extension Double {
    var currency: String { formatted(.currency(code: "USD").precision(.fractionLength(0))) }
    var compactCurrency: String {
        "$" + formatted(.number.notation(.compactName).precision(.significantDigits(1...3)))
    }
    var percent: String { formatted(.percent.precision(.fractionLength(1))) }
}

extension Int {
    /// "3 yr 4 mo" style duration for a number of months.
    var monthsDescription: String {
        let years = self / 12
        let months = self % 12
        switch (years, months) {
        case (0, _): return "\(months) mo"
        case (_, 0): return "\(years) yr"
        default: return "\(years) yr \(months) mo"
        }
    }

    var monthsFromNow: String {
        let date = Calendar.current.date(byAdding: .month, value: self, to: .now) ?? .now
        return date.formatted(.dateTime.month(.abbreviated).year())
    }
}

/// Text field bound to a dollar amount.
struct CurrencyField: View {
    let title: String
    @Binding var value: Double

    init(_ title: String, value: Binding<Double>) {
        self.title = title
        self._value = value
    }

    var body: some View {
        TextField(title, value: $value, format: .currency(code: "USD").precision(.fractionLength(0...2)))
            .multilineTextAlignment(.trailing)
    }
}

/// Text field bound to a rate stored as a fraction (0.07 shows as 7%).
struct PercentField: View {
    let title: String
    @Binding var value: Double

    init(_ title: String, value: Binding<Double>) {
        self.title = title
        self._value = value
    }

    var body: some View {
        TextField(title, value: $value, format: .percent.precision(.fractionLength(0...2)))
            .multilineTextAlignment(.trailing)
    }
}

/// A headline number on a card.
struct StatCard: View {
    let title: String
    let value: String
    var detail: String? = nil
    var tint: Color = .primary

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.subheadline).foregroundStyle(.secondary)
            Text(value).font(.title2.weight(.semibold)).foregroundStyle(tint)
                .monospacedDigit()
            if let detail {
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
    }
}

/// Y axis that labels values as compact dollars ($120K, $1.2M).
func currencyAxis() -> some AxisContent {
    AxisMarks { value in
        AxisGridLine()
        AxisValueLabel {
            if let amount = value.as(Double.self) {
                Text(amount.compactCurrency)
            }
        }
    }
}
