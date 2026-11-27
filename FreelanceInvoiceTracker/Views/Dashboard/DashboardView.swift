import SwiftUI

/// Home dashboard displaying financial KPIs, quick actions, and recently added invoices.
struct DashboardView: View {
    let storageService: InvoiceStorageService
    @State private var viewModel: DashboardViewModel
    @State private var isShowingAddInvoice: Bool = false
    var onViewAllInvoices: () -> Void

    init(
        storageService: InvoiceStorageService,
        onViewAllInvoices: @escaping () -> Void
    ) {
        self.storageService = storageService
        self._viewModel = State(initialValue: DashboardViewModel(storageService: storageService))
        self.onViewAllInvoices = onViewAllInvoices
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                heroHeaderCard
                summaryGrid
                quickActionsSection
                recentInvoicesSection
            }
            .padding(.horizontal, AppTheme.horizontalPadding)
            .padding(.top, 10)
            .padding(.bottom, 28)
        }
        .background(AppTheme.appBackground.ignoresSafeArea())
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingAddInvoice) {
            AddInvoiceView(storageService: storageService)
        }
    }

    private var heroHeaderCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.greetingMessage)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(viewModel.currentDateText)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.82))
                }

                Spacer()

                Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(AppTheme.accentGreen)
                    .background(Circle().fill(Color.white.opacity(0.15)))
            }

            Divider()
                .overlay(Color.white.opacity(0.2))

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Pending Amount")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.78))

                    Text(viewModel.formattedTotalPendingAmount)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Collected")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.78))

                    Text(viewModel.formattedTotalPaidAmount)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color(red: 0.56, green: 0.96, blue: 0.72))
                }
            }
        }
        .padding(20)
        .background(AppTheme.heroGradient)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: AppTheme.primaryNavy.opacity(0.24), radius: 14, x: 0, y: 7)
    }

    private var summaryGrid: some View {
        let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]

        return LazyVGrid(columns: columns, spacing: 12) {
            SummaryCardView(
                title: "Total Invoices",
                value: "\(viewModel.totalInvoicesCount)",
                subtitle: "All recorded",
                systemImage: "doc.on.doc.fill",
                tintColor: AppTheme.primaryNavy
            )

            SummaryCardView(
                title: "Pending Amount",
                value: viewModel.formattedTotalPendingAmount,
                subtitle: "\(viewModel.pendingInvoicesCount + viewModel.overdueInvoicesCount) unpaid",
                systemImage: "hourglass.bottomhalf.filled",
                tintColor: AppTheme.secondaryPurple
            )

            SummaryCardView(
                title: "Paid Invoices",
                value: "\(viewModel.paidInvoicesCount)",
                subtitle: "Completed",
                systemImage: "checkmark.seal.fill",
                tintColor: AppTheme.accentGreen
            )

            SummaryCardView(
                title: "Overdue Invoices",
                value: "\(viewModel.overdueInvoicesCount)",
                subtitle: viewModel.overdueInvoicesCount > 0 ? "Needs attention" : "All on track",
                systemImage: "exclamationmark.triangle.fill",
                tintColor: viewModel.overdueInvoicesCount > 0 ? AppTheme.dangerRed : AppTheme.accentGreen
            )
        }
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            HStack(spacing: 12) {
                Button {
                    isShowingAddInvoice = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Add New Invoice")
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.accentGreen)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: AppTheme.accentGreen.opacity(0.25), radius: 8, x: 0, y: 4)
                }

                Button {
                    onViewAllInvoices()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "list.bullet.rectangle.portrait.fill")
                            .font(.system(size: 17, weight: .semibold))
                        Text("View All Invoices")
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.cardBackground)
                    .foregroundStyle(AppTheme.primaryNavy)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(AppTheme.primaryNavy.opacity(0.22), lineWidth: 1.2)
                    }
                }
            }
        }
    }

    private var recentInvoicesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recently Added Invoices")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)

                Spacer()

                if !viewModel.recentInvoices.isEmpty {
                    Button("See All") {
                        onViewAllInvoices()
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.secondaryPurple)
                }
            }

            if viewModel.recentInvoices.isEmpty {
                EmptyStateView(
                    title: "No Invoices Yet",
                    message: "Create your first freelance invoice to start tracking payments and revenue.",
                    systemImage: "doc.badge.plus",
                    actionTitle: "Add New Invoice"
                ) {
                    isShowingAddInvoice = true
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(viewModel.recentInvoices) { invoice in
                        NavigationLink {
                            InvoiceDetailView(invoiceId: invoice.id, storageService: storageService)
                        } label: {
                            recentInvoiceRow(invoice)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func recentInvoiceRow(_ invoice: Invoice) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(invoice.category.badgeColor.opacity(0.14))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: invoice.category.systemImage)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(invoice.category.badgeColor)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(invoice.clientName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(invoice.invoiceNumber)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.secondaryPurple)
                    Text("•")
                        .foregroundStyle(AppTheme.textSecondary)
                    Text(DateFormatterHelper.formatShort(invoice.issueDate))
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 5) {
                Text(viewModel.formattedAmount(for: invoice))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)

                StatusBadgeView(status: invoice.currentStatus, compact: true)
            }
        }
        .padding(14)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        }
        .shadow(color: AppTheme.primaryNavy.opacity(0.04), radius: 6, x: 0, y: 3)
    }
}
