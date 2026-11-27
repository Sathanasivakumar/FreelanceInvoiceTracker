import Foundation
import Observation

/// Handles form state, input validation, tax calculations, and persistence for adding or editing an invoice.
@Observable
@MainActor
final class AddInvoiceViewModel {
    var invoiceNumber: String
    var title: String
    var clientName: String
    var category: InvoiceCategory
    var issueDate: Date
    var dueDate: Date
    var amountText: String
    var taxPercentageText: String
    var notes: String
    var status: PaymentStatus

    var validationErrorMessage: String?
    var successMessage: String?

    private let storageService: InvoiceStorageService
    private let editingInvoice: Invoice?

    var isEditing: Bool {
        editingInvoice != nil
    }

    var selectedCurrency: CurrencyOption {
        storageService.selectedCurrency
    }

    init(storageService: InvoiceStorageService, editingInvoice: Invoice? = nil) {
        self.storageService = storageService
        self.editingInvoice = editingInvoice

        if let invoice = editingInvoice {
            self.invoiceNumber = invoice.invoiceNumber
            self.title = invoice.title
            self.clientName = invoice.clientName
            self.category = invoice.category
            self.issueDate = invoice.issueDate
            self.dueDate = invoice.dueDate
            self.amountText = Self.formatEditableNumber(invoice.amount)
            self.taxPercentageText = invoice.taxPercentage > 0 ? Self.formatEditableNumber(invoice.taxPercentage) : ""
            self.notes = invoice.notes
            self.status = invoice.currentStatus
        } else {
            let today = Date()
            let defaultDue = Calendar.current.date(byAdding: .day, value: 14, to: today) ?? today
            self.invoiceNumber = storageService.nextSuggestedInvoiceNumber()
            self.title = ""
            self.clientName = ""
            self.category = .webDevelopment
            self.issueDate = today
            self.dueDate = defaultDue
            self.amountText = ""
            self.taxPercentageText = ""
            self.notes = ""
            self.status = .pending
        }
    }

    var parsedBaseAmount: Double {
        let normalized = amountText.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
        return Double(normalized) ?? 0
    }

    var parsedTaxPercentage: Double {
        let trimmed = taxPercentageText.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
        guard !trimmed.isEmpty else { return 0 }
        return Double(trimmed) ?? 0
    }

    var calculatedTaxAmount: Double {
        max(0, parsedBaseAmount) * max(0, parsedTaxPercentage) / 100.0
    }

    var calculatedTotalAmount: Double {
        max(0, parsedBaseAmount) + calculatedTaxAmount
    }

    var formattedTotalPreview: String {
        CurrencyFormatter.format(calculatedTotalAmount, currency: selectedCurrency)
    }

    /// Computes effective preview status based on due date and selected status.
    var effectiveStatusPreview: PaymentStatus {
        if status == .paid {
            return .paid
        }
        let calendar = Calendar.current
        if calendar.startOfDay(for: dueDate) < calendar.startOfDay(for: Date()) {
            return .overdue
        }
        return .pending
    }

    /// Validates all form inputs and persists either a new invoice or updates the existing invoice.
    @discardableResult
    func saveInvoice() -> Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedClient = clientName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNumber = invoiceNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAmount = amountText.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
        let trimmedTax = taxPercentageText.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            validationErrorMessage = "Please enter an invoice title."
            return false
        }

        guard !trimmedClient.isEmpty else {
            validationErrorMessage = "Please enter the client name."
            return false
        }

        guard !trimmedNumber.isEmpty else {
            validationErrorMessage = "Please enter an invoice number."
            return false
        }

        guard storageService.isInvoiceNumberUnique(trimmedNumber, excludingId: editingInvoice?.id) else {
            validationErrorMessage = "Invoice number \"\(trimmedNumber)\" already exists. Please enter a unique invoice number."
            return false
        }

        guard let amountValue = Double(trimmedAmount), amountValue > 0 else {
            validationErrorMessage = "Invoice amount must be greater than zero."
            return false
        }

        let taxValue: Double
        if trimmedTax.isEmpty {
            taxValue = 0
        } else if let parsedTax = Double(trimmedTax), parsedTax >= 0, parsedTax <= 100 {
            taxValue = parsedTax
        } else {
            validationErrorMessage = "Tax percentage must be between 0 and 100."
            return false
        }

        let calendar = Calendar.current
        if calendar.startOfDay(for: dueDate) < calendar.startOfDay(for: issueDate) {
            validationErrorMessage = "Due date cannot be earlier than the issue date."
            return false
        }

        // Persist Paid or Pending; Overdue is derived automatically when unpaid and past due.
        let storedStatus: PaymentStatus = (status == .paid) ? .paid : .pending

        do {
            if let existing = editingInvoice {
                let updated = Invoice(
                    id: existing.id,
                    invoiceNumber: trimmedNumber,
                    title: trimmedTitle,
                    clientName: trimmedClient,
                    category: category,
                    issueDate: issueDate,
                    dueDate: dueDate,
                    amount: amountValue,
                    taxPercentage: taxValue,
                    notes: trimmedNotes,
                    status: storedStatus,
                    createdAt: existing.createdAt,
                    updatedAt: Date()
                )
                try storageService.updateInvoice(updated)
                successMessage = "Invoice \(trimmedNumber) updated successfully."
            } else {
                let newInvoice = Invoice(
                    invoiceNumber: trimmedNumber,
                    title: trimmedTitle,
                    clientName: trimmedClient,
                    category: category,
                    issueDate: issueDate,
                    dueDate: dueDate,
                    amount: amountValue,
                    taxPercentage: taxValue,
                    notes: trimmedNotes,
                    status: storedStatus
                )
                try storageService.addInvoice(newInvoice)
                successMessage = "Invoice \(trimmedNumber) saved successfully."
            }

            validationErrorMessage = nil
            return true
        } catch {
            validationErrorMessage = error.localizedDescription
            return false
        }
    }

    private static func formatEditableNumber(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        }
        return String(format: "%.2f", value)
    }
}
