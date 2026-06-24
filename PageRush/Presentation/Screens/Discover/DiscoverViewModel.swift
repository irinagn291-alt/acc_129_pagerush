import Foundation
import SwiftUI

@MainActor
final class DiscoverViewModel: ObservableObject {
    @Published var lanes: [DiscoverLane] = []
    @Published var dailyPulse: [VolumePreview] = []
    @Published var weeklyPulse: [VolumePreview] = []
    @Published var isLoading = false
    @Published var errorText: String?

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorText = nil
        do {
            let feed = try await DiscoverUseCase.loadFeed()
            dailyPulse = feed.daily
            weeklyPulse = feed.weekly
            lanes = feed.lanes
        } catch {
            errorText = error.localizedDescription
        }
        isLoading = false
    }
}
