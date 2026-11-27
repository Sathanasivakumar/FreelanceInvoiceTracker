import SwiftUI

/// Reusable brand emblem combining an invoice document and currency badge in Navy, Purple, and Green.
struct BrandLogoView: View {
    var size: CGFloat = 84

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .fill(AppTheme.heroGradient)
                .frame(width: size, height: size)
                .shadow(color: AppTheme.primaryNavy.opacity(0.28), radius: size * 0.16, x: 0, y: size * 0.08)
                .overlay {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: size * 0.44, weight: .semibold))
                        .foregroundStyle(.white)
                        .offset(x: -size * 0.05, y: -size * 0.03)
                }

            Circle()
                .fill(
                    LinearGradient(
                        colors: [AppTheme.secondaryPurple, AppTheme.accentGreen],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.38, height: size * 0.38)
                .overlay {
                    Circle()
                        .stroke(AppTheme.primaryNavy, lineWidth: max(2, size * 0.03))
                }
                .overlay {
                    Image(systemName: "dollarsign")
                        .font(.system(size: size * 0.19, weight: .bold))
                        .foregroundStyle(.white)
                }
                .offset(x: size * 0.06, y: size * 0.06)
        }
    }
}
