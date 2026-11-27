import SwiftUI

/// Supported display currencies stored in local user preferences.
enum CurrencyOption: String, CaseIterable, Identifiable, Codable, Sendable {
    case usd = "USD"
    case eur = "EUR"
    case gbp = "GBP"
    case cad = "CAD"
    case aud = "AUD"
    case inr = "INR"
    case jpy = "JPY"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .usd: return "$"
        case .eur: return "€"
        case .gbp: return "£"
        case .cad: return "CA$"
        case .aud: return "A$"
        case .inr: return "₹"
        case .jpy: return "¥"
        }
    }

    var displayName: String {
        switch self {
        case .usd: return "USD ($) — US Dollar"
        case .eur: return "EUR (€) — Euro"
        case .gbp: return "GBP (£) — British Pound"
        case .cad: return "CAD (CA$) — Canadian Dollar"
        case .aud: return "AUD (A$) — Australian Dollar"
        case .inr: return "INR (₹) — Indian Rupee"
        case .jpy: return "JPY (¥) — Japanese Yen"
        }
    }

    var localeIdentifier: String {
        switch self {
        case .usd: return "en_US"
        case .eur: return "de_DE"
        case .gbp: return "en_GB"
        case .cad: return "en_CA"
        case .aud: return "en_AU"
        case .inr: return "en_IN"
        case .jpy: return "ja_JP"
        }
    }
}

/// Application-wide design tokens following Dark Navy, Purple, and Green theme.
enum AppTheme {
    static let primaryNavy = Color(red: 0.075, green: 0.145, blue: 0.310)
    static let primaryNavyLight = Color(red: 0.125, green: 0.220, blue: 0.455)
    static let secondaryPurple = Color(red: 0.427, green: 0.290, blue: 1.0)
    static let accentGreen = Color(red: 0.086, green: 0.639, blue: 0.290)
    static let warningOrange = Color(red: 0.918, green: 0.463, blue: 0.067)
    static let dangerRed = Color(red: 0.863, green: 0.149, blue: 0.149)

    static let appBackground = Color(red: 0.961, green: 0.969, blue: 0.984)
    static let cardBackground = Color.white
    static let cardBorder = Color(red: 0.898, green: 0.918, blue: 0.953)
    static let textPrimary = Color(red: 0.075, green: 0.118, blue: 0.204)
    static let textSecondary = Color(red: 0.404, green: 0.455, blue: 0.545)

    static let heroGradient = LinearGradient(
        colors: [primaryNavy, primaryNavyLight, secondaryPurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardCornerRadius: CGFloat = 18
    static let controlCornerRadius: CGFloat = 12
    static let horizontalPadding: CGFloat = 16
}

/// Global application constants and UserDefaults keys.
enum AppConstants {
    static let appName = "Freelance Invoice & Payment Tracker"
    static let shortAppName = "InvoiceTracker"
    static let appVersion = "1.0.0"
    static let buildNumber = "1"

    static let biometricEnabledKey = "fit.settings.biometricEnabled"
    static let currencyCodeKey = "fit.settings.currencyCode"
    static let hasSeededDemoDataKey = "fit.storage.hasSeededDemoData"
    static let localAuthUsernameKey = "fit.auth.localUsername"
    static let localAuthSaltKey = "fit.auth.localSalt"
    static let localAuthHashKey = "fit.auth.localPasswordHash"

    static let invoicesFileName = "invoices.json"
    static let storageFolderName = "FreelanceInvoiceTracker"
}
