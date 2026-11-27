import SwiftUI

/// Detailed breakdown view for a single invoice with Edit, Delete, and Mark as Paid actions.
struct InvoiceDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let storageService: InvoiceStorageService
    @State private var viewModel: InvoiceDetailViewModel

    init(invoiceId: UUID, storageService: InvoiceStorageService) {
        self.storageService = storageService
        self._viewModel = State(
            initialValue: InvoiceDetailViewModel(
                invoiceId: invoiceId,
                storageService: storageService
            )
        )
    }

    var body: some View {
        Group {
            if let invoice = viewModel.invoice {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        headerCard(invoice)

                        if let statusMessage = viewModel.statusMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppTheme.accentGreen)
                                Text(statusMessage)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(AppTheme.accentGreen)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppTheme.accentGreen.opacity(0.11))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }

                        if let errorMessage = viewModel.actionErrorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(AppTheme.dangerRed)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(AppTheme.dangerRed.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }

                        infoCard(invoice)
                        amountBreakdownCard(invoice)
                        notesCard(invoice)
                        actionButtons(invoice)
                    }
                    .padding(.horizontal, AppTheme.horizontalPadding)
                    .padding(.vertical, 14)
                }
                .background(AppTheme.appBackground.ignoresSafeArea())
                .sheet(isPresented: $viewModel.isShowingEditSheet) {
                    EditInvoiceView(invoice: invoice, storageService: storageService)
                }
                .alert("Delete Invoice?", isPresented: $viewModel.isShowingDeleteAlert) {
                    Button("Cancel", role: .cancel) {}
                    Button("Delete", role: .destructive) {
                        if viewModel.confirmDelete() {
                            dismiss()
                        }
                    }
                } message: {
                    Text("Are you sure you want to permanently delete \(invoice.invoiceNumber) (\(invoice.title))? This action cannot be undone.")
                }
            } else {
                EmptyStateView(
                    title: "Invoice Unavailable",
                    message: "This invoice was deleted or is no longer available.",
                    systemImage: "doc.questionmark"
                )
                .padding()
            }
        }
        .navigationTitle("Invoice Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func headerCard(_ invoice: Invoice) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(invoice.invoiceNumber)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.18))
                    .clipShape(Capsule())

                Spacer()

                StatusBadgeView(status: invoice.currentStatus)
                    .background(Color.white)
                    .clipShape(Capsule())
            }

            Text(invoice.title)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)

            HStack {
                Label(invoice.clientName, systemImage: "building.2.fill")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.88))

                Spacer()

                Text(viewModel.formattedTotalAmount(invoice))
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
            }
        }
        .padding(20)
        .background(AppTheme.heroGradient)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: AppTheme.primaryNavy.opacity(0.22), radius: 12, x: 0, y: 6)
    }

    private func infoCard(_ invoice: Invoice) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Summary")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            detailRow(label: "Invoice Number", value: invoice.invoiceNumber)
            detailRow(label: "Client", value: invoice.clientName)
            detailRow(label: "Service Category", value: invoice.category.rawValue)
            detailRow(label: "Issue Date", value: DateFormatterHelper.formatMedium(invoice.issueDate))
            detailRow(label: "Due Date", value: DateFormatterHelper.formatMedium(invoice.dueDate))
            detailRow(label: "Payment Status", value: invoice.currentStatus.rawValue)
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        }
    }

    private func amountBreakdownCard(_ invoice: Invoice) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Financial Breakdown")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            detailRow(label: "Base Amount", value: viewModel.formattedBaseAmount(invoice))
            detailRow(
                label: "Tax (\(String(format: "%.1f", invoice.taxPercentage))%)",
                value: viewModel.formattedTaxAmount(invoice)
            )

            Divider()

            HStack {
                Text("Total Amount")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Text(viewModel.formattedTotalAmount(invoice))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.primaryNavy)
            }
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        }
    }

    private func notesCard(_ invoice: Invoice) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            Text(invoice.notes.isEmpty ? "No notes added for this invoice." : invoice.notes)
                .font(.subheadline)
                .foregroundStyle(invoice.notes.isEmpty ? AppTheme.textSecondary : AppTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        }
    }

    private func actionButtons(_ invoice: Invoice) -> some View {
        VStack(spacing: 12) {
            if invoice.currentStatus != .paid {
                Button {
                    viewModel.markAsPaid()
                } label: {
                    Label("Mark as Paid", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.accentGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }

            HStack(spacing: 12) {
                Button {
                    viewModel.isShowingEditSheet = true
                } label: {
                    Label("Edit Invoice", systemImage: "pencil")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryNavy)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(AppTheme.primaryNavy.opacity(0.25), lineWidth: 1.2)
                        }
                }

                Button(role: .destructive) {
                    viewModel.isShowingDeleteAlert = true
                } label: {
                    Label("Delete Invoice", systemImage: "trash.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.dangerRed)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.dangerRed.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(AppTheme.dangerRed.opacity(0.25), lineWidth: 1.2)
                        }
                }
            }
        }
        .padding(.top, 4)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .multilineTextAlignment(.trailing)
        }
    }
}
