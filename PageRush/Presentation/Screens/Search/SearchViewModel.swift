import Foundation
import SwiftUI

enum QueryRunState: Equatable {
    case idle
    case loading
    case empty
    case results
    case error(String)
}

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var channel: QueryChannel = .everything
    @Published var results: [VolumePreview] = []
    @Published var runState: QueryRunState = .idle

    private var debounceTask: Task<Void, Never>?

    func reset(channel: QueryChannel, query: String) {
        self.channel = channel
        self.query = query
    }

    func scheduleSearch() {
        debounceTask?.cancel()
        let currentQuery = query
        let currentChannel = channel
        if currentQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            results = []
            runState = .idle
            return
        }
        runState = .loading
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 450_000_000)
            guard !Task.isCancelled else { return }
            await runSearch(query: currentQuery, channel: currentChannel)
        }
    }

    func searchNow() async {
        debounceTask?.cancel()
        let currentQuery = query
        let currentChannel = channel
        if currentQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            results = []
            runState = .idle
            return
        }
        runState = .loading
        await runSearch(query: currentQuery, channel: currentChannel)
    }

    private func runSearch(query: String, channel: QueryChannel) async {
        do {
            let found = try await QueryUseCase.search(channel: channel, text: query, limit: 40)
            results = found
            runState = found.isEmpty ? .empty : .results
        } catch {
            runState = .error(error.localizedDescription)
        }
    }
}
