import Foundation

/// Represents a freelance client associated with invoices.
struct Client: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var name: String
    var company: String
    var email: String

    init(
        id: UUID = UUID(),
        name: String,
        company: String = "",
        email: String = ""
    ) {
        self.id = id
        self.name = name
        self.company = company
        self.email = email
    }
}
