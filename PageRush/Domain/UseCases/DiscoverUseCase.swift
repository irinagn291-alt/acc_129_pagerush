import Foundation

struct DiscoverLane: Identifiable, Hashable, Sendable {
    var id: String { title }
    let title: String
    let items: [VolumePreview]
}

enum DiscoverUseCase: Sendable {
    static func loadFeed() async throws -> (daily: [VolumePreview], weekly: [VolumePreview], lanes: [DiscoverLane]) {
        async let daily = ArchiveWire.shared.fetchPulse(window: .daily)
        async let weekly = ArchiveWire.shared.fetchPulse(window: .weekly)
        let themes: [(String, String)] = [
            ("Campus Classics", "college"),
            ("Sci-Fi Sprint", "science_fiction"),
            ("Study Break Reads", "young_adult_fiction"),
            ("Quick Wins", "short_stories")
        ]
        var lanes: [DiscoverLane] = []
        for (title, topic) in themes {
            let works = try await ArchiveWire.shared.fetchTopicShelf(topic: topic, limit: 14)
            lanes.append(DiscoverLane(title: title, items: works))
        }
        return (try await daily, try await weekly, lanes)
    }
}
