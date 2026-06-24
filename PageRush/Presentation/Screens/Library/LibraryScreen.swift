import SwiftData
import SwiftUI

struct LibraryScreen: View {
    @Query(sort: \RushVolume.addedAt, order: .reverse) private var volumes: [RushVolume]
    @State private var showSettings = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationStack {
            ZStack {
                PageRushPalette.energyGradient.ignoresSafeArea()
                Group {
                    if volumes.isEmpty {
                        emptyState
                    } else {
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 20) {
                                Text("Your stack")
                                    .font(PageRushPalette.rounded(.title3))
                                    .foregroundStyle(PageRushPalette.ink)
                                ForEach(MilestoneStatus.allCases) { status in
                                    let subset = volumes.filter { $0.milestone == status }
                                    if !subset.isEmpty {
                                        statusSection(title: status.title, subset: subset)
                                    }
                                }
                            }
                            .padding(16)
                        }
                    }
                }
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape.fill")
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .navigationDestination(for: VolumePreview.self) { preview in
                VolumeDetailScreen(preview: preview)
            }
            .sheet(isPresented: $showSettings) {
                NavigationStack {
                    SettingsScreen()
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { showSettings = false }
                            }
                        }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            Image(systemName: "books.vertical.fill")
                .font(.system(size: 56))
                .foregroundStyle(PageRushPalette.primary)
            Text("Library's empty — let's fix that")
                .font(PageRushPalette.rounded(.title2))
                .foregroundStyle(PageRushPalette.ink)
            Text("Discover, search, or scan a barcode. Every book you save lands here, sorted by reading status.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(PageRushPalette.ink.opacity(0.65))
                .padding(.horizontal, 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func statusSection(title: String, subset: [RushVolume]) -> some View {
        let shadow = PageRushPalette.cardShadow(reduceMotion: reduceMotion)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(PageRushPalette.ink)
                Spacer()
                Image(systemName: "bolt.fill")
                    .foregroundStyle(PageRushPalette.accent)
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(subset) { volume in
                    NavigationLink(value: volume.asPreview()) {
                        volumeTile(volume: volume, shadow: shadow)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: PageRushPalette.radiusCard, style: .continuous)
                .fill(PageRushPalette.surface)
                .shadow(color: shadow.color, radius: shadow.radius, y: shadow.y)
        )
    }

    private func volumeTile(volume: RushVolume, shadow: (color: Color, radius: CGFloat, y: CGFloat)) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            JacketImageView(jacketURL: volume.jacketURL(size: "S"))
                .frame(height: 118)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(PageRushPalette.primary.opacity(0.4), lineWidth: 2)
                )
            Text(volume.headline)
                .font(.caption.weight(.semibold))
                .foregroundStyle(PageRushPalette.ink)
                .lineLimit(2)
            Text(volume.milestone.title)
                .font(.caption2.weight(.bold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(PageRushPalette.accent.opacity(0.5)))
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(PageRushPalette.canvas.opacity(0.9))
                .shadow(color: shadow.color, radius: shadow.radius * 0.5, y: shadow.y * 0.6)
        )
    }
}
