import SwiftUI

/// Fallback manual demo login screen using local salted SHA-256 verification.
struct LoginView: View {
    @Bindable var viewModel: AuthenticationViewModel
    @State private var isPasscodeVisible: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                VStack(spacing: 12) {
                    BrandLogoView(size: 80)

                    Text(viewModel.isCreatingLocalCredentials ? "Set Up Local Demo Login" : "Local Demo Login")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text(viewModel.isCreatingLocalCredentials
                         ? "Create a local username and passcode to lock your offline invoice records."
                         : "Sign in with your local credentials to access your invoices.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 28)

                // Local-only security disclaimer
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundStyle(AppTheme.secondaryPurple)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Offline Local Authentication")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)

                        Text("Demo login verifies credentials locally on this device using salted SHA-256 hashing. Passwords are never stored in plain text and no remote server account is used.")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.secondaryPurple.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(AppTheme.secondaryPurple.opacity(0.22), lineWidth: 1)
                }

                // Credentials Card
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Username")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.textSecondary)

                        HStack(spacing: 10) {
                            Image(systemName: "person.fill")
                                .foregroundStyle(AppTheme.textSecondary)
                            TextField("Minimum 3 characters", text: $viewModel.username)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                        }
                        .padding(12)
                        .background(AppTheme.appBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Passcode")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.textSecondary)

                        HStack(spacing: 10) {
                            Image(systemName: "key.fill")
                                .foregroundStyle(AppTheme.textSecondary)

                            if isPasscodeVisible {
                                TextField("Minimum 6 characters", text: $viewModel.passcode)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled(true)
                            } else {
                                SecureField("Minimum 6 characters", text: $viewModel.passcode)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled(true)
                            }

                            Button {
                                isPasscodeVisible.toggle()
                            } label: {
                                Image(systemName: isPasscodeVisible ? "eye.slash.fill" : "eye.fill")
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            .accessibilityLabel(isPasscodeVisible ? "Hide passcode" : "Show passcode")
                        }
                        .padding(12)
                        .background(AppTheme.appBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    if let infoMessage = viewModel.infoBannerMessage {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(AppTheme.warningOrange)
                            Text(infoMessage)
                                .font(.footnote)
                                .foregroundStyle(AppTheme.textPrimary)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.warningOrange.opacity(0.11))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    if let errorMessage = viewModel.errorMessage {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundStyle(AppTheme.dangerRed)
                                Text(errorMessage)
                                    .font(.footnote)
                                    .foregroundStyle(AppTheme.dangerRed)
                            }

                            Button {
                                viewModel.retryManualLogin()
                            } label: {
                                Label("Clear & Retry", systemImage: "arrow.clockwise")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AppTheme.primaryNavy)
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.dangerRed.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    Button {
                        viewModel.submitManualLogin()
                    } label: {
                        Text(viewModel.isCreatingLocalCredentials ? "Save Local Login & Continue" : "Sign In")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.heroGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .padding(.top, 4)

                    if viewModel.hasLocalCredentials {
                        Button {
                            viewModel.toggleCredentialSetupMode()
                        } label: {
                            Text(viewModel.isCreatingLocalCredentials
                                 ? "Back to Sign In"
                                 : "Reset Local Demo Credentials")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(AppTheme.secondaryPurple)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                        }
                    }

                    if viewModel.biometricAvailability.isAvailable && viewModel.isBiometricPreferenceEnabled {
                        Button {
                            viewModel.switchToBiometricAuth()
                        } label: {
                            Label(
                                "Use \(viewModel.biometricAvailability.type.displayName)",
                                systemImage: viewModel.biometricAvailability.type.systemImage
                            )
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.primaryNavy)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(AppTheme.primaryNavy.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                }
                .padding(18)
                .background(AppTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                        .stroke(AppTheme.cardBorder, lineWidth: 1)
                }
                .shadow(color: AppTheme.primaryNavy.opacity(0.06), radius: 12, x: 0, y: 5)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(AppTheme.appBackground.ignoresSafeArea())
    }
}
