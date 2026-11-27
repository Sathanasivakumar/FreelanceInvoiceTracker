import Foundation
import XCTest
@testable import FreelanceInvoiceTracker

@MainActor
final class FreelanceInvoiceTrackerTests: XCTestCase {
    private var tempDirectory: URL!
    private var userDefaults: UserDefaults!
    private var suiteName: String!

    override func setUpWithError() throws {
        suiteName = "fit.tests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FITTests_\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let suiteName {
            UserDefaults.standard.removePersistentDomain(forName: suiteName)
        }
        if let tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
    }

    private func makeStorage(seedSampleData: Bool = false) -> InvoiceStorageService {
        let storageURL = tempDirectory.appendingPathComponent("invoices.json")
        return InvoiceStorageService(
            storageURL: storageURL,
            userDefaults: userDefaults,
            seedSampleDataIfFirstLaunch: seedSampleData
        )
    }

    private func makeInvoice(
        id: UUID = UUID(),
        number: String = "INV-2001",
        title: String = "iOS App Sprint",
        client: String = "Acme Corp",
        category: InvoiceCategory = .webDevelopment,
        issueOffsetDays: Int = -5,
        dueOffsetDays: Int = 5,
        amount: Double = 1000,
        taxPercentage: Double = 10,
        status: PaymentStatus = .pending
    ) -> Invoice {
        let calendar = Calendar.current
        let today = Date()
        let issueDate = calendar.date(byAdding: .day, value: issueOffsetDays, to: today) ?? today
        let dueDate = calendar.date(byAdding: .day, value: dueOffsetDays, to: today) ?? today
        return Invoice(
            id: id,
            invoiceNumber: number,
            title: title,
            clientName: client,
            category: category,
            issueDate: issueDate,
            dueDate: dueDate,
            amount: amount,
            taxPercentage: taxPercentage,
            notes: "Test invoice notes",
            status: status
        )
    }

    func testPaymentStatusCalculations() {
        let paidPastDue = makeInvoice(issueOffsetDays: -15, dueOffsetDays: -3, status: .paid)
        XCTAssertEqual(paidPastDue.currentStatus, .paid)

        let unpaidPastDue = makeInvoice(issueOffsetDays: -15, dueOffsetDays: -1, status: .pending)
        XCTAssertEqual(unpaidPastDue.currentStatus, .overdue)

        let unpaidFutureDue = makeInvoice(issueOffsetDays: -2, dueOffsetDays: 7, status: .pending)
        XCTAssertEqual(unpaidFutureDue.currentStatus, .pending)

        let unpaidDueToday = makeInvoice(issueOffsetDays: -2, dueOffsetDays: 0, status: .pending)
        XCTAssertEqual(unpaidDueToday.currentStatus, .pending)
    }

    func testPersistenceAcrossReloadAndDeleteSampleData() throws {
        let firstLaunchStorage = makeStorage(seedSampleData: true)
        XCTAssertEqual(firstLaunchStorage.invoices.count, 4)

        // Delete all sample invoices
        for invoice in firstLaunchStorage.invoices {
            try firstLaunchStorage.deleteInvoice(id: invoice.id)
        }
        XCTAssertTrue(firstLaunchStorage.invoices.isEmpty)

        // Reopen app storage: deleted sample invoices must NOT come back
        let secondLaunchStorage = makeStorage(seedSampleData: true)
        XCTAssertTrue(secondLaunchStorage.invoices.isEmpty)

        // Add a new invoice and verify it persists across reload
        let custom = makeInvoice(number: "INV-9001", title: "Custom API Work", amount: 1500, taxPercentage: 10)
        try secondLaunchStorage.addInvoice(custom)

        let thirdLaunchStorage = makeStorage(seedSampleData: true)
        XCTAssertEqual(thirdLaunchStorage.invoices.count, 1)
        XCTAssertEqual(thirdLaunchStorage.invoices.first?.id, custom.id)
        XCTAssertEqual(thirdLaunchStorage.invoices.first?.totalAmount, 1650)
    }

    func testEditPreservesIDAndRejectsDuplicateInvoiceNumbers() throws {
        let storage = makeStorage()
        let first = makeInvoice(number: "INV-101", title: "Alpha")
        let second = makeInvoice(number: "INV-102", title: "Beta")
        try storage.addInvoice(first)
        try storage.addInvoice(second)

        XCTAssertThrowsError(try storage.addInvoice(makeInvoice(number: "inv-101")))

        let editVM = AddInvoiceViewModel(storageService: storage, editingInvoice: first)
        editVM.title = "Alpha Updated"
        editVM.amountText = "2200"
        editVM.taxPercentageText = "5"
        XCTAssertTrue(editVM.saveInvoice())

        let updated = storage.invoice(withId: first.id)
        XCTAssertEqual(updated?.id, first.id)
        XCTAssertEqual(updated?.title, "Alpha Updated")
        XCTAssertEqual(updated?.totalAmount, 2310)
    }

    func testAddInvoiceValidationRules() throws {
        let storage = makeStorage()
        try storage.addInvoice(makeInvoice(number: "INV-500"))

        let vm = AddInvoiceViewModel(storageService: storage)
        vm.title = ""
        vm.clientName = "Client"
        vm.invoiceNumber = "INV-501"
        vm.amountText = "100"
        XCTAssertFalse(vm.saveInvoice())
        XCTAssertNotNil(vm.validationErrorMessage)

        vm.title = "Valid Title"
        vm.amountText = "0"
        XCTAssertFalse(vm.saveInvoice())

        vm.amountText = "500"
        vm.invoiceNumber = "INV-500" // Duplicate
        XCTAssertFalse(vm.saveInvoice())

        vm.invoiceNumber = "INV-501"
        vm.dueDate = Calendar.current.date(byAdding: .day, value: -1, to: vm.issueDate) ?? vm.issueDate
        XCTAssertFalse(vm.saveInvoice())

        vm.dueDate = Calendar.current.date(byAdding: .day, value: 7, to: vm.issueDate) ?? vm.issueDate
        XCTAssertTrue(vm.saveInvoice())
        XCTAssertEqual(storage.invoices.count, 2)
    }

    func testSearchAndFilterCombined() throws {
        let storage = makeStorage()
        try storage.addInvoice(makeInvoice(number: "INV-10", title: "Web Portal", client: "Northstar", category: .webDevelopment, dueOffsetDays: 5, status: .pending))
        try storage.addInvoice(makeInvoice(number: "INV-11", title: "Brand Kit", client: "Northstar", category: .design, dueOffsetDays: -2, status: .pending))
        try storage.addInvoice(makeInvoice(number: "INV-12", title: "SEO Copy", client: "Beacon", category: .writing, dueOffsetDays: -5, status: .paid))

        let listVM = InvoiceListViewModel(storageService: storage)
        XCTAssertEqual(listVM.filteredInvoices.count, 3)

        listVM.searchText = "Northstar"
        XCTAssertEqual(listVM.filteredInvoices.count, 2)

        listVM.selectedCategory = .design
        listVM.selectedStatus = .overdue
        XCTAssertEqual(listVM.filteredInvoices.count, 1)
        XCTAssertEqual(listVM.filteredInvoices.first?.invoiceNumber, "INV-11")

        listVM.clearFilters()
        XCTAssertEqual(listVM.filteredInvoices.count, 3)
    }

    func testDashboardStatisticsUpdateAutomatically() throws {
        let storage = makeStorage()
        let dashboardVM = DashboardViewModel(storageService: storage)

        let inv1 = makeInvoice(number: "INV-1", dueOffsetDays: 5, amount: 1000, taxPercentage: 0, status: .pending)
        let inv2 = makeInvoice(number: "INV-2", dueOffsetDays: -3, amount: 500, taxPercentage: 0, status: .pending)
        let inv3 = makeInvoice(number: "INV-3", dueOffsetDays: -1, amount: 800, taxPercentage: 0, status: .paid)
        try storage.addInvoice(inv1)
        try storage.addInvoice(inv2)
        try storage.addInvoice(inv3)

        XCTAssertEqual(dashboardVM.totalInvoicesCount, 3)
        XCTAssertEqual(dashboardVM.paidInvoicesCount, 1)
        XCTAssertEqual(dashboardVM.overdueInvoicesCount, 1)
        XCTAssertEqual(dashboardVM.totalPendingAmount, 1500)

        try storage.markAsPaid(id: inv2.id)
        XCTAssertEqual(dashboardVM.paidInvoicesCount, 2)
        XCTAssertEqual(dashboardVM.overdueInvoicesCount, 0)
        XCTAssertEqual(dashboardVM.totalPendingAmount, 1000)

        try storage.deleteInvoice(id: inv1.id)
        XCTAssertEqual(dashboardVM.totalInvoicesCount, 2)
        XCTAssertEqual(dashboardVM.totalPendingAmount, 0)
    }

    func testLocalAuthNeverStoresPlaintextPasswordAndHandlesBiometricFallback() async {
        let storage = makeStorage()
        let mockAuth = MockBiometricAuthService(
            availability: BiometricAvailability(isAvailable: false, type: .faceID, unavailableReason: "Face ID unavailable"),
            biometricResult: .failure(.biometricUnavailable("Face ID unavailable")),
            underlying: BiometricAuthService(userDefaults: userDefaults)
        )

        let authVM = AuthenticationViewModel(authService: mockAuth, storageService: storage)
        await authVM.startAppFlow(splashDelayNanoseconds: 0)
        XCTAssertEqual(authVM.currentStep, .manualLogin)

        // Register local demo credentials
        authVM.username = "alexdev"
        authVM.passcode = "Secure99"
        authVM.submitManualLogin()
        XCTAssertEqual(authVM.currentStep, .authenticated)

        // Verify password is never stored in plain text in UserDefaults
        let dict = userDefaults.dictionaryRepresentation()
        for (_, value) in dict {
            if let str = value as? String {
                XCTAssertFalse(str.contains("Secure99"))
            }
        }

        // Logout and verify wrong passcode fails, right passcode succeeds
        authVM.logout()
        XCTAssertEqual(authVM.currentStep, .manualLogin)

        authVM.passcode = "WrongPass"
        authVM.submitManualLogin()
        XCTAssertEqual(authVM.currentStep, .manualLogin)
        XCTAssertNotNil(authVM.errorMessage)

        authVM.retryManualLogin()
        authVM.passcode = "Secure99"
        authVM.submitManualLogin()
        XCTAssertEqual(authVM.currentStep, .authenticated)
    }
}

private final class MockBiometricAuthService: BiometricAuthenticating, @unchecked Sendable {
    private let availability: BiometricAvailability
    private let biometricResult: Result<Void, AuthenticationError>
    private let underlying: BiometricAuthService

    init(
        availability: BiometricAvailability,
        biometricResult: Result<Void, AuthenticationError>,
        underlying: BiometricAuthService
    ) {
        self.availability = availability
        self.biometricResult = biometricResult
        self.underlying = underlying
    }

    func checkBiometricAvailability() -> BiometricAvailability {
        availability
    }

    func authenticateWithBiometrics(reason: String) async -> Result<Void, AuthenticationError> {
        biometricResult
    }

    var hasLocalCredentials: Bool { underlying.hasLocalCredentials }
    var storedUsername: String? { underlying.storedUsername }

    func registerLocalCredentials(username: String, passcode: String) throws {
        try underlying.registerLocalCredentials(username: username, passcode: passcode)
    }

    func verifyLocalCredentials(username: String, passcode: String) -> Result<Void, AuthenticationError> {
        underlying.verifyLocalCredentials(username: username, passcode: passcode)
    }
}
