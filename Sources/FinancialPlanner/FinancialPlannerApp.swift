import AppKit
import SwiftUI

@main
struct FinancialPlannerApp: App {
    @State private var store = PlanStore()

    init() {
        // Needed so the window comes to the front when launched with `swift run`.
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    var body: some Scene {
        WindowGroup("Financial Planner") {
            ContentView()
                .environment(store)
                .frame(minWidth: 900, minHeight: 600)
        }
    }
}
