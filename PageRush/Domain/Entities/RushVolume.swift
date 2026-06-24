import Foundation
import SwiftData

@Model
final class RushVolume {
    @Attribute(.unique) var identityKey: String
    var headline: String
    var creatorsLine: String
    var isbnCode: String?
    var workRef: String?
    var editionRef: String?
    var jacketID: Int?
    var debutYear: Int?
    var milestoneRaw: String
    var starScore: Int
    var hotTake: String
    var marginNotes: String
    var kickoffDate: Date?
    var wrapDate: Date?
    var addedAt: Date
    var touchedAt: Date
    var onSprintBoard: Bool
    var sprintTarget: Date?
    var sprintOrder: Int

    init(
        identityKey: String,
        headline: String,
        creatorsLine: String,
        isbnCode: String? = nil,
        workRef: String? = nil,
        editionRef: String? = nil,
        jacketID: Int? = nil,
        debutYear: Int? = nil,
        milestone: MilestoneStatus = .queued,
        starScore: Int = 0,
        hotTake: String = "",
        marginNotes: String = "",
        kickoffDate: Date? = nil,
        wrapDate: Date? = nil,
        addedAt: Date = .now,
        touchedAt: Date = .now,
        onSprintBoard: Bool = false,
        sprintTarget: Date? = nil,
        sprintOrder: Int = 0
    ) {
        self.identityKey = identityKey
        self.headline = headline
        self.creatorsLine = creatorsLine
        self.isbnCode = isbnCode
        self.workRef = workRef
        self.editionRef = editionRef
        self.jacketID = jacketID
        self.debutYear = debutYear
        self.milestoneRaw = milestone.rawValue
        self.starScore = starScore
        self.hotTake = hotTake
        self.marginNotes = marginNotes
        self.kickoffDate = kickoffDate
        self.wrapDate = wrapDate
        self.addedAt = addedAt
        self.touchedAt = touchedAt
        self.onSprintBoard = onSprintBoard
        self.sprintTarget = sprintTarget
        self.sprintOrder = sprintOrder
    }

    var milestone: MilestoneStatus {
        get { MilestoneStatus(rawValue: milestoneRaw) ?? .queued }
        set { milestoneRaw = newValue.rawValue }
    }

    var creatorsList: [String] {
        creatorsLine.split(separator: "\n").map(String.init)
    }

    func merge(preview: VolumePreview) {
        headline = preview.headline
        creatorsLine = preview.creators.joined(separator: "\n")
        isbnCode = preview.isbnCode ?? isbnCode
        workRef = preview.workRef ?? workRef
        editionRef = preview.editionRef ?? editionRef
        jacketID = preview.jacketID ?? jacketID
        debutYear = preview.debutYear ?? debutYear
        touchedAt = .now
    }

    func jacketURL(size: String = "M") -> URL? {
        guard let jacketID else { return nil }
        return URL(string: "https://covers.openlibrary.org/b/id/\(jacketID)-\(size).jpg")
    }

    func asPreview() -> VolumePreview {
        VolumePreview(
            headline: headline,
            creators: creatorsList,
            isbnCode: isbnCode,
            jacketID: jacketID,
            workRef: workRef,
            editionRef: editionRef,
            debutYear: debutYear,
            topicTags: nil
        )
    }
}
