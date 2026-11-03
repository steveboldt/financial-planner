import XCTest
@testable import FinanceCore

final class GrowthTests: XCTestCase {
    func testCompoundsMonthlyWithoutContributions() {
        let value = Growth.futureValue(initial: 1_000, monthlyContribution: 0, annualReturn: 0.12, years: 1)
        XCTAssertEqual(value, 1_000 * pow(1.01, 12), accuracy: 0.0001)
    }

    func testContributionsOnlyAtZeroReturn() {
        let points = Growth.project(initial: 0, monthlyContribution: 100, annualReturn: 0, years: 2)
        XCTAssertEqual(points.count, 3)
        XCTAssertEqual(points[1].balance, 1_200, accuracy: 0.0001)
        XCTAssertEqual(points[2].contributions, 2_400, accuracy: 0.0001)
        XCTAssertEqual(points[2].growth, 0, accuracy: 0.0001)
    }

    func testZeroYearsReturnsStartingPoint() {
        let points = Growth.project(initial: 500, monthlyContribution: 100, annualReturn: 0.05, years: 0)
        XCTAssertEqual(points.map(\.balance), [500])
    }
}

final class PortfolioTests: XCTestCase {
    func testAllocationAndBlendedReturn() {
        let holdings = [
            Holding(name: "Index fund", assetClass: .usStocks, value: 60_000),
            Holding(name: "Bond fund", assetClass: .bonds, value: 30_000),
            Holding(name: "Savings", assetClass: .cash, value: 10_000),
        ]
        let allocation = Portfolio.allocation(holdings)
        XCTAssertEqual(Portfolio.total(holdings), 100_000)
        XCTAssertEqual(allocation.first?.assetClass, .usStocks)
        XCTAssertEqual(allocation.first?.share ?? 0, 0.6, accuracy: 0.0001)

        let blended = Portfolio.blendedReturn(holdings) { assetClass in
            switch assetClass {
            case .usStocks: return 0.10
            case .bonds: return 0.04
            default: return 0.0
            }
        }
        XCTAssertEqual(blended, 0.6 * 0.10 + 0.3 * 0.04, accuracy: 0.0001)
    }

    func testEmptyPortfolio() {
        XCTAssertTrue(Portfolio.allocation([]).isEmpty)
        XCTAssertEqual(Portfolio.blendedReturn([]), 0)
    }
}
