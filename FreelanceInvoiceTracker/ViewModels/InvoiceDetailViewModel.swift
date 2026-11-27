import Foundation
import Observation

/// Manages display, payment status updates, editing, and deletion for a single invoice.
@Observable
@MainActor
final class InvoiceDetailViewModel {
    let invoiceId: UUID
    private let storageService: InvoiceStorageService

    var isShowingDeleteAlert: Bool = false
    var isShowingEditSheet: Bool = false
    var actionErrorMessage: String?
    var statusMessage: String?

    init(invoiceId: UUID, storageService: InvoiceStorageService) {
        self.invoiceId = invoiceId
        self.storageService = storageService
    }

    var invoice: Invoice? {
        storageService.invoice(withId: invoiceId)
    }

    var selectedCurrency: CurrencyOption {
        storageService.selectedCurrency
    }

    func formattedBaseAmount(_ invoice: Invoice) -> String {
        CurrencyFormatter.format(invoice.amount, currency: selectedCurrency)
    }

    func formattedTaxAmount(_ invoice: Invoice) -> String {
        CurrencyFormatter.format(invoice.taxAmount, currency: selectedCurrency)
    }

    func formattedTotalAmount(_ invoice: Invoice) -> String {
        CurrencyFormatter.format(invoice.totalAmount, currency: selectedCurrency)
    }

    func markAsPaid() {
        do {
            try storageService.markAsPaid(id: invoiceId)
            actionErrorMessage = nil
            statusMessage = "Invoice marked as Paid."
        } catch {
            actionErrorMessage = error.localizedDescription
        }
    }

    @discardableResult
    func confirmDelete() -> Bool {
        do {
            try storageService.deleteInvoice(id: invoiceId)
            actionErrorMessage = nil
            return true
        } catch {
            actionErrorMessage = error.localizedDescription
            return false
        }
    }
}
