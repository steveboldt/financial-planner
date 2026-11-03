import SwiftUI

enum Screen: String, CaseIterable, Identifiable {
    case dashboard, investing, retirement, debt

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .investing: return "Investing"
        case .retirement: return "Retirement"
        case .debt: return "Debt"
        }
    }

    var symbol: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .investing: return "chart.pie"
        case .retirement: return "sun.horizon"
        case .debt: return "creditcard"
        }
    }
}

struct ContentView: View {
    @State private var selection: Screen? = .dashboard

    var body: some View {
        NavigationSplitView {
            List(Screen.allCases, selection: $selection) { screen in
                Label(screen.title, systemImage: screen.symbol).tag(screen)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            switch selection ?? .dashboard {
            case .dashboard: DashboardView(selection: $selection)
            case .investing: InvestingView()
            case .retirement: RetirementView()
            case .debt: DebtView()
            }
        }
    }
}
