import Foundation

enum QueryUseCase: Sendable {
    static func search(channel: QueryChannel, text: String, limit: Int = 40) async throws -> [VolumePreview] {
        try await ArchiveWire.shared.query(channel: channel, text: text, limit: limit)
    }

    static func lookupISBN(_ raw: String) async throws -> [VolumePreview] {
        try await ArchiveWire.shared.lookupISBN(raw)
    }
}
