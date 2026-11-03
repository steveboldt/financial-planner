// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "FinancialPlanner",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "FinancialPlanner", targets: ["FinancialPlanner"]),
        .library(name: "FinanceCore", targets: ["FinanceCore"]),
    ],
    targets: [
        // Pure calculation engine: no UI, fully unit tested.
        .target(name: "FinanceCore"),
        // The macOS SwiftUI app.
        .executableTarget(name: "FinancialPlanner", dependencies: ["FinanceCore"]),
        .testTarget(name: "FinanceCoreTests", dependencies: ["FinanceCore"]),
    ]
)
