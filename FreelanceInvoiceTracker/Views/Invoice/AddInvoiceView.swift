import SwiftUI

/// Screen for creating and validating a new freelance invoice.
struct AddInvoiceView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: AddInvoiceViewModel
    @State private var isShowingSuccessAlert: Bool = false

    init(storageService: InvoiceStorageService) {
        self._viewModel = State(initialValue: AddInvoiceViewModel(storageService: storageService))
    }

    var body: some View {
        NavigationStack {
            InvoiceFormContentView(viewModel: viewModel)
                .navigationTitle("New Invoice")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            if viewModel.saveInvoice() {
                                isShowingSuccessAlert = true
                            }
                        }
                        .fontWeight(.semibold)
                    }
                }
                .alert("Invoice Saved", isPresented: $isShowingSuccessAlert) {
                    Button("Done") {
                        dismiss()
                    }
                } message: {
                    Text(viewModel.successMessage ?? "Your invoice has been saved locally.")
                }
        }
    }
}

/// Shared form body used by both AddInvoiceView and EditInvoiceView to prevent duplicate UI code.
struct InvoiceFormContentView: View {
    @Bindable var viewModel: AddInvoiceViewModel

    var body: some View {
        Form {
            if let errorMessage = viewModel.validationErrorMessage {
                Section {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(AppTheme.dangerRed)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.dangerRed)
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("Invoice Details") {
                TextField("Invoice Title (e.g., Website Redesign)", text: $viewModel.title)
                TextField("Client Name", text: $viewModel.clientName)
                TextField("Invoice Number (e.g., INV-1005)", text: $viewModel.invoiceNumber)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled(true)

                Picker("Service Category", selection: $viewModel.category) {
                    ForEach(InvoiceCategory.allCases) { category in
                        Label(category.rawValue, systemImage: category.systemImage)
                            .tag(category)
                    }
                }
            }

            Section("Schedule") {
                DatePicker("Issue Date", selection: $viewModel.issueDate, displayedComponents: .date)
                DatePicker("Due Date", selection: $viewModel.dueDate, displayedComponents: .date)
            }

            Section("Billing & Status") {
                HStack {
                    Text("Amount (\(viewModel.selectedCurrency.symbol))")
                    Spacer()
                    TextField("0.00", text: $viewModel.amountText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }

                HStack {
                    Text("Tax Percentage (%)")
                    Spacer()
                    TextField("Optional (e.g., 10)", text: $viewModel.taxPercentageText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }

                Picker("Payment Status", selection: $viewModel.status) {
                    Text(PaymentStatus.pending.rawValue).tag(PaymentStatus.pending)
                    Text(PaymentStatus.paid.rawValue).tag(PaymentStatus.paid)
                }
                .pickerStyle(.segmented)

                HStack {
                    Text("Effective Status")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                    Spacer()
                    StatusBadgeView(status: viewModel.effectiveStatusPreview, compact: true)
                }

                HStack {
                    Text("Calculated Total")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(viewModel.formattedTotalPreview)
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryNavy)
                }
            }

            Section("Notes") {
                TextEditor(text: $viewModel.notes)
                    .frame(minHeight: 100)
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }
}
