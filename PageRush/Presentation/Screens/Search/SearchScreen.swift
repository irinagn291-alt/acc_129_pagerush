import SwiftUI

struct SearchScreen: View {
    @StateObject private var viewModel = SearchViewModel()

    var body: some View {
        NavigationStack {
            SearchResultsPanel(viewModel: viewModel, lockedChannel: nil, initialQuery: nil)
                .navigationTitle("Search")
                .navigationDestination(for: VolumePreview.self) { preview in
                    VolumeDetailScreen(preview: preview)
                }
        }
    }
}

struct SearchResultsPanel: View {
    @ObservedObject var viewModel: SearchViewModel
    let lockedChannel: QueryChannel?
    let initialQuery: String?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let grid = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ZStack {
            PageRushPalette.energyGradient
                .ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if lockedChannel == nil {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(QueryChannel.allCases) { channel in
                                    filterPill(channel: channel, selected: viewModel.channel == channel)
                                }
                            }
                        }
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(PageRushPalette.secondary)
                        TextField(placeholder, text: $viewModel.query)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.search)
                            .onSubmit { Task { await viewModel.searchNow() } }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: PageRushPalette.radiusPill, style: .continuous)
                            .fill(PageRushPalette.surface)
                            .shadow(color: PageRushPalette.ink.opacity(0.08), radius: 8, y: 3)
                    )

                    content
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
            }
        }
        .onAppear {
            if let lockedChannel { viewModel.channel = lockedChannel }
            if let initialQuery {
                viewModel.query = initialQuery
                Task { await viewModel.searchNow() }
            }
        }
        .onChange(of: viewModel.query) { _, _ in viewModel.scheduleSearch() }
        .onChange(of: viewModel.channel) { _, _ in
            if lockedChannel == nil { viewModel.scheduleSearch() }
        }
    }

    private func filterPill(channel: QueryChannel, selected: Bool) -> some View {
        Button { viewModel.channel = channel } label: {
            HStack(spacing: 6) {
                Image(systemName: selected ? "circle.fill" : "circle")
                    .font(.system(size: 8))
                    .foregroundStyle(selected ? PageRushPalette.primary : PageRushPalette.ink.opacity(0.3))
                Text(channel.label)
                    .font(.caption.weight(.bold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(selected ? PageRushPalette.accent.opacity(0.4) : PageRushPalette.surface)
                    .overlay(Capsule().stroke(PageRushPalette.primary.opacity(selected ? 0.5 : 0.15), lineWidth: selected ? 2 : 1))
            )
            .foregroundStyle(PageRushPalette.ink)
        }
        .buttonStyle(.plain)
    }

    private var placeholder: String {
        switch viewModel.channel {
        case .everything: "Search everything — go!"
        case .title: "Hunt by title"
        case .author: "Find an author"
        case .topic: "Browse a topic"
        case .isbn: "Type an ISBN"
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.runState {
        case .idle:
            VStack(alignment: .leading, spacing: 8) {
                Text("Ready to rush?")
                    .font(PageRushPalette.rounded(.headline))
                Text("Pick a filter, type your query, and we'll pull titles from Open Library in seconds.")
                    .font(.footnote)
                    .foregroundStyle(PageRushPalette.ink.opacity(0.6))
            }
            .padding(.top, 18)
        case .loading:
            VStack(spacing: 14) {
                ProgressView()
                    .tint(PageRushPalette.primary)
                Text("Searching the stacks…")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PageRushPalette.ink.opacity(0.55))
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 24)
        case .empty:
            VStack(spacing: 10) {
                Image(systemName: "book.closed")
                    .font(.largeTitle)
                    .foregroundStyle(PageRushPalette.secondary)
                Text("No hits yet")
                    .font(PageRushPalette.rounded(.headline))
                Text("Try a broader search or switch filters — your next read is out there.")
                    .font(.footnote)
                    .foregroundStyle(PageRushPalette.ink.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 22)
        case .error(let message):
            Text(message)
                .foregroundStyle(PageRushPalette.primary)
                .multilineTextAlignment(.center)
                .padding()
        case .results:
            LazyVGrid(columns: grid, spacing: 12) {
                ForEach(viewModel.results) { item in
                    NavigationLink(value: item) {
                        searchTile(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 8)
        }
    }

    private func searchTile(item: VolumePreview) -> some View {
        let sh = PageRushPalette.cardShadow(reduceMotion: reduceMotion)
        return VStack(alignment: .leading, spacing: 8) {
            JacketImageView(jacketURL: item.jacketURL(size: "M"), cornerRadius: 14)
                .frame(height: 132)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(PageRushPalette.accent, lineWidth: 2)
                )
            Text(item.headline)
                .font(.caption.weight(.bold))
                .foregroundStyle(PageRushPalette.ink)
                .lineLimit(2)
            Text(item.creators.joined(separator: ", "))
                .font(.caption2)
                .foregroundStyle(PageRushPalette.ink.opacity(0.6))
                .lineLimit(1)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: PageRushPalette.radiusCard, style: .continuous)
                .fill(PageRushPalette.surface)
                .shadow(color: sh.color, radius: sh.radius * 0.85, y: sh.y)
        )
    }
}
