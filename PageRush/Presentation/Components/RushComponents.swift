import SwiftUI

struct JacketImageView: View {
    let jacketURL: URL?
    var cornerRadius: CGFloat = 12

    var body: some View {
        ZStack {
            if let jacketURL {
                AsyncImage(url: jacketURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    private var placeholder: some View {
        ZStack {
            LinearGradient(
                colors: [PageRushPalette.secondary.opacity(0.35), PageRushPalette.primary.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "book.closed.fill")
                .font(.title2)
                .foregroundStyle(PageRushPalette.ink.opacity(0.35))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct RushVolumeCard: View {
    let preview: VolumePreview
    let reduceMotion: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            let sh = PageRushPalette.cardShadow(reduceMotion: reduceMotion)
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 10) {
                    JacketImageView(jacketURL: preview.jacketURL(size: "M"), cornerRadius: 16)
                        .frame(width: 88, height: 118)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(PageRushPalette.accent, lineWidth: 2)
                        )
                    VStack(alignment: .leading, spacing: 6) {
                        Text(preview.headline)
                            .font(PageRushPalette.rounded(.callout))
                            .foregroundStyle(PageRushPalette.ink)
                            .lineLimit(3)
                        Text(preview.creators.joined(separator: ", "))
                            .font(.caption2)
                            .foregroundStyle(PageRushPalette.ink.opacity(0.6))
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                HStack {
                    Image(systemName: "bolt.fill")
                        .font(.caption2)
                        .foregroundStyle(PageRushPalette.primary)
                    Text("Hot pick")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(PageRushPalette.secondary)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: PageRushPalette.radiusCard, style: .continuous)
                    .fill(PageRushPalette.surface)
                    .shadow(color: sh.color, radius: sh.radius, y: sh.y)
            )
        }
        .buttonStyle(.plain)
    }
}

struct RushProgressBar: View {
    let progress: Double
    let accent: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(PageRushPalette.ink.opacity(0.08))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [accent, PageRushPalette.secondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(geo.size.width * progress, 8))
            }
        }
        .frame(height: 6)
    }
}

struct RushBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.title3.weight(.bold))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(PageRushPalette.accent.opacity(0.35))
                    .overlay(Capsule().stroke(PageRushPalette.primary.opacity(0.3), lineWidth: 1))
            )
    }
}

struct RushFAB: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "flag.checkered.2.crossed.fill")
                    .font(.body.weight(.bold))
                Text("Sprint Plan")
                    .font(.subheadline.weight(.bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [PageRushPalette.primary, PageRushPalette.secondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: PageRushPalette.primary.opacity(0.4), radius: 10, y: 4)
            )
        }
        .buttonStyle(.plain)
    }
}
