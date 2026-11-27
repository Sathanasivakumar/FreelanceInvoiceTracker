import Foundation
import Observation

/// Manages invoice listing, combined search and category/status filtering, and quick actions.
@Observable
@MainActor
final class InvoiceListViewModel {
    var searchText: String = ""
    var selectedCategory: InvoiceCategory? = nil
    var selectedStatus: PaymentStatus? = nil
    var actionErrorMessage: String?

    private let storageService: InvoiceStorageService

    init(storageService: InvoiceStorageService) {
        self.storageService = storageService
    }

    var selectedCurrency: CurrencyOption {
        storageService.selectedCurrency
    }

    var totalInvoicesCount: Int {
        storageService.invoices.count
    }

    var hasActiveFilters: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || selectedCategory != nil
            || selectedStatus != nil
    }

    /// Combines text search (title, client name, invoice number), category filter, and effective payment status filter.
    var filteredInvoices: [Invoice] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return storageService.invoices.filter { invoice in
            let matchesQuery: Bool
            if query.isEmpty {
                matchesQuery = true
            } else {
                matchesQuery = invoice.title.lowercased().contains(query)
                    || invoice.clientName.lowercased().contains(query)
                    || invoice.invoiceNumber.lowercased().contains(query)
            }

            let matchesCategory = selectedCategory == nil || invoice.category == selectedCategory
            let matchesStatus = selectedStatus == nil || invoice.currentStatus == selectedStatus

            return matchesQuery && matchesCategory && matchesStatus
        }
    }

    func clearFilters() {
        searchText = ""
        selectedCategory = nil
        selectedStatus = nil
    }

    func formattedAmount(for invoice: Invoice) -> String {
        CurrencyFormatter.format(invoice.totalAmount, currency: selectedCurrency)
    }

    func markAsPaid(_ invoice: Invoice) {
        do {
            try storageService.markAsPaid(id: invoice.id)
            actionErrorMessage = nil
        } catch {
            actionErrorMessage = error.localizedDescription
        }
    }

    func deleteInvoice(_ invoice: Invoice) {
        do {
            try storageService.deleteInvoice(id: invoice.id)
            actionErrorMessage = nil
        } catch {
            actionErrorMessage = error.localizedDescription
        }
    }
}
