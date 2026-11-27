import SwiftUI

/// Card component displaying complete invoice summary metadata in the Invoice List.
struct InvoiceCardView: View {
    let invoice: Invoice
    let formattedAmount: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Text(invoice.invoiceNumber)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.secondaryPurple)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(AppTheme.secondaryPurple.opacity(0.11))
                    .clipShape(Capsule())

                HStack(spacing: 4) {
                    Image(systemName: invoice.category.systemImage)
                        .font(.caption2)
                    Text(invoice.category.rawValue)
                        .font(.caption.weight(.medium))
                }
                .foregroundStyle(invoice.category.badgeColor)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(invoice.category.badgeColor.opacity(0.11))
                .clipShape(Capsule())

                Spacer()

                StatusBadgeView(status: invoice.currentStatus, compact: true)
            }

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(invoice.title)
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(2)

                    Label(invoice.clientName, systemImage: "building.2.fill")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                Text(formattedAmount)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryNavy)
            }

            Divider()
                .overlay(AppTheme.cardBorder)

            HStack {
                Label("Issued: \(DateFormatterHelper.formatShort(invoice.issueDate))", systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)

                Spacer()

                Label("Due: \(DateFormatterHelper.formatShort(invoice.dueDate))", systemImage: "clock")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(invoice.currentStatus == .overdue ? AppTheme.dangerRed : AppTheme.textSecondary)
            }
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        }
        .shadow(color: AppTheme.primaryNavy.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}
