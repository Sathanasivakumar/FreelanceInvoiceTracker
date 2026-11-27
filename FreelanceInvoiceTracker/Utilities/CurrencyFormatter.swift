import Foundation

/// Formats monetary amounts according to the user's selected currency preference.
enum CurrencyFormatter {
    private static let lock = NSLock()
    private static var cachedFormatters: [CurrencyOption: NumberFormatter] = [:]

    static func format(_ amount: Double, currency: CurrencyOption = .usd) -> String {
        let formatter = numberFormatter(for: currency)
        return formatter.string(from: NSNumber(value: amount))
            ?? "\(currency.symbol)\(String(format: "%.2f", amount))"
    }

    private static func numberFormatter(for currency: CurrencyOption) -> NumberFormatter {
        lock.lock()
        defer { lock.unlock() }

        if let existing = cachedFormatters[currency] {
            return existing
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency.rawValue
        formatter.currencySymbol = currency.symbol
        formatter.locale = Locale(identifier: currency.localeIdentifier)
        if currency == .jpy {
            formatter.maximumFractionDigits = 0
            formatter.minimumFractionDigits = 0
        } else {
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 2
        }
        cachedFormatters[currency] = formatter
        return formatter
    }
}
