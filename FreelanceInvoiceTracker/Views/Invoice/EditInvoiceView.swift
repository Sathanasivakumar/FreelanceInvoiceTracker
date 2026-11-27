import SwiftUI

/// Screen for editing an existing invoice while preserving its unique identifier.
struct EditInvoiceView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: AddInvoiceViewModel
    @State private var isShowingSavedAlert: Bool = false

    init(invoice: Invoice, storageService: InvoiceStorageService) {
        self._viewModel = State(
            initialValue: AddInvoiceViewModel(
                storageService: storageService,
                editingInvoice: invoice
            )
        )
    }

    var body: some View {
        NavigationStack {
            InvoiceFormContentView(viewModel: viewModel)
                .navigationTitle("Edit Invoice")
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
                                isShowingSavedAlert = true
                            }
                        }
                        .fontWeight(.semibold)
                    }
                }
                .alert("Changes Saved", isPresented: $isShowingSavedAlert) {
                    Button("Done") {
                        dismiss()
                    }
                } message: {
                    Text(viewModel.successMessage ?? "Invoice updated successfully.")
                }
        }
    }
}
