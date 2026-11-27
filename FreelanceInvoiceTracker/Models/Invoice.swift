import Foundation
import SwiftUI

/// Payment status of an invoice.
enum PaymentStatus: String, CaseIterable, Codable, Identifiable, Sendable {
    case paid = "Paid"
    case pending = "Pending"
    case overdue = "Overdue"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .paid:
            return "checkmark.circle.fill"
        case .pending:
            return "clock.fill"
        case .overdue:
            return "exclamationmark.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .paid:
            return AppTheme.accentGreen
        case .pending:
            return AppTheme.warningOrange
        case .overdue:
            return AppTheme.dangerRed
        }
    }
}

/// Core freelance invoice model persisted locally.
struct Invoice: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var invoiceNumber: String
    var title: String
    var clientName: String
    var category: InvoiceCategory
    var issueDate: Date
    var dueDate: Date
    var amount: Double
    var taxPercentage: Double
    var notes: String
    var status: PaymentStatus
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        invoiceNumber: String,
        title: String,
        clientName: String,
        category: InvoiceCategory,
        issueDate: Date,
        dueDate: Date,
        amount: Double,
        taxPercentage: Double = 0,
        notes: String = "",
        status: PaymentStatus = .pending,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.invoiceNumber = invoiceNumber
        self.title = title
        self.clientName = clientName
        self.category = category
        self.issueDate = issueDate
        self.dueDate = dueDate
        self.amount = amount
        self.taxPercentage = taxPercentage
        self.notes = notes
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Tax amount calculated from the base invoice amount and tax percentage.
    var taxAmount: Double {
        max(0, amount) * max(0, taxPercentage) / 100.0
    }

    /// Total payable amount including tax.
    var totalAmount: Double {
        max(0, amount) + taxAmount
    }

    /// Computes effective payment status using business rules:
    /// - Paid invoices stay Paid.
    /// - Unpaid invoices with a due date before the current day become Overdue.
    /// - Otherwise status is Pending.
    func effectiveStatus(referenceDate: Date = Date(), calendar: Calendar = .current) -> PaymentStatus {
        if status == .paid {
            return .paid
        }
        let dueDay = calendar.startOfDay(for: dueDate)
        let currentDay = calendar.startOfDay(for: referenceDate)
        if dueDay < currentDay {
            return .overdue
        }
        return .pending
    }

    var currentStatus: PaymentStatus {
        effectiveStatus()
    }
}
