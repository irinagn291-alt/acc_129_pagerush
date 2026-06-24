import Foundation

enum PulseWindow: String, Sendable {
    case daily
    case weekly
}

struct CatalogHitResponse: Decodable, Sendable {
    let numFound: Int?
    let docs: [CatalogHitDoc]?
}

struct CatalogHitDoc: Decodable, Sendable {
    let key: String?
    let title: String?
    let authorName: [String]?
    let coverI: Int?
    let firstPublishYear: Int?
    let isbn: [String]?
    let subject: [String]?

    enum CodingKeys: String, CodingKey {
        case key, title, isbn, subject
        case authorName = "author_name"
        case coverI = "cover_i"
        case firstPublishYear = "first_publish_year"
    }

    func toPreview() -> VolumePreview? {
        guard let title, !title.isEmpty else { return nil }
        return VolumePreview(
            headline: title,
            creators: authorName ?? [],
            isbnCode: isbn?.first,
            jacketID: coverI,
            workRef: key,
            editionRef: nil,
            debutYear: firstPublishYear,
            topicTags: subject
        )
    }
}

struct TopicShelfResponse: Decodable, Sendable {
    let works: [TopicShelfWork]?
}

struct TopicShelfWork: Decodable, Sendable {
    let key: String?
    let title: String?
    let coverId: Int?
    let authors: [TopicShelfAuthor]?

    enum CodingKeys: String, CodingKey {
        case key, title, authors
        case coverId = "cover_id"
    }

    func toPreview() -> VolumePreview? {
        guard let title, !title.isEmpty else { return nil }
        return VolumePreview(
            headline: title,
            creators: authors?.compactMap(\.name) ?? [],
            isbnCode: nil,
            jacketID: coverId,
            workRef: key,
            editionRef: nil,
            debutYear: nil,
            topicTags: nil
        )
    }
}

struct TopicShelfAuthor: Decodable, Sendable {
    let name: String?
}

struct EditionISBNPayload: Decodable, Sendable {
    let title: String?
    let fullTitle: String?
    let covers: [Int]?
    let authors: [EditionCreatorRef]?
    let works: [EditionWorkRef]?
    let key: String?
    let isbn10: [String]?
    let isbn13: [String]?
    let byStatement: String?

    enum CodingKeys: String, CodingKey {
        case title, covers, authors, works, key
        case fullTitle = "full_title"
        case isbn10 = "isbn_10"
        case isbn13 = "isbn_13"
        case byStatement = "by_statement"
    }

    func toPreview(fallbackISBN: String) -> VolumePreview {
        let t = title ?? fullTitle ?? "Unknown title"
        let cover = covers?.first
        let work = works?.first?.key
        let isbn = isbn13?.first ?? isbn10?.first ?? fallbackISBN
        let parsedCreators: [String] = {
            if let bs = byStatement?.lowercased(), bs.hasPrefix("by ") {
                let rest = String(byStatement!.dropFirst(3))
                return rest.split(separator: ";").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
            }
            return []
        }()
        return VolumePreview(
            headline: t,
            creators: parsedCreators,
            isbnCode: isbn,
            jacketID: cover,
            workRef: work,
            editionRef: key,
            debutYear: nil,
            topicTags: nil
        )
    }
}

struct EditionCreatorRef: Decodable, Sendable {
    let key: String?
}

struct EditionWorkRef: Decodable, Sendable {
    let key: String?
}
