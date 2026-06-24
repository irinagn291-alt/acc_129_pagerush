import Foundation

enum VolumeIdentity: Sendable {
    static func key(for preview: VolumePreview) -> String {
        if let isbn = preview.isbnCode, !isbn.isEmpty {
            let digits = isbn.filter(\.isNumber)
            if digits.count >= 10 { return "isbn:\(digits)" }
        }
        if let workRef = preview.workRef, !workRef.isEmpty { return "work:\(workRef)" }
        let authorKey = preview.creators.map { $0.lowercased() }.sorted().joined(separator: "|")
        return "title:\(preview.headline.lowercased())|authors:\(authorKey)"
    }

    static func matches(_ a: VolumePreview, _ b: VolumePreview) -> Bool {
        key(for: a) == key(for: b)
    }
}
