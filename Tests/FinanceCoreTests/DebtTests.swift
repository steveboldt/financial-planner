import XCTest
@testable import FinanceCore

final class DebtTests: XCTestCase {
    func testZeroInterestPaysOffOnSchedule() {
        let debt = Debt(name: "Loan", balance: 1_000, apr: 0, minimumPayment: 100)
        let result = DebtPlanner.simulate(debts: [debt], monthlyBudget: 100, strategy: .avalanche)
        XCTAssertEqual(result.monthsToDebtFree, 10)
        XCTAssertEqual(result.totalInterest, 0, accuracy: 0.0001)
        XCTAssertEqual(result.totalPaid, 1_000, accuracy: 0.0001)
        XCTAssertEqual(result.payoffMonth[debt.id], 10)
    }

    func testInterestAccruesMonthly() {
        let debt = Debt(name: "Card", balance: 1_200, apr: 0.12, minimumPayment: 0)
        let result = DebtPlanner.simulate(debts: [debt], monthlyBudget: 1_200, strategy: .avalanche)
        XCTAssertEqual(result.monthsToDebtFree, 2)
        XCTAssertEqual(result.totalInterest, 12.12, accuracy: 0.0001)
    }

    func testAvalancheSavesInterestAndSnowballClearsSmallDebtFirst() {
        let card = Debt(name: "Card", balance: 5_000, apr: 0.20, minimumPayment: 100)
        let car = Debt(name: "Car", balance: 1_000, apr: 0.05, minimumPayment: 50)
        let avalanche = DebtPlanner.simulate(debts: [card, car], monthlyBudget: 500, strategy: .avalanche)
        let snowball = DebtPlanner.simulate(debts: [card, car], monthlyBudget: 500, strategy: .snowball)

        XCTAssertTrue(avalanche.isPaidOff)
        XCTAssertTrue(snowball.isPaidOff)
        XCTAssertLessThan(avalanche.totalInterest, snowball.totalInterest)
        XCTAssertLessThan(snowball.payoffMonth[car.id]!, snowball.payoffMonth[card.id]!)
        XCTAssertLessThan(avalanche.payoffMonth[card.id]!, avalanche.payoffMonth[car.id]!)
    }

    func testBudgetBelowInterestNeverPaysOff() {
        let debt = Debt(name: "Card", balance: 10_000, apr: 0.24, minimumPayment: 100)
        let result = DebtPlanner.simulate(debts: [debt], monthlyBudget: 100, strategy: .avalanche, maxMonths: 120)
        XCTAssertFalse(result.isPaidOff)
        XCTAssertNil(result.monthsToDebtFree)
        XCTAssertEqual(result.months.count, 121)
    }
}
