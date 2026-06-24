import Foundation

enum QueryChannel: String, CaseIterable, Identifiable, Sendable {
    case everything
    case title
    case author
    case topic
    case isbn

    var id: String { rawValue }

    var label: String {
        switch self {
        case .everything: "All"
        case .title: "Title"
        case .author: "Author"
        case .topic: "Topic"
        case .isbn: "ISBN"
        }
    }
}
