import SwiftUI

/// Reusable empty state card shown when no invoices exist or match active filters.
struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 14) {
            Circle()
                .fill(AppTheme.secondaryPurple.opacity(0.12))
                .frame(width: 68, height: 68)
                .overlay {
                    Image(systemName: systemImage)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(AppTheme.secondaryPurple)
                }

            VStack(spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(AppTheme.secondaryPurple)
                        .clipShape(Capsule())
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 24)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        }
    }
}
