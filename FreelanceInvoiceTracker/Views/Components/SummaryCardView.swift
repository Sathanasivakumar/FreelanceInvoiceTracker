import SwiftUI

/// Financial summary KPI card with SF Symbol icon badge and soft card styling.
struct SummaryCardView: View {
    let title: String
    let value: String
    let subtitle: String?
    let systemImage: String
    let tintColor: Color

    init(
        title: String,
        value: String,
        subtitle: String? = nil,
        systemImage: String,
        tintColor: Color
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.tintColor = tintColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(tintColor.opacity(0.14))
                    .frame(width: 36, height: 36)
                    .overlay {
                        Image(systemName: systemImage)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(tintColor)
                    }

                Spacer()
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(tintColor)
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        }
        .shadow(color: AppTheme.primaryNavy.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}
