import SwiftUI

/// Color-coded payment status pill (Paid: Green, Pending: Orange, Overdue: Red).
struct StatusBadgeView: View {
    let status: PaymentStatus
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: status.systemImage)
                .font(.system(size: compact ? 10 : 11, weight: .semibold))
            Text(status.rawValue)
                .font(.system(size: compact ? 11 : 12, weight: .semibold))
        }
        .foregroundStyle(status.color)
        .padding(.horizontal, compact ? 8 : 10)
        .padding(.vertical, compact ? 4 : 5)
        .background(status.color.opacity(0.13))
        .clipShape(Capsule())
    }
}
