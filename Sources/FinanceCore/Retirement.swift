import Foundation

public struct RetirementInputs: Codable, Hashable, Sendable {
    public var currentAge: Int
    public var retirementAge: Int
    public var lifeExpectancy: Int
    public var currentSavings: Double
    public var monthlyContribution: Double
    /// Nominal annual return while working, e.g. 0.07 for 7%.
    public var preRetirementReturn: Double
    /// Nominal annual return once retired (usually more conservative).
    public var postRetirementReturn: Double
    public var inflation: Double
    /// Desired yearly spending in retirement, in today's dollars.
    public var annualSpending: Double
    /// Other yearly income in retirement (Social Security, pension), in today's dollars.
    public var otherAnnualIncome: Double

    public init(
        currentAge: Int, retirementAge: Int, lifeExpectancy: Int,
        currentSavings: Double, monthlyContribution: Double,
        preRetirementReturn: Double, postRetirementReturn: Double, inflation: Double,
        annualSpending: Double, otherAnnualIncome: Double
    ) {
        self.currentAge = currentAge
        self.retirementAge = retirementAge
        self.lifeExpectancy = lifeExpectancy
        self.currentSavings = currentSavings
        self.monthlyContribution = monthlyContribution
        self.preRetirementReturn = preRetirementReturn
        self.postRetirementReturn = postRetirementReturn
        self.inflation = inflation
        self.annualSpending = annualSpending
        self.otherAnnualIncome = otherAnnualIncome
    }

    /// Yearly amount the portfolio must cover, in today's dollars.
    public var annualShortfall: Double { max(0, annualSpending - otherAnnualIncome) }
}

public struct RetirementYear: Hashable, Sendable, Identifiable {
    public let age: Int
    /// Balance at this age in future (nominal) dollars.
    public let balance: Double
    /// Balance at this age expressed in today's dollars.
    public let realBalance: Double
    public let isRetired: Bool
    public var id: Int { age }
}

public struct RetirementProjection: Sendable {
    public let years: [RetirementYear]
    public let balanceAtRetirement: Double
    public let realBalanceAtRetirement: Double
    /// Age at which savings run out, or nil if they last through life expectancy.
    public let depletionAge: Int?
    /// Rough nest egg needed in today's dollars, using the given withdrawal rate.
    public let targetNestEgg: Double

    public var lastsThroughLifeExpectancy: Bool { depletionAge == nil }
}

public enum RetirementPlanner {
    /// Year-by-year projection. Contributions are added annually while working;
    /// in retirement the inflation-adjusted shortfall is withdrawn at the start of
    /// each year and the rest grows at the post-retirement return.
    public static func project(_ inputs: RetirementInputs, withdrawalRate: Double = 0.04) -> RetirementProjection {
        let start = inputs.currentAge
        let end = max(inputs.lifeExpectancy, start)
        let retireAge = min(max(inputs.retirementAge, start), end)
        func deflator(_ age: Int) -> Double { pow(1 + inputs.inflation, Double(age - start)) }

        var balance = inputs.currentSavings
        var depletionAge: Int?
        var years = [RetirementYear(age: start, balance: balance, realBalance: balance,
                                    isRetired: start >= retireAge)]

        for age in start..<end {
            if age < retireAge {
                balance = balance * (1 + inputs.preRetirementReturn) + inputs.monthlyContribution * 12
            } else {
                let withdrawal = inputs.annualShortfall * deflator(age)
                balance -= withdrawal
                if balance <= 0 {
                    balance = 0
                    if depletionAge == nil { depletionAge = age }
                } else {
                    balance *= 1 + inputs.postRetirementReturn
                }
            }
            let nextAge = age + 1
            years.append(RetirementYear(age: nextAge, balance: balance,
                                        realBalance: balance / deflator(nextAge),
                                        isRetired: nextAge >= retireAge))
        }

        let atRetirement = years.first { $0.age == retireAge } ?? years[years.count - 1]
        let target = withdrawalRate > 0 ? inputs.annualShortfall / withdrawalRate : 0
        return RetirementProjection(
            years: years,
            balanceAtRetirement: atRetirement.balance,
            realBalanceAtRetirement: atRetirement.realBalance,
            depletionAge: depletionAge,
            targetNestEgg: target
        )
    }
}
