import Foundation

enum MilestoneStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case queued
    case inProgress
    case crushed
    case dropped

    var id: String { rawValue }

    var title: String {
        switch self {
        case .queued: "Want to Read"
        case .inProgress: "Reading Now"
        case .crushed: "Finished"
        case .dropped: "Dropped"
        }
    }

    var icon: String {
        switch self {
        case .queued: "bookmark.fill"
        case .inProgress: "bolt.fill"
        case .crushed: "checkmark.seal.fill"
        case .dropped: "xmark.circle.fill"
        }
    }
}
