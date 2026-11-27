import SwiftUI

/// Application settings screen for security preferences, currency display, app info, and logout.
struct SettingsView: View {
    @Bindable var storageService: InvoiceStorageService
    let authViewModel: AuthenticationViewModel

    @State private var isShowingLogoutConfirm: Bool = false

    var body: some View {
        Form {
            Section("Security") {
                Toggle(isOn: $storageService.isBiometricLockEnabled) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Biometric Unlock")
                            Text(biometricStatusSubtitle)
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    } icon: {
                        Image(systemName: authViewModel.biometricAvailability.type.systemImage)
                            .foregroundStyle(AppTheme.secondaryPurple)
                    }
                }
                .tint(AppTheme.accentGreen)
            }

            Section("Preferences") {
                Picker(selection: $storageService.selectedCurrency) {
                    ForEach(CurrencyOption.allCases) { option in
                        Text(option.displayName).tag(option)
                    }
                } label: {
                    Label("Currency Display", systemImage: "dollarsign.circle.fill")
                        .foregroundStyle(AppTheme.primaryNavy)
                }
            }

            Section("App Information") {
                infoRow(title: "Application", value: AppConstants.appName)
                infoRow(title: "Version", value: "\(AppConstants.appVersion) (\(AppConstants.buildNumber))")
                infoRow(title: "Stored Invoices", value: "\(storageService.invoices.count)")
                infoRow(title: "Data Storage", value: "Local Offline Storage")
            }

            Section("About Application") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Built for Freelancers")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("Freelance Invoice & Payment Tracker keeps your billing records, client summaries, and payment statuses organized 100% offline on your iPhone. Authentication uses Apple's LocalAuthentication framework (Face ID / Touch ID) with a local-only salted SHA-256 fallback login.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button(role: .destructive) {
                    isShowingLogoutConfirm = true
                } label: {
                    HStack {
                        Spacer()
                        Label("Logout & Lock App", systemImage: "rectangle.portrait.and.arrow.right")
                            .font(.headline)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Lock & Logout?", isPresented: $isShowingLogoutConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Logout", role: .destructive) {
                authViewModel.logout()
            }
        } message: {
            Text("You will need to authenticate again to access your invoices.")
        }
    }

    private var biometricStatusSubtitle: String {
        if authViewModel.biometricAvailability.isAvailable {
            return "\(authViewModel.biometricAvailability.type.displayName) available on this device"
        }
        return "Biometrics unavailable — manual local login will be used"
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.textPrimary)
                .multilineTextAlignment(.trailing)
        }
    }
}
