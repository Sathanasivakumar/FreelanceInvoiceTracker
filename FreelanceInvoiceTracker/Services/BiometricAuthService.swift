import CryptoKit
import Foundation
import LocalAuthentication

/// Supported biometric modalities mapped from LocalAuthentication.
enum BiometricType: Equatable, Sendable {
    case faceID
    case touchID
    case opticID
    case none

    var displayName: String {
        switch self {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        case .none: return "Biometrics"
        }
    }

    var systemImage: String {
        switch self {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .opticID: return "opticid"
        case .none: return "lock.shield.fill"
        }
    }
}

/// Availability state returned before presenting biometric prompts.
struct BiometricAvailability: Equatable, Sendable {
    let isAvailable: Bool
    let type: BiometricType
    let unavailableReason: String?
}

/// Errors produced by biometric or local demo authentication.
enum AuthenticationError: LocalizedError, Equatable, Sendable {
    case biometricUnavailable(String)
    case cancelledByUser
    case fallbackRequested
    case authenticationFailed(String)
    case biometryLockedOut
    case invalidInput(String)
    case invalidCredentials

    var errorDescription: String? {
        switch self {
        case .biometricUnavailable(let reason):
            return reason
        case .cancelledByUser:
            return "Authentication was cancelled. Tap Retry or use Manual Login."
        case .fallbackRequested:
            return "Switched to manual demo login."
        case .authenticationFailed(let message):
            return message
        case .biometryLockedOut:
            return "Biometric authentication is locked after too many failed attempts. Please unlock your device or use Manual Login."
        case .invalidInput(let message):
            return message
        case .invalidCredentials:
            return "Incorrect username or passcode. Please check your credentials and try again."
        }
    }
}

/// Protocol enabling unit testing of AuthenticationViewModel.
protocol BiometricAuthenticating: Sendable {
    func checkBiometricAvailability() -> BiometricAvailability
    func authenticateWithBiometrics(reason: String) async -> Result<Void, AuthenticationError>
    var hasLocalCredentials: Bool { get }
    var storedUsername: String? { get }
    func registerLocalCredentials(username: String, passcode: String) throws
    func verifyLocalCredentials(username: String, passcode: String) -> Result<Void, AuthenticationError>
}

/// Handles LocalAuthentication (Face ID / Touch ID) and salted SHA-256 local demo authentication.
/// Note: Local demo authentication never stores passwords in plain text; only a random salt and SHA-256 digest are stored.
final class BiometricAuthService: BiometricAuthenticating, @unchecked Sendable {
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    var hasLocalCredentials: Bool {
        userDefaults.string(forKey: AppConstants.localAuthUsernameKey) != nil &&
        userDefaults.string(forKey: AppConstants.localAuthSaltKey) != nil &&
        userDefaults.string(forKey: AppConstants.localAuthHashKey) != nil
    }

    var storedUsername: String? {
        userDefaults.string(forKey: AppConstants.localAuthUsernameKey)
    }

    func checkBiometricAvailability() -> BiometricAvailability {
        let context = LAContext()
        var error: NSError?
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        let type = mapBiometryType(context.biometryType)

        if canEvaluate {
            return BiometricAvailability(isAvailable: true, type: type, unavailableReason: nil)
        }

        let reason: String
        if let nsError = error {
            reason = mapLAError(nsError).localizedDescription
        } else {
            reason = "Biometric authentication is unavailable on this device."
        }

        return BiometricAvailability(isAvailable: false, type: type, unavailableReason: reason)
    }

    func authenticateWithBiometrics(reason: String) async -> Result<Void, AuthenticationError> {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        context.localizedFallbackTitle = "Use Manual Login"

        var authError: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) else {
            if let authError {
                return .failure(mapLAError(authError))
            }
            return .failure(.biometricUnavailable("Biometric authentication is not available on this device."))
        }

        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
            return success ? .success(()) : .failure(.authenticationFailed("Biometric verification did not succeed. Please try again."))
        } catch let error as NSError {
            return .failure(mapLAError(error))
        }
    }

    func registerLocalCredentials(username: String, passcode: String) throws {
        let trimmedUser = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedUser.count >= 3 else {
            throw AuthenticationError.invalidInput("Username must be at least 3 characters.")
        }
        guard passcode.count >= 6 else {
            throw AuthenticationError.invalidInput("Passcode must be at least 6 characters.")
        }

        let salt = generateRandomSaltHex()
        let hash = sha256Hex(salt: salt, secret: passcode)

        userDefaults.set(trimmedUser.lowercased(), forKey: AppConstants.localAuthUsernameKey)
        userDefaults.set(salt, forKey: AppConstants.localAuthSaltKey)
        userDefaults.set(hash, forKey: AppConstants.localAuthHashKey)
    }

    func verifyLocalCredentials(username: String, passcode: String) -> Result<Void, AuthenticationError> {
        let trimmedUser = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmedUser.isEmpty else {
            return .failure(.invalidInput("Please enter your username."))
        }
        guard !passcode.isEmpty else {
            return .failure(.invalidInput("Please enter your passcode."))
        }

        guard let savedUser = userDefaults.string(forKey: AppConstants.localAuthUsernameKey),
              let savedSalt = userDefaults.string(forKey: AppConstants.localAuthSaltKey),
              let savedHash = userDefaults.string(forKey: AppConstants.localAuthHashKey) else {
            return .failure(.invalidInput("No local demo credentials are configured yet. Create one below to continue."))
        }

        let candidateHash = sha256Hex(salt: savedSalt, secret: passcode)
        if trimmedUser == savedUser && constantTimeCompare(candidateHash, savedHash) {
            return .success(())
        }
        return .failure(.invalidCredentials)
    }

    private func mapBiometryType(_ type: LABiometryType) -> BiometricType {
        switch type {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        case .opticID:
            return .opticID
        case .none:
            return .none
        @unknown default:
            return .none
        }
    }

    private func mapLAError(_ error: NSError) -> AuthenticationError {
        let code = LAError.Code(rawValue: error.code)
        switch code {
        case .userCancel, .appCancel, .systemCancel:
            return .cancelledByUser
        case .userFallback:
            return .fallbackRequested
        case .biometryLockout:
            return .biometryLockedOut
        case .biometryNotEnrolled:
            return .biometricUnavailable("No Face ID or Touch ID is enrolled on this device. Please use manual login.")
        case .biometryNotAvailable, .passcodeNotSet:
            return .biometricUnavailable("Biometric authentication is not configured on this device. Please use manual login.")
        case .authenticationFailed:
            return .authenticationFailed("Biometrics did not recognize you. Please retry or use manual login.")
        default:
            return .authenticationFailed(error.localizedDescription)
        }
    }

    private func generateRandomSaltHex() -> String {
        var bytes = [UInt8](repeating: 0, count: 16)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return bytes.map { String(format: "%02x", $0) }.joined()
    }

    private func sha256Hex(salt: String, secret: String) -> String {
        let input = Data("\(salt):\(secret)".utf8)
        let digest = SHA256.hash(data: input)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private func constantTimeCompare(_ lhs: String, _ rhs: String) -> Bool {
        let lhsBytes = Array(lhs.utf8)
        let rhsBytes = Array(rhs.utf8)
        guard lhsBytes.count == rhsBytes.count else { return false }
        var diff: UInt8 = 0
        for (a, b) in zip(lhsBytes, rhsBytes) {
            diff |= a ^ b
        }
        return diff == 0
    }
}
