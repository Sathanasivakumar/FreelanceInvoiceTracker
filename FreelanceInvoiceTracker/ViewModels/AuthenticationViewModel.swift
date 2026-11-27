import Foundation
import Observation

/// Coordinates splash screen, biometric authentication (Face ID / Touch ID), and local demo login.
@Observable
@MainActor
final class AuthenticationViewModel {
    enum AuthStep: Equatable {
        case splash
        case biometric
        case manualLogin
        case authenticated
    }

    private(set) var currentStep: AuthStep = .splash
    private(set) var biometricAvailability: BiometricAvailability
    private(set) var isAuthenticating: Bool = false
    var infoBannerMessage: String?
    var errorMessage: String?

    // Manual demo login state
    var username: String = ""
    var passcode: String = ""
    var isCreatingLocalCredentials: Bool = false

    private let authService: BiometricAuthenticating
    private let storageService: InvoiceStorageService
    private var hasStartedFlow = false

    init(
        authService: BiometricAuthenticating = BiometricAuthService(),
        storageService: InvoiceStorageService
    ) {
        self.authService = authService
        self.storageService = storageService
        self.biometricAvailability = authService.checkBiometricAvailability()
        self.isCreatingLocalCredentials = !authService.hasLocalCredentials
        if let savedUsername = authService.storedUsername {
            self.username = savedUsername
        }
    }

    var hasLocalCredentials: Bool {
        authService.hasLocalCredentials
    }

    var isBiometricPreferenceEnabled: Bool {
        storageService.isBiometricLockEnabled
    }

    /// Launches the initial authentication sequence after displaying the splash screen.
    func startAppFlow(splashDelayNanoseconds: UInt64 = 1_100_000_000) async {
        guard !hasStartedFlow else { return }
        hasStartedFlow = true

        if splashDelayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: splashDelayNanoseconds)
        }

        evaluateInitialAuthRoute()
    }

    /// Re-evaluates whether biometric prompt or manual login should be presented.
    func evaluateInitialAuthRoute() {
        biometricAvailability = authService.checkBiometricAvailability()
        isCreatingLocalCredentials = !authService.hasLocalCredentials

        if storageService.isBiometricLockEnabled && biometricAvailability.isAvailable {
            currentStep = .biometric
            infoBannerMessage = nil
            errorMessage = nil
            Task {
                await authenticateWithBiometrics()
            }
        } else {
            currentStep = .manualLogin
            errorMessage = nil
            if storageService.isBiometricLockEnabled && !biometricAvailability.isAvailable {
                infoBannerMessage = biometricAvailability.unavailableReason
            } else {
                infoBannerMessage = nil
            }
        }
    }

    /// Attempts Face ID or Touch ID authentication.
    func authenticateWithBiometrics() async {
        guard !isAuthenticating else { return }
        biometricAvailability = authService.checkBiometricAvailability()

        guard biometricAvailability.isAvailable else {
            errorMessage = biometricAvailability.unavailableReason
                ?? "Biometric authentication is unavailable on this device."
            currentStep = .manualLogin
            return
        }

        isAuthenticating = true
        errorMessage = nil

        let reason = "Unlock Freelance Invoice & Payment Tracker to view your invoices."
        let result = await authService.authenticateWithBiometrics(reason: reason)
        isAuthenticating = false

        switch result {
        case .success:
            passcode = ""
            errorMessage = nil
            currentStep = .authenticated
        case .failure(let error):
            switch error {
            case .fallbackRequested:
                errorMessage = nil
                currentStep = .manualLogin
            case .biometricUnavailable(let reason):
                errorMessage = reason
                currentStep = .manualLogin
            case .cancelledByUser, .authenticationFailed, .biometryLockedOut, .invalidInput, .invalidCredentials:
                errorMessage = error.localizedDescription
            }
        }
    }

    /// Switches to manual local login screen.
    func switchToManualLogin() {
        errorMessage = nil
        isCreatingLocalCredentials = !authService.hasLocalCredentials
        currentStep = .manualLogin
    }

    /// Switches back to biometric authentication if available on this device.
    func switchToBiometricAuth() {
        biometricAvailability = authService.checkBiometricAvailability()
        guard biometricAvailability.isAvailable else {
            errorMessage = biometricAvailability.unavailableReason
                ?? "Biometrics are not available on this device."
            return
        }
        errorMessage = nil
        currentStep = .biometric
        Task {
            await authenticateWithBiometrics()
        }
    }

    /// Validates and processes local demo login or credential setup.
    func submitManualLogin() {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedUsername.count >= 3 else {
            errorMessage = "Username must be at least 3 characters."
            return
        }

        guard !trimmedUsername.contains(" ") else {
            errorMessage = "Username cannot contain spaces."
            return
        }

        guard passcode.count >= 6 else {
            errorMessage = "Passcode must be at least 6 characters."
            return
        }

        if isCreatingLocalCredentials || !authService.hasLocalCredentials {
            do {
                try authService.registerLocalCredentials(username: trimmedUsername, passcode: passcode)
                passcode = ""
                errorMessage = nil
                isCreatingLocalCredentials = false
                currentStep = .authenticated
            } catch {
                errorMessage = error.localizedDescription
            }
        } else {
            let result = authService.verifyLocalCredentials(username: trimmedUsername, passcode: passcode)
            switch result {
            case .success:
                passcode = ""
                errorMessage = nil
                currentStep = .authenticated
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }

    /// Clears sensitive input and retries manual login.
    func retryManualLogin() {
        errorMessage = nil
        passcode = ""
    }

    /// Toggles between Sign In and Create/Reset Local Demo Credentials.
    func toggleCredentialSetupMode() {
        errorMessage = nil
        passcode = ""
        isCreatingLocalCredentials.toggle()
    }

    /// Locks the active session and returns to the authentication flow.
    func logout() {
        passcode = ""
        errorMessage = nil
        biometricAvailability = authService.checkBiometricAvailability()
        isCreatingLocalCredentials = !authService.hasLocalCredentials
        if let savedUsername = authService.storedUsername {
            username = savedUsername
        }
        if storageService.isBiometricLockEnabled && biometricAvailability.isAvailable {
            currentStep = .biometric
        } else {
            currentStep = .manualLogin
        }
    }
}
