import Foundation

/// One yearly snapshot of an investment growing with regular contributions.
public struct GrowthPoint: Hashable, Sendable {
    public let year: Int
    /// Total money put in so far (starting amount plus contributions).
    public let contributions: Double
    /// Account value at the end of the year.
    public let balance: Double

    /// Investment growth earned on top of what was contributed.
    public var growth: Double { balance - contributions }
}

public enum Growth {
    /// Projects an investment with monthly compounding and monthly contributions
    /// made at the end of each month. Returns one point per year, starting at year 0.
    public static func project(
        initial: Double,
        monthlyContribution: Double,
        annualReturn: Double,
        years: Int
    ) -> [GrowthPoint] {
        let monthlyRate = annualReturn / 12
        var balance = initial
        var contributed = initial
        var points = [GrowthPoint(year: 0, contributions: initial, balance: initial)]
        guard years > 0 else { return points }
        for year in 1...years {
            for _ in 0..<12 {
                balance = balance * (1 + monthlyRate) + monthlyContribution
                contributed += monthlyContribution
            }
            points.append(GrowthPoint(year: year, contributions: contributed, balance: balance))
        }
        return points
    }

    /// Final value after `years` of growth.
    public static func futureValue(
        initial: Double,
        monthlyContribution: Double,
        annualReturn: Double,
        years: Int
    ) -> Double {
        project(initial: initial, monthlyContribution: monthlyContribution,
                annualReturn: annualReturn, years: years).last?.balance ?? initial
    }
}
