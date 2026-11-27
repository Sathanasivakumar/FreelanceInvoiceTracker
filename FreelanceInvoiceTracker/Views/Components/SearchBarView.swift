import SwiftUI

/// Styled search input used on the Invoice List screen.
struct SearchBarView: View {
    @Binding var text: String
    var placeholder: String = "Search title, client, or invoice #"

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)

            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textPrimary)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(AppTheme.textSecondary.opacity(0.8))
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius, style: .continuous)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        }
        .shadow(color: AppTheme.primaryNavy.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}
