import SwiftData
import SwiftUI

struct ReadingPlanSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<RushVolume> { $0.onSprintBoard == true }, sort: \RushVolume.sprintOrder)
    private var sprintVolumes: [RushVolume]
    @State private var editMode = EditMode.inactive

    var body: some View {
        NavigationStack {
            ZStack {
                PageRushPalette.canvas.ignoresSafeArea()
                Group {
                    if sprintVolumes.isEmpty {
                        ContentUnavailableView(
                            "No sprint books yet",
                            systemImage: "flag.checkered.2.crossed",
                            description: Text("Tap Sprint Plan on any book to queue your next reads.")
                        )
                    } else {
                        List {
                            Section {
                                RushProgressBar(progress: 0.35, accent: PageRushPalette.primary)
                                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                    .listRowBackground(Color.clear)
                            }
                            ForEach(sprintVolumes) { volume in
                                sprintRow(volume: volume)
                                    .listRowBackground(PageRushPalette.surface)
                            }
                            .onMove(perform: move)
                        }
                        .scrollContentBackground(.hidden)
                        .listStyle(.insetGrouped)
                    }
                }
            }
            .environment(\.editMode, $editMode)
            .navigationTitle("Sprint Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func sprintRow(volume: RushVolume) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                JacketImageView(jacketURL: volume.jacketURL(size: "S"))
                    .frame(width: 52, height: 78)
                VStack(alignment: .leading, spacing: 6) {
                    Text(volume.headline)
                        .font(.headline)
                    Text(volume.creatorsLine.replacingOccurrences(of: "\n", with: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    DatePicker("Target date", selection: Binding(
                        get: { volume.sprintTarget ?? .now },
                        set: { newValue in
                            volume.sprintTarget = newValue
                            volume.touchedAt = .now
                            try? modelContext.save()
                        }
                    ), displayedComponents: .date)
                    .font(.caption)
                    HStack {
                        Button("Start reading") {
                            volume.milestone = .inProgress
                            volume.touchedAt = .now
                            try? modelContext.save()
                        }
                        .buttonStyle(.bordered)
                        Button("Finished!") {
                            volume.milestone = .crushed
                            volume.wrapDate = .now
                            volume.touchedAt = .now
                            try? modelContext.save()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(PageRushPalette.primary)
                        Spacer()
                        Button(role: .destructive) {
                            VaultUseCase.removeFromSprint(volume, context: modelContext)
                            try? modelContext.save()
                        } label: {
                            Image(systemName: "trash.fill")
                        }
                        .buttonStyle(.borderless)
                    }
                    .font(.caption.weight(.semibold))
                }
            }
        }
        .padding(.vertical, 6)
    }

    private func move(from offsets: IndexSet, to destination: Int) {
        var reordered = sprintVolumes
        reordered.move(fromOffsets: offsets, toOffset: destination)
        for (idx, volume) in reordered.enumerated() {
            volume.sprintOrder = idx
        }
        try? modelContext.save()
    }
}
