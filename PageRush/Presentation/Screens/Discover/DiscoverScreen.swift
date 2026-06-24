import SwiftUI

struct DiscoverScreen: View {
    @StateObject private var viewModel = DiscoverViewModel()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                PageRushPalette.canvas
                    .ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        heroHeader
                        RushBadge(text: "Discover")
                            .padding(.horizontal)

                        if let errorText = viewModel.errorText {
                            Text(errorText)
                                .font(.footnote)
                                .foregroundStyle(PageRushPalette.primary)
                                .padding(.horizontal)
                        }

                        if viewModel.isLoading && viewModel.lanes.isEmpty {
                            ProgressView()
                                .tint(PageRushPalette.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 40)
                        }

                        carouselSection(title: "Trending Today", items: viewModel.dailyPulse)
                        carouselSection(title: "Trending This Week", items: viewModel.weeklyPulse)

                        ForEach(viewModel.lanes) { lane in
                            carouselSection(title: lane.title, items: lane.items)
                        }

                        spotlightAuthors
                    }
                    .padding(.vertical, 12)
                }
            }
            .navigationTitle("Discover")
            .navigationDestination(for: VolumePreview.self) { preview in
                VolumeDetailScreen(preview: preview)
            }
            .navigationDestination(for: String.self) { query in
                AuthorSpotlightScreen(initialQuery: query)
            }
            .task { await viewModel.load() }
        }
    }

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your next page-turner")
                .font(PageRushPalette.rounded(.title2))
                .foregroundStyle(PageRushPalette.ink)
            Text("Swipe fast through trending reads, campus picks, and sprint-worthy titles.")
                .font(.footnote)
                .foregroundStyle(PageRushPalette.ink.opacity(0.65))
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var spotlightAuthors: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Authors on fire")
                .font(PageRushPalette.rounded(.title3))
                .foregroundStyle(PageRushPalette.ink)
                .padding(.horizontal)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(SpotlightRoster.picks) { author in
                    NavigationLink(value: author.searchQuery) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(author.displayName)
                                .font(.headline)
                                .foregroundStyle(PageRushPalette.ink)
                            Text(author.vibe)
                                .font(.caption)
                                .foregroundStyle(PageRushPalette.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: PageRushPalette.radiusCard, style: .continuous)
                                .fill(PageRushPalette.surface)
                                .shadow(color: PageRushPalette.ink.opacity(0.08), radius: 8, y: 4)
                        )
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private func carouselSection(title: String, items: [VolumePreview]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(PageRushPalette.rounded(.title3))
                .foregroundStyle(PageRushPalette.ink)
                .padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(items) { item in
                        RushVolumeCard(preview: item, reduceMotion: reduceMotion) {
                            path.append(item)
                        }
                        .frame(width: 198)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct AuthorSpotlightScreen: View {
    let initialQuery: String
    @StateObject private var viewModel = SearchViewModel()

    var body: some View {
        SearchResultsPanel(viewModel: viewModel, lockedChannel: .author, initialQuery: initialQuery)
            .navigationTitle("Author")
            .navigationBarTitleDisplayMode(.inline)
    }
}
