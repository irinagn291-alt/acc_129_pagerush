import Foundation

struct VolumePreview: Identifiable, Hashable, Sendable {
    var id: String { workRef ?? "ed:\(editionRef ?? "")-\(headline)-\(creators.prefix(1).joined())" }
    var headline: String
    var creators: [String]
    var isbnCode: String?
    var jacketID: Int?
    var workRef: String?
    var editionRef: String?
    var debutYear: Int?
    var topicTags: [String]?

    init(
        headline: String,
        creators: [String],
        isbnCode: String? = nil,
        jacketID: Int? = nil,
        workRef: String? = nil,
        editionRef: String? = nil,
        debutYear: Int? = nil,
        topicTags: [String]? = nil
    ) {
        self.headline = headline
        self.creators = creators
        self.isbnCode = isbnCode
        self.jacketID = jacketID
        self.workRef = workRef
        self.editionRef = editionRef
        self.debutYear = debutYear
        self.topicTags = topicTags
    }

    func jacketURL(size: String = "M") -> URL? {
        guard let jacketID else { return nil }
        return URL(string: "https://covers.openlibrary.org/b/id/\(jacketID)-\(size).jpg")
    }

    func identityKey() -> String {
        VolumeIdentity.key(for: self)
    }
}

struct SpotlightAuthor: Identifiable, Hashable, Sendable {
    var id: String { displayName }
    let displayName: String
    let searchQuery: String
    let vibe: String
}

enum SpotlightRoster {
    static let picks: [SpotlightAuthor] = [
        SpotlightAuthor(displayName: "Colleen Hoover", searchQuery: "Colleen Hoover", vibe: "Romance"),
        SpotlightAuthor(displayName: "Brandon Sanderson", searchQuery: "Brandon Sanderson", vibe: "Fantasy"),
        SpotlightAuthor(displayName: "Stephen King", searchQuery: "Stephen King", vibe: "Thriller"),
        SpotlightAuthor(displayName: "Toni Morrison", searchQuery: "Toni Morrison", vibe: "Literary"),
        SpotlightAuthor(displayName: "Yuval Noah Harari", searchQuery: "Yuval Noah Harari", vibe: "Non-fiction"),
        SpotlightAuthor(displayName: "Sarah J. Maas", searchQuery: "Sarah J. Maas", vibe: "Fantasy"),
        SpotlightAuthor(displayName: "James Clear", searchQuery: "James Clear", vibe: "Self-help"),
        SpotlightAuthor(displayName: "Agatha Christie", searchQuery: "Agatha Christie", vibe: "Mystery")
    ]
}
