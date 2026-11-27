import SwiftUI

/// Service categories supported across invoices and filtering.
enum InvoiceCategory: String, CaseIterable, Codable, Identifiable, Sendable {
    case webDevelopment = "Web Development"
    case design = "Design"
    case consulting = "Consulting"
    case writing = "Writing"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .webDevelopment:
            return "chevron.left.forwardslash.chevron.right"
        case .design:
            return "paintbrush.pointed.fill"
        case .consulting:
            return "briefcase.fill"
        case .writing:
            return "doc.text.fill"
        }
    }

    var badgeColor: Color {
        switch self {
        case .webDevelopment:
            return AppTheme.secondaryPurple
        case .design:
            return Color(red: 0.85, green: 0.27, blue: 0.56)
        case .consulting:
            return AppTheme.primaryNavy
        case .writing:
            return Color(red: 0.05, green: 0.55, blue: 0.62)
        }
    }
}
