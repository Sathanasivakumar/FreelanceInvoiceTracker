import SwiftUI

/// Searchable, filterable list of invoices with a floating Add Invoice button.
struct InvoiceListView: View {
    let storageService: InvoiceStorageService
    @State private var viewModel: InvoiceListViewModel
    @State private var isShowingAddInvoice: Bool = false

    init(storageService: InvoiceStorageService) {
        self.storageService = storageService
        self._viewModel = State(initialValue: InvoiceListViewModel(storageService: storageService))
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    SearchBarView(text: $viewModel.searchText)

                    categoryFilterRow
                    statusFilterRow

                    if let errorMessage = viewModel.actionErrorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(AppTheme.dangerRed)
                            .padding(.horizontal, 4)
                    }

                    if viewModel.filteredInvoices.isEmpty {
                        emptyStateSection
                            .padding(.top, 16)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.filteredInvoices) { invoice in
                                NavigationLink {
                                    InvoiceDetailView(invoiceId: invoice.id, storageService: storageService)
                                } label: {
                                    InvoiceCardView(
                                        invoice: invoice,
                                        formattedAmount: viewModel.formattedAmount(for: invoice)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, AppTheme.horizontalPadding)
                .padding(.top, 10)
                .padding(.bottom, 92)
            }
            .background(AppTheme.appBackground.ignoresSafeArea())

            floatingAddButton
                .padding(.trailing, 20)
                .padding(.bottom, 20)
        }
        .navigationTitle("Invoices")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingAddInvoice) {
            AddInvoiceView(storageService: storageService)
        }
    }

    private var categoryFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(
                    title: "All Categories",
                    isSelected: viewModel.selectedCategory == nil,
                    activeColor: AppTheme.primaryNavy
                ) {
                    viewModel.selectedCategory = nil
                }

                ForEach(InvoiceCategory.allCases) { category in
                    filterChip(
                        title: category.rawValue,
                        isSelected: viewModel.selectedCategory == category,
                        activeColor: category.badgeColor
                    ) {
                        viewModel.selectedCategory = (viewModel.selectedCategory == category) ? nil : category
                    }
                }
            }
        }
    }

    private var statusFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(
                    title: "All Statuses",
                    isSelected: viewModel.selectedStatus == nil,
                    activeColor: AppTheme.secondaryPurple
                ) {
                    viewModel.selectedStatus = nil
                }

                ForEach(PaymentStatus.allCases) { status in
                    filterChip(
                        title: status.rawValue,
                        isSelected: viewModel.selectedStatus == status,
                        activeColor: status.color
                    ) {
                        viewModel.selectedStatus = (viewModel.selectedStatus == status) ? nil : status
                    }
                }
            }
        }
    }

    private func filterChip(
        title: String,
        isSelected: Bool,
        activeColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? .white : AppTheme.textSecondary)
                .padding(.horizontal, 13)
                .padding(.vertical, 8)
                .background(isSelected ? activeColor : AppTheme.cardBackground)
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .stroke(isSelected ? activeColor : AppTheme.cardBorder, lineWidth: 1)
                }
        }
    }

    @ViewBuilder
    private var emptyStateSection: some View {
        if viewModel.totalInvoicesCount == 0 {
            EmptyStateView(
                title: "No Invoices Stored",
                message: "Tap the + button to create your first client invoice.",
                systemImage: "doc.text.magnifyingglass",
                actionTitle: "Add Invoice"
            ) {
                isShowingAddInvoice = true
            }
        } else {
            EmptyStateView(
                title: "No Matching Invoices",
                message: "No invoices match your search query or selected category and status filters.",
                systemImage: "line.3.horizontal.decrease.circle",
                actionTitle: "Clear Filters"
            ) {
                viewModel.clearFilters()
            }
        }
    }

    private var floatingAddButton: some View {
        Button {
            isShowingAddInvoice = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(AppTheme.heroGradient)
                .clipShape(Circle())
                .shadow(color: AppTheme.secondaryPurple.opacity(0.38), radius: 12, x: 0, y: 6)
        }
        .accessibilityLabel("Add New Invoice")
    }
}
