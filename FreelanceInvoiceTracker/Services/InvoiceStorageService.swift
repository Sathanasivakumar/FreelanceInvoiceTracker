import Foundation
import Observation

/// Errors thrown by local invoice persistence operations.
enum InvoiceStorageError: LocalizedError, Equatable {
    case duplicateInvoiceID
    case duplicateInvoiceNumber(String)
    case invoiceNotFound
    case persistenceFailed(String)

    var errorDescription: String? {
        switch self {
        case .duplicateInvoiceID:
            return "An invoice with this identifier already exists."
        case .duplicateInvoiceNumber(let number):
            return "Invoice number \"\(number)\" is already in use. Please choose a unique number."
        case .invoiceNotFound:
            return "The selected invoice could not be found."
        case .persistenceFailed(let message):
            return "Unable to save invoice data locally: \(message)"
        }
    }
}

/// Manages persistent local storage of invoices and app settings.
@Observable
@MainActor
final class InvoiceStorageService {
    private(set) var invoices: [Invoice] = []
    private(set) var lastStorageErrorMessage: String?

    var selectedCurrency: CurrencyOption {
        didSet {
            userDefaults.set(selectedCurrency.rawValue, forKey: AppConstants.currencyCodeKey)
        }
    }

    var isBiometricLockEnabled: Bool {
        didSet {
            userDefaults.set(isBiometricLockEnabled, forKey: AppConstants.biometricEnabledKey)
        }
    }

