import SwiftUI

/// Splash screen and Face ID / Touch ID authentication screen.
struct BiometricAuthView: View {
    @Bindable var viewModel: AuthenticationViewModel

    var body: some View {
        ZStack {
            AppTheme.heroGradient
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                VStack(spacing: 16) {
                    BrandLogoView(size: 96)

                    VStack(spacing: 6) {
                        Text("Freelance Invoice")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text("& Payment Tracker")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.88))

                        Text("Offline-first financial workspace")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.72))
                            .padding(.top, 2)
                    }
                }

                VStack(spacing: 18) {
                    Image(systemName: viewModel.biometricAvailability.type.systemImage)
                        .font(.system(size: 44, weight: .medium))
                        .foregroundStyle(AppTheme.accentGreen)
                        .padding(16)
                        .background(Color.white.opacity(0.14))
                        .clipShape(Circle())

                    VStack(spacing: 6) {
                        Text("Unlock with \(viewModel.biometricAvailability.type.displayName)")
                            .font(.headline)
                            .foregroundStyle(.white)

                        Text("Authenticate to view your client invoices and payment dashboard.")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }

                    if let errorMessage = viewModel.errorMessage {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.yellow)
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.black.opacity(0.28))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    Button {
                        Task {
                            await viewModel.authenticateWithBiometrics()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if viewModel.isAuthenticating {
                                ProgressView()
                                    .tint(AppTheme.primaryNavy)
                            } else {
                                Image(systemName: viewModel.biometricAvailability.type.systemImage)
                            }
                            Text(viewModel.errorMessage == nil
                                 ? "Authenticate with \(viewModel.biometricAvailability.type.displayName)"
                                 : "Retry \(viewModel.biometricAvailability.type.displayName)")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .foregroundStyle(AppTheme.primaryNavy)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .disabled(viewModel.isAuthenticating)

                    Button {
                        viewModel.switchToManualLogin()
                    } label: {
                        Text("Use Manual Demo Login")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.92))
                            .padding(.vertical, 8)
                    }
                }
                .padding(22)
                .background(Color.white.opacity(0.11))
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
    }
}

/// Launch splash view displayed briefly while evaluating biometric capability.
struct LaunchSplashView: View {
    var body: some View {
        ZStack {
            AppTheme.heroGradient
                .ignoresSafeArea()

            VStack(spacing: 18) {
                BrandLogoView(size: 108)

                VStack(spacing: 6) {
                    Text("Freelance Invoice")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("& Payment Tracker")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.88))
                }

                ProgressView()
                    .tint(.white)
                    .padding(.top, 12)
            }
            .padding(24)
        }
    }
}
