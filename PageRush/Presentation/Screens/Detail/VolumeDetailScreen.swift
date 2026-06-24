import SwiftData
import SwiftUI

struct VolumeDetailScreen: View {
    let preview: VolumePreview

    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var stored: RushVolume?
    @State private var starEditor: Double = 0
    @State private var hotTakeText = ""
    @State private var notesText = ""
    @State private var kickoffDate = Date.now
    @State private var wrapDate = Date.now
    @State private var flashMessage: String?

    var body: some View {
        ZStack {
            PageRushPalette.energyGradient.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    heroBlock
                    if stored != nil {
                        Label("In your library", systemImage: "checkmark.seal.fill")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(PageRushPalette.secondary)
                    }
                    if let flashMessage {
                        Text(flashMessage)
                            .font(.footnote)
                            .foregroundStyle(PageRushPalette.primary)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(PageRushPalette.accent.opacity(0.35))
                            )
                    }
                    actionButtons
                    if let stored {
                        milestonePicker(stored)
                        rushPanel(title: "Your rating") {
                            Slider(value: $starEditor, in: 0...5, step: 1)
                                .tint(PageRushPalette.primary)
                            Text("\(Int(starEditor)) / 5 stars")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(PageRushPalette.ink.opacity(0.6))
                        }
                        .onChange(of: starEditor) { _, newValue in
                            stored.starScore = Int(newValue)
                            stored.touchedAt = .now
                            try? modelContext.save()
                        }
                        rushPanel(title: "Quick review") {
                            TextEditor(text: $hotTakeText)
                                .frame(minHeight: 120)
                                .onChange(of: hotTakeText) { _, _ in
                                    stored.hotTake = hotTakeText
                                    stored.touchedAt = .now
                                    try? modelContext.save()
                                }
                        }
                        rushPanel(title: "Notes") {
                            TextEditor(text: $notesText)
                                .frame(minHeight: 120)
                                .onChange(of: notesText) { _, _ in
                                    stored.marginNotes = notesText
                                    stored.touchedAt = .now
                                    try? modelContext.save()
                                }
                        }
                        rushPanel(title: "Reading dates") {
                            DatePicker("Started", selection: $kickoffDate, displayedComponents: .date)
                                .onChange(of: kickoffDate) { _, newValue in
                                    stored.kickoffDate = newValue
                                    stored.touchedAt = .now
                                    try? modelContext.save()
                                }
                            DatePicker("Finished", selection: $wrapDate, displayedComponents: .date)
                                .onChange(of: wrapDate) { _, newValue in
                                    stored.wrapDate = newValue
                                    stored.touchedAt = .now
                                    try? modelContext.save()
                                }
                        }
                    }
                }
                .padding(18)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: refreshBinding)
    }

    private var heroBlock: some View {
        let sh = PageRushPalette.cardShadow(reduceMotion: reduceMotion)
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 18) {
                JacketImageView(jacketURL: preview.jacketURL(size: "L"), cornerRadius: 18)
                    .frame(width: 118, height: 176)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(PageRushPalette.rushStroke, lineWidth: 2)
                    )
                VStack(alignment: .leading, spacing: 10) {
                    RushBadge(text: "Book detail")
                    Text(preview.headline)
                        .font(PageRushPalette.rounded(.title2))
                        .foregroundStyle(PageRushPalette.ink)
                    Text(preview.creators.joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundStyle(PageRushPalette.ink.opacity(0.7))
                    metaChips
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: PageRushPalette.radiusCard, style: .continuous)
                .fill(PageRushPalette.surface)
                .shadow(color: sh.color, radius: sh.radius, y: sh.y)
        )
    }

    private var metaChips: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let year = preview.debutYear {
                chip(icon: "calendar", text: "First published \(year)")
            }
            if let isbn = preview.isbnCode {
                chip(icon: "barcode", text: isbn)
            }
        }
    }

    private func chip(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Capsule().fill(PageRushPalette.accent.opacity(0.4)))
        .foregroundStyle(PageRushPalette.ink)
    }

    private func rushPanel<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(PageRushPalette.ink)
            content()
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: PageRushPalette.radiusPill, style: .continuous)
                        .fill(PageRushPalette.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: PageRushPalette.radiusPill, style: .continuous)
                                .stroke(PageRushPalette.secondary.opacity(0.15), lineWidth: 1)
                        )
                )
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        if stored == nil {
            HStack(spacing: 10) {
                Button("Add to Library") { stash(sprint: false) }
                    .buttonStyle(.borderedProminent)
                    .tint(PageRushPalette.secondary)
                Button("Sprint Plan") { stash(sprint: true) }
                    .buttonStyle(.borderedProminent)
                    .tint(PageRushPalette.primary)
            }
        } else if let stored, !stored.onSprintBoard {
            Button("Add to Sprint Plan") { stash(sprint: true) }
                .buttonStyle(.borderedProminent)
                .tint(PageRushPalette.primary)
        }
    }

    private func refreshBinding() {
        let key = preview.identityKey()
        stored = try? VaultUseCase.findVolume(identityKey: key, context: modelContext)
        if let stored {
            starEditor = Double(stored.starScore)
            hotTakeText = stored.hotTake
            notesText = stored.marginNotes
            kickoffDate = stored.kickoffDate ?? .now
            wrapDate = stored.wrapDate ?? .now
        }
    }

    private func stash(sprint: Bool) {
        do {
            let volume: RushVolume
            if sprint {
                volume = try VaultUseCase.addToSprint(preview: preview, context: modelContext)
            } else {
                volume = try VaultUseCase.stash(preview: preview, context: modelContext)
            }
            try modelContext.save()
            stored = volume
            flashMessage = sprint ? "Added to your Sprint Plan!" : "Saved to Library!"
            refreshBinding()
        } catch {
            flashMessage = error.localizedDescription
        }
    }

    @ViewBuilder
    private func milestonePicker(_ stored: RushVolume) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Reading status")
                .font(.headline.weight(.bold))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(MilestoneStatus.allCases) { status in
                        Button(status.title) {
                            stored.milestone = status
                            stored.touchedAt = .now
                            try? modelContext.save()
                        }
                        .font(.caption.weight(.bold))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            Capsule()
                                .fill(stored.milestone == status ? PageRushPalette.accent : PageRushPalette.surface)
                        )
                    }
                }
            }
        }
    }
}
