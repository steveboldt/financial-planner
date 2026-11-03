import XCTest
@testable import FinanceCore

final class RetirementTests: XCTestCase {
    private func inputs(spending: Double) -> RetirementInputs {
        RetirementInputs(
            currentAge: 60, retirementAge: 62, lifeExpectancy: 65,
            currentSavings: 100_000, monthlyContribution: 1_000,
            preRetirementReturn: 0, postRetirementReturn: 0, inflation: 0,
            annualSpending: spending, otherAnnualIncome: 10_000
        )
    }

    func testMoneyLastsWhenSpendingIsCovered() {
        let projection = RetirementPlanner.project(inputs(spending: 50_000))
        XCTAssertEqual(projection.balanceAtRetirement, 124_000, accuracy: 0.01)
        XCTAssertEqual(projection.years.last?.age, 65)
        XCTAssertEqual(projection.years.last?.balance ?? -1, 4_000, accuracy: 0.01)
        XCTAssertNil(projection.depletionAge)
        XCTAssertTrue(projection.lastsThroughLifeExpectancy)
    }

    func testReportsDepletionAge() {
        let projection = RetirementPlanner.project(inputs(spending: 60_000))
        XCTAssertEqual(projection.depletionAge, 64)
        XCTAssertEqual(projection.years.last?.balance, 0)
    }

    func testTargetNestEggUsesWithdrawalRate() {
        let projection = RetirementPlanner.project(inputs(spending: 50_000), withdrawalRate: 0.04)
        XCTAssertEqual(projection.targetNestEgg, 1_000_000, accuracy: 0.01)
    }

    func testInflationReducesRealBalance() {
        var input = inputs(spending: 10_000)
        input.inflation = 0.03
        let projection = RetirementPlanner.project(input)
        XCTAssertLessThan(projection.realBalanceAtRetirement, projection.balanceAtRetirement)
    }
}
