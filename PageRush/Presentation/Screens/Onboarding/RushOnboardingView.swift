import SwiftUI

struct RushOnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var page = 0

    private let slides: [(String, String, String)] = [
        ("Rush your reading list", "Track every book like a sprint — fast, fun, and totally yours.", "bolt.fill"),
        ("Discover what's hot", "Browse trending titles and campus-ready picks from Open Library.", "sparkles"),
        ("Scan in seconds", "Point your camera at a barcode or punch in an ISBN. Done.", "barcode.viewfinder"),
        ("Crush your goals", "Build a Sprint Plan, rate books, and keep notes that stick.", "flag.checkered.2.crossed.fill")
    ]

    var body: some View {
        ZStack {
            PageRushPalette.energyGradient.ignoresSafeArea()
            VStack(spacing: 0) {
                progressHeader
                    .padding(.horizontal, 22)
                    .padding(.top, 12)

                HStack {
                    Spacer()
                    Button("Skip") { hasCompletedOnboarding = true }
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(PageRushPalette.primary)
                }
                .padding(.horizontal, 22)
                .padding(.top, 8)

                TabView(selection: $page) {
                    ForEach(slides.indices, id: \.self) { index in
                        slide(
                            title: slides[index].0,
                            subtitle: slides[index].1,
                            symbol: slides[index].2
                        )
                        .tag(index)
                        .padding(.horizontal, 22)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(RushMotion.slide(reduceMotion: reduceMotion), value: page)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Button(action: advance) {
                    Text(page == slides.count - 1 ? "Let's Go!" : "Next")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [PageRushPalette.primary, PageRushPalette.secondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 22)
            }
        }
    }

    private var progressHeader: some View {
        VStack(spacing: 8) {
            Text("Step \(page + 1) of \(slides.count)")
                .font(.caption.weight(.bold))
                .foregroundStyle(PageRushPalette.ink.opacity(0.5))
            RushProgressBar(
                progress: Double(page + 1) / Double(slides.count),
                accent: PageRushPalette.primary
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Onboarding step \(page + 1) of \(slides.count)")
    }

    private func slide(title: String, subtitle: String, symbol: String) -> some View {
        ScrollView {
            VStack(spacing: 22) {
                Image(systemName: symbol)
                    .font(.system(size: dynamicTypeSize.isAccessibilitySize ? 56 : 72, weight: .bold))
                    .foregroundStyle(PageRushPalette.primary)
                    .symbolRenderingMode(.hierarchical)
                    .padding(26)
                    .background(
                        Circle()
                            .fill(PageRushPalette.surface)
                            .shadow(color: PageRushPalette.ink.opacity(0.1), radius: reduceMotion ? 2 : 14, y: 8)
                    )
                VStack(alignment: .leading, spacing: 10) {
                    Text(title)
                        .font(PageRushPalette.rounded(.largeTitle))
                        .foregroundStyle(PageRushPalette.ink)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(subtitle)
                        .font(.title3)
                        .foregroundStyle(PageRushPalette.ink.opacity(0.72))
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.vertical, 24)
        }
    }

    private func advance() {
        if page < slides.count - 1 {
            page += 1
        } else {
            hasCompletedOnboarding = true
        }
    }
}
