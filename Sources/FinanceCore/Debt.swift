import Foundation

public struct Debt: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var balance: Double
    /// Annual percentage rate, e.g. 0.199 for 19.9%.
    public var apr: Double
    public var minimumPayment: Double

    public init(id: UUID = UUID(), name: String, balance: Double, apr: Double, minimumPayment: Double) {
        self.id = id
        self.name = name
        self.balance = balance
        self.apr = apr
        self.minimumPayment = minimumPayment
    }
}

public enum PayoffStrategy: String, CaseIterable, Codable, Hashable, Sendable, Identifiable {
    /// Extra money goes to the highest interest rate first. Minimizes interest.
    case avalanche
    /// Extra money goes to the smallest balance first. Quick wins.
    case snowball

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .avalanche: return "Avalanche"
        case .snowball: return "Snowball"
        }
    }

    public var explanation: String {
        switch self {
        case .avalanche: return "Highest interest rate first. Usually the cheapest."
        case .snowball: return "Smallest balance first. Faster early wins."
        }
    }
}

public struct PayoffMonth: Hashable, Sendable, Identifiable {
    public let month: Int
    public let totalBalance: Double
    public var id: Int { month }
}

public struct PayoffResult: Sendable {
    /// Month 0 is the starting balance.
    public let months: [PayoffMonth]
    public let totalInterest: Double
    public let totalPaid: Double
    /// Month in which each debt reached zero.
    public let payoffMonth: [UUID: Int]
    /// False when the budget can't clear the debts within the simulation limit.
    public let isPaidOff: Bool

    public var monthsToDebtFree: Int? { isPaidOff ? months.last?.month : nil }
}

public enum DebtPlanner {
    static let epsilon = 0.005

    public static func minimumPaymentsTotal(_ debts: [Debt]) -> Double {
        debts.filter { $0.balance > epsilon }.reduce(0) { $0 + $1.minimumPayment }
    }

    /// Simulates paying `monthlyBudget` per month across all debts: interest accrues,
    /// every debt gets its minimum, and anything left over goes to the priority debt
    /// chosen by `strategy`. Money freed up by paid-off debts rolls into the next one.
    public static func simulate(
        debts: [Debt],
        monthlyBudget: Double,
        strategy: PayoffStrategy,
        maxMonths: Int = 600
    ) -> PayoffResult {
        var balances = Dictionary(uniqueKeysWithValues: debts.map { ($0.id, max(0, $0.balance)) })
        var months = [PayoffMonth(month: 0, totalBalance: balances.values.reduce(0, +))]
        var payoffMonth: [UUID: Int] = [:]
        var totalInterest = 0.0
        var totalPaid = 0.0
        var month = 0

        for debt in debts where balances[debt.id, default: 0] <= epsilon {
            payoffMonth[debt.id] = 0
        }

        while balances.values.contains(where: { $0 > epsilon }) && month < maxMonths {
            month += 1

            for debt in debts {
                let balance = balances[debt.id, default: 0]
                guard balance > epsilon else { continue }
                let interest = balance * debt.apr / 12
                balances[debt.id] = balance + interest
                totalInterest += interest
            }

            var available = max(0, monthlyBudget)

            for debt in debts {
                let balance = balances[debt.id, default: 0]
                guard balance > epsilon else { continue }
                let payment = min(debt.minimumPayment, balance, available)
                balances[debt.id] = balance - payment
                available -= payment
                totalPaid += payment
            }

            for debt in prioritized(debts, balances: balances, strategy: strategy) {
                guard available > epsilon else { break }
                let balance = balances[debt.id, default: 0]
                guard balance > epsilon else { continue }
                let payment = min(balance, available)
                balances[debt.id] = balance - payment
                available -= payment
                totalPaid += payment
            }

            for debt in debts where payoffMonth[debt.id] == nil && balances[debt.id, default: 0] <= epsilon {
                balances[debt.id] = 0
                payoffMonth[debt.id] = month
            }

            months.append(PayoffMonth(month: month, totalBalance: balances.values.reduce(0, +)))
        }

        let isPaidOff = !balances.values.contains(where: { $0 > epsilon })
        return PayoffResult(months: months, totalInterest: totalInterest, totalPaid: totalPaid,
                            payoffMonth: payoffMonth, isPaidOff: isPaidOff)
    }

    static func prioritized(_ debts: [Debt], balances: [UUID: Double], strategy: PayoffStrategy) -> [Debt] {
        debts.sorted { a, b in
            let balanceA = balances[a.id, default: 0]
            let balanceB = balances[b.id, default: 0]
            switch strategy {
            case .avalanche:
                return a.apr != b.apr ? a.apr > b.apr : balanceA < balanceB
            case .snowball:
                return balanceA != balanceB ? balanceA < balanceB : a.apr > b.apr
            }
        }
    }
}
