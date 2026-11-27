import SwiftUI

/// Root view coordinating authentication state and the main tab navigation.
struct ContentView: View {
    @State private var storageService: InvoiceStorageService
    @State private var authViewModel: AuthenticationViewModel
    @State private var selectedTab: AppTab = .dashboard

    enum AppTab: Hashable {
        case dashboard
        case invoices
        case settings
    }

    init() {
        let storage = InvoiceStorageService()
        self._storageService = State(initialValue: storage)
        self._authViewModel = State(initialValue: AuthenticationViewModel(storageService: storage))
    }

    var body: some View {
        Group {
            switch authViewModel.currentStep {
            case .splash:
                LaunchSplashView()
            case .biometric:
                BiometricAuthView(viewModel: authViewModel)
            case .manualLogin:
                LoginView(viewModel: authViewModel)
            case .authenticated:
                mainTabView
            }
        }
        .task {
            await authViewModel.startAppFlow()
        }
        .animation(.easeInOut(duration: 0.25), value: authViewModel.currentStep)
    }

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                DashboardView(storageService: storageService) {
                    selectedTab = .invoices
                }
            }
            .tabItem {
                Label("Dashboard", systemImage: "square.grid.2x2.fill")
            }
            .tag(AppTab.dashboard)

            NavigationStack {
                InvoiceListView(storageService: storageService)
            }
            .tabItem {
                Label("Invoices", systemImage: "doc.text.fill")
            }
            .tag(AppTab.invoices)

            NavigationStack {
                SettingsView(
                    storageService: storageService,
                    authViewModel: authViewModel
                )
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(AppTab.settings)
        }
        .tint(AppTheme.secondaryPurple)
    }
}