    private let storageURL: URL
    private let userDefaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        storageURL: URL? = nil,
        userDefaults: UserDefaults = .standard,
        seedSampleDataIfFirstLaunch: Bool = true
    ) {
        self.userDefaults = userDefaults
        self.storageURL = storageURL ?? Self.defaultStorageURL()

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        let savedCurrencyCode = userDefaults.string(forKey: AppConstants.currencyCodeKey) ?? CurrencyOption.usd.rawValue
        self.selectedCurrency = CurrencyOption(rawValue: savedCurrencyCode) ?? .usd

        if userDefaults.object(forKey: AppConstants.biometricEnabledKey) != nil {
            self.isBiometricLockEnabled = userDefaults.bool(forKey: AppConstants.biometricEnabledKey)
        } else {
            self.isBiometricLockEnabled = true
        }

        loadInvoices(seedSampleDataIfFirstLaunch: seedSampleDataIfFirstLaunch)
    }

    /// Reloads invoices directly from persistent storage.
    func reload() {
        loadInvoices(seedSampleDataIfFirstLaunch: false)
    }

    func addInvoice(_ invoice: Invoice) throws {
        guard !invoices.contains(where: { $0.id == invoice.id }) else {
            throw InvoiceStorageError.duplicateInvoiceID
        }
        guard isInvoiceNumberUnique(invoice.invoiceNumber) else {
            throw InvoiceStorageError.duplicateInvoiceNumber(invoice.invoiceNumber)
        }

        var updated = invoices
        updated.insert(invoice, at: 0)
        try persist(updated)
        invoices = sortedByNewest(updated)
    }

    func updateInvoice(_ invoice: Invoice) throws {
        guard let index = invoices.firstIndex(where: { $0.id == invoice.id }) else {
            throw InvoiceStorageError.invoiceNotFound
        }
        guard isInvoiceNumberUnique(invoice.invoiceNumber, excludingId: invoice.id) else {
            throw InvoiceStorageError.duplicateInvoiceNumber(invoice.invoiceNumber)
        }

        var updatedInvoice = invoice
        updatedInvoice.updatedAt = Date()

        var updated = invoices
        updated[index] = updatedInvoice
        try persist(updated)
        invoices = sortedByNewest(updated)
    }

    func deleteInvoice(id: UUID) throws {
        guard invoices.contains(where: { $0.id == id }) else {
            throw InvoiceStorageError.invoiceNotFound
        }

        var updated = invoices
        updated.removeAll { $0.id == id }
        try persist(updated)
        invoices = sortedByNewest(updated)
    }

    func markAsPaid(id: UUID) throws {
        guard let existing = invoices.first(where: { $0.id == id }) else {
            throw InvoiceStorageError.invoiceNotFound
        }
        var updated = existing
        updated.status = .paid
        updated.updatedAt = Date()
        try updateInvoice(updated)
    }

    func invoice(withId id: UUID) -> Invoice? {
        invoices.first { $0.id == id }
    }

    /// Unique client directory derived from stored invoices.
    var knownClients: [Client] {
        var seen = Set<String>()
        var result: [Client] = []
        for invoice in invoices {
            let trimmed = invoice.clientName.trimmingCharacters(in: .whitespacesAndNewlines)
            let key = trimmed.lowercased()
            guard !trimmed.isEmpty, !seen.contains(key) else { continue }
            seen.insert(key)
            result.append(Client(name: trimmed))
        }
        return result.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func isInvoiceNumberUnique(_ number: String, excludingId: UUID? = nil) -> Bool {
        let normalized = number.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else { return false }
        return !invoices.contains { invoice in
            if let excludingId, invoice.id == excludingId {
                return false
            }
            return invoice.invoiceNumber.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == normalized
        }
    }

    func nextSuggestedInvoiceNumber() -> String {
        let numericParts = invoices.compactMap { invoice -> Int? in
            let digits = invoice.invoiceNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            return Int(digits)
        }
        let nextNumber = (numericParts.max() ?? 1000) + 1
        return "INV-\(nextNumber)"
    }

    private func loadInvoices(seedSampleDataIfFirstLaunch: Bool) {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: storageURL.path) {
            do {
                let data = try Data(contentsOf: storageURL)
                let decoded = try decoder.decode([Invoice].self, from: data)
                invoices = sortedByNewest(decoded)
                lastStorageErrorMessage = nil
                return
            } catch {
                lastStorageErrorMessage = error.localizedDescription
            }
        }

        let hasSeeded = userDefaults.bool(forKey: AppConstants.hasSeededDemoDataKey)
        if seedSampleDataIfFirstLaunch && !hasSeeded {
            let demoInvoices = Self.makeInitialSampleInvoices()
            do {
                try persist(demoInvoices)
                invoices = sortedByNewest(demoInvoices)
                userDefaults.set(true, forKey: AppConstants.hasSeededDemoDataKey)
            } catch {
                invoices = sortedByNewest(demoInvoices)
                lastStorageErrorMessage = error.localizedDescription
            }
        } else {
            invoices = []
        }
    }

    private func persist(_ items: [Invoice]) throws {
        let directory = storageURL.deletingLastPathComponent()
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try encoder.encode(items)
            try data.write(to: storageURL, options: [.atomic])
            lastStorageErrorMessage = nil
        } catch {
            let message = error.localizedDescription
            lastStorageErrorMessage = message
            throw InvoiceStorageError.persistenceFailed(message)
        }
    }

    private func sortedByNewest(_ items: [Invoice]) -> [Invoice] {
        items.sorted { lhs, rhs in
            if lhs.issueDate != rhs.issueDate {
                return lhs.issueDate > rhs.issueDate
            }
            return lhs.createdAt > rhs.createdAt
        }
    }

    private static func defaultStorageURL() -> URL {
        let baseDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return baseDir
            .appendingPathComponent(AppConstants.storageFolderName, isDirectory: true)
            .appendingPathComponent(AppConstants.invoicesFileName)
    }

    /// Initial demo invoices seeded only on very first launch; users can freely edit or delete them.
    private static func makeInitialSampleInvoices() -> [Invoice] {
        let calendar = Calendar.current
        let today = Date()

        let daysAgo: (Int) -> Date = { offset in
            calendar.date(byAdding: .day, value: -offset, to: today) ?? today
        }
        let daysFromNow: (Int) -> Date = { offset in
            calendar.date(byAdding: .day, value: offset, to: today) ?? today
        }

        return [
            Invoice(
                invoiceNumber: "INV-1001",
                title: "E-Commerce Checkout Redesign",
                clientName: "Northstar Retail Co.",
                category: .design,
                issueDate: daysAgo(18),
                dueDate: daysAgo(3),
                amount: 2400,
                taxPercentage: 10,
                notes: "UI/UX wireframes, interactive prototype, and design tokens handoff.",
                status: .paid
            ),
            Invoice(
                invoiceNumber: "INV-1002",
                title: "SaaS Marketing Site Build",
                clientName: "Apex Cloud Labs",
                category: .webDevelopment,
                issueDate: daysAgo(5),
                dueDate: daysFromNow(10),
                amount: 3800,
                taxPercentage: 8,
                notes: "Responsive landing pages, CMS integration, and Lighthouse optimization.",
                status: .pending
            ),
            Invoice(
                invoiceNumber: "INV-1003",
                title: "Q4 Architecture Advisory",
                clientName: "Meridian FinTech",
                category: .consulting,
                issueDate: daysAgo(21),
                dueDate: daysAgo(4),
                amount: 1650,
                taxPercentage: 0,
                notes: "Technical roadmap audit and payment gateway compliance review.",
                status: .pending
            ),
            Invoice(
                invoiceNumber: "INV-1004",
                title: "Developer API Documentation",
                clientName: "Veloce Analytics",
                category: .writing,
                issueDate: daysAgo(2),
                dueDate: daysFromNow(14),
                amount: 950,
                taxPercentage: 5,
                notes: "REST endpoint guides, SDK quickstart, and webhook examples.",
                status: .pending
            )
        ]
    }
}
