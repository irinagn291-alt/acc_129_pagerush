import Foundation
import SwiftData

enum VaultUseCase: Sendable {
    static func findVolume(identityKey: String, context: ModelContext) throws -> RushVolume? {
        var descriptor = FetchDescriptor<RushVolume>(
            predicate: #Predicate { $0.identityKey == identityKey }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    static func nextSprintOrder(context: ModelContext) throws -> Int {
        var descriptor = FetchDescriptor<RushVolume>(
            predicate: #Predicate { $0.onSprintBoard == true },
            sortBy: [SortDescriptor(\.sprintOrder, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        let max = try context.fetch(descriptor).first?.sprintOrder ?? -1
        return max + 1
    }

    static func stash(preview: VolumePreview, context: ModelContext) throws -> RushVolume {
        let key = preview.identityKey()
        if let existing = try findVolume(identityKey: key, context: context) {
            existing.merge(preview: preview)
            return existing
        }
        let volume = RushVolume(
            identityKey: key,
            headline: preview.headline,
            creatorsLine: preview.creators.joined(separator: "\n"),
            isbnCode: preview.isbnCode,
            workRef: preview.workRef,
            editionRef: preview.editionRef,
            jacketID: preview.jacketID,
            debutYear: preview.debutYear,
            milestone: .queued,
            sprintOrder: 0
        )
        context.insert(volume)
        return volume
    }

    static func addToSprint(preview: VolumePreview, context: ModelContext) throws -> RushVolume {
        let volume = try stash(preview: preview, context: context)
        if !volume.onSprintBoard {
            volume.onSprintBoard = true
            volume.sprintOrder = try nextSprintOrder(context: context)
        }
        volume.touchedAt = .now
        return volume
    }

    static func removeFromSprint(_ volume: RushVolume, context: ModelContext) {
        volume.onSprintBoard = false
        volume.sprintTarget = nil
        volume.touchedAt = .now
    }

    static func wipeVault(context: ModelContext) throws {
        let all = try context.fetch(FetchDescriptor<RushVolume>())
        for volume in all {
            context.delete(volume)
        }
    }
}
