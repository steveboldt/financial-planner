import Foundation

public enum AssetClass: String, CaseIterable, Codable, Hashable, Sendable, Identifiable {
    case usStocks, internationalStocks, bonds, cash, realEstate, other

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .usStocks: return "US stocks"
        case .internationalStocks: return "International stocks"
        case .bonds: return "Bonds"
        case .cash: return "Cash"
        case .realEstate: return "Real estate"
        case .other: return "Other"
        }
    }

    /// Placeholder long-run nominal return assumptions. These are rough planning
    /// defaults, not forecasts; the user should be able to override them.
    public var defaultExpectedReturn: Double {
        switch self {
        case .usStocks: return 0.07
        case .internationalStocks: return 0.07
        case .bonds: return 0.04
        case .cash: return 0.03
        case .realEstate: return 0.06
        case .other: return 0.05
        }
    }
}

public struct Holding: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var assetClass: AssetClass
    public var value: Double

    public init(id: UUID = UUID(), name: String, assetClass: AssetClass, value: Double) {
        self.id = id
        self.name = name
        self.assetClass = assetClass
        self.value = value
    }
}

public struct AllocationSlice: Hashable, Sendable, Identifiable {
    public let assetClass: AssetClass
    public let value: Double
    public let share: Double
    public var id: AssetClass { assetClass }
}

public enum Portfolio {
    public static func total(_ holdings: [Holding]) -> Double {
        holdings.reduce(0) { $0 + max(0, $1.value) }
    }

    /// Allocation by asset class, largest first. Empty classes are omitted.
    public static func allocation(_ holdings: [Holding]) -> [AllocationSlice] {
        let total = total(holdings)
        guard total > 0 else { return [] }
        var byClass: [AssetClass: Double] = [:]
        for holding in holdings where holding.value > 0 {
            byClass[holding.assetClass, default: 0] += holding.value
        }
        return byClass
            .map { AllocationSlice(assetClass: $0.key, value: $0.value, share: $0.value / total) }
            .sorted { $0.value > $1.value }
    }

    /// Value-weighted expected return using each class's assumption.
    public static func blendedReturn(
        _ holdings: [Holding],
        assumptions: (AssetClass) -> Double = { $0.defaultExpectedReturn }
    ) -> Double {
        allocation(holdings).reduce(0) { $0 + $1.share * assumptions($1.assetClass) }
    }
}
