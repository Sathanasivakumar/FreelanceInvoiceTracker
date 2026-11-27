import Foundation
import Observation

/// Provides real-time financial summary statistics and recent invoices for the Dashboard.
@Observable
@MainActor
final class DashboardViewModel {
    private let storageService: InvoiceStorageService

    init(storageService: InvoiceStorageService) {
        self.storageService = storageService
    }

    var greetingMessage: String {
        DateFormatterHelper.greeting()
    }

    var currentDateText: String {
        DateFormatterHelper.formatHeaderDate()
    }

    var selectedCurrency: CurrencyOption {
        storageService.selectedCurrency
    }

    var totalInvoicesCount: Int {
        storageService.invoices.count
    }

    /// Total unpaid balance across Pending and Overdue invoices.
    var totalPendingAmount: Double {
        storageService.invoices
            .filter { $0.currentStatus != .paid }
            .reduce(0) { $0 + $1.totalAmount }
    }

    var formattedTotalPendingAmount: String {
        CurrencyFormatter.format(totalPendingAmount, currency: selectedCurrency)
    }

    var totalPaidAmount: Double {
        storageService.invoices
            .filter { $0.currentStatus == .paid }
            .reduce(0) { $0 + $1.totalAmount }
    }

    var formattedTotalPaidAmount: String {
        CurrencyFormatter.format(totalPaidAmount, currency: selectedCurrency)
    }

    var paidInvoicesCount: Int {
        storageService.invoices.filter { $0.currentStatus == .paid }.count
    }

    var pendingInvoicesCount: Int {
        storageService.invoices.filter { $0.currentStatus == .pending }.count
    }

    var overdueInvoicesCount: Int {
        storageService.invoices.filter { $0.currentStatus == .overdue }.count
    }

    /// Returns up to 5 most recently added invoices so dashboard updates reflect newly created records immediately.
    var recentInvoices: [Invoice] {
        Array(
            storageService.invoices
                .sorted { $0.createdAt > $1.createdAt }
                .prefix(5)
        )
    }

    func formattedAmount(for invoice: Invoice) -> String {
        CurrencyFormatter.format(invoice.totalAmount, currency: selectedCurrency)
    }
}
