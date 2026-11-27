import Foundation

/// Centralized date formatting and greeting helpers with cached formatters.
enum DateFormatterHelper {
    private static let mediumFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private static let shortFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }()

    private static let headerFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d, yyyy"
        return formatter
    }()

    static func formatMedium(_ date: Date) -> String {
        mediumFormatter.string(from: date)
    }

    static func formatShort(_ date: Date) -> String {
        shortFormatter.string(from: date)
    }

    static func formatHeaderDate(_ date: Date = Date()) -> String {
        headerFormatter.string(from: date)
    }

    static func greeting(for date: Date = Date(), calendar: Calendar = .current) -> String {
        let hour = calendar.component(.hour, from: date)
        switch hour {
        case 5..<12:
            return "Good Morning"
        case 12..<17:
            return "Good Afternoon"
        case 17..<22:
            return "Good Evening"
        default:
            return "Welcome Back"
        }
    }
}
