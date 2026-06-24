import Foundation

actor ArchiveWire {
    static let shared = ArchiveWire()

    private let session: URLSession
    private let userAgent: String

    init(userAgent: String = "PageRush/1.0 (iOS; +https://openlibrary.org/developers/api)") {
        self.userAgent = userAgent
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 25
        configuration.timeoutIntervalForResource = 45
        configuration.waitsForConnectivity = true
        configuration.requestCachePolicy = .useProtocolCachePolicy
        session = URLSession(configuration: configuration)
    }

    private func payload(for url: URL, allow429Retry: Bool = true) async throws -> Data {
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        if http.statusCode == 429, allow429Retry {
            try await Task.sleep(nanoseconds: 1_200_000_000)
            return try await payload(for: url, allow429Retry: false)
        }
        guard (200...299).contains(http.statusCode) else {
            let message = "Open Library returned HTTP \(http.statusCode). Try again in a moment."
            throw NSError(domain: NSURLErrorDomain, code: URLError.Code.badServerResponse.rawValue, userInfo: [
                NSLocalizedDescriptionKey: message
            ])
        }
        return data
    }

    private func looksLikeJSONObject(_ data: Data) -> Bool {
        guard let text = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              let first = text.first else { return false }
        return first == "{" || first == "["
    }

    func query(channel: QueryChannel, text: String, limit: Int = 30) async throws -> [VolumePreview] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        switch channel {
        case .isbn:
            return try await lookupISBN(trimmed)
        default:
            var components = URLComponents(string: "https://openlibrary.org/search.json")!
            let qItem: URLQueryItem
            switch channel {
            case .everything: qItem = URLQueryItem(name: "q", value: trimmed)
            case .title: qItem = URLQueryItem(name: "title", value: trimmed)
            case .author: qItem = URLQueryItem(name: "author", value: trimmed)
            case .topic: qItem = URLQueryItem(name: "subject", value: trimmed)
            case .isbn: return []
            }
            components.queryItems = [qItem, URLQueryItem(name: "limit", value: String(limit))]
            guard let url = components.url else { return [] }
            let data = try await payload(for: url)
            let decoded = try JSONDecoder().decode(CatalogHitResponse.self, from: data)
            return (decoded.docs ?? []).compactMap { $0.toPreview() }
        }
    }

    func lookupISBN(_ raw: String) async throws -> [VolumePreview] {
        let normalized = raw.uppercased().filter { $0.isNumber || $0 == "X" }
        let query = normalized.count == 10 && normalized.hasSuffix("X")
            ? normalized
            : normalized.filter(\.isNumber)
        guard query.count >= 10 else { return [] }
        let url = URL(string: "https://openlibrary.org/isbn/\(query).json")!
        let data = try await payload(for: url)
        let edition = try JSONDecoder().decode(EditionISBNPayload.self, from: data)
        var preview = edition.toPreview(fallbackISBN: query)
        if preview.creators.isEmpty {
            let names = await resolveCreatorNames(refs: edition.authors ?? [])
            if !names.isEmpty {
                preview = VolumePreview(
                    headline: preview.headline,
                    creators: names,
                    isbnCode: preview.isbnCode,
                    jacketID: preview.jacketID,
                    workRef: preview.workRef,
                    editionRef: preview.editionRef,
                    debutYear: preview.debutYear,
                    topicTags: preview.topicTags
                )
            }
        }
        return [preview]
    }

    private func resolveCreatorNames(refs: [EditionCreatorRef]) async -> [String] {
        var names: [String] = []
        for ref in refs.prefix(4) {
            guard let key = ref.key, key.hasPrefix("/authors/") else { continue }
            if let name = await fetchCreatorName(path: key) {
                names.append(name)
            }
        }
        return names
    }

    private func fetchCreatorName(path: String) async -> String? {
        let url = URL(string: "https://openlibrary.org\(path).json")!
        do {
            let data = try await payload(for: url)
            struct A: Decodable { let name: String? }
            return try JSONDecoder().decode(A.self, from: data).name
        } catch {
            return nil
        }
    }

    func fetchTopicShelf(topic: String, limit: Int = 20) async throws -> [VolumePreview] {
        let encoded = topic.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? topic
        let url = URL(string: "https://openlibrary.org/subjects/\(encoded).json?limit=\(limit)")!
        let data = try await payload(for: url)
        let decoded = try JSONDecoder().decode(TopicShelfResponse.self, from: data)
        return (decoded.works ?? []).compactMap { $0.toPreview() }
    }

    func fetchPulse(window: PulseWindow) async throws -> [VolumePreview] {
        let url = URL(string: "https://openlibrary.org/trending/\(window.rawValue).json?limit=20")!
        do {
            let data = try await payload(for: url)
            guard looksLikeJSONObject(data) else {
                return try await fallbackPulse()
            }
            if let summaries = try decodePulseWorks(from: data), !summaries.isEmpty {
                return summaries
            }
        } catch {
            return try await fallbackPulse()
        }
        return try await fallbackPulse()
    }

    private func fallbackPulse() async throws -> [VolumePreview] {
        let topics = ["fiction", "fantasy", "history", "science_fiction", "romance"]
        let pick = topics.randomElement() ?? "fiction"
        return try await fetchTopicShelf(topic: pick, limit: 20)
    }

    private func decodePulseWorks(from data: Data) throws -> [VolumePreview]? {
        let obj = try JSONSerialization.jsonObject(with: data, options: [])
        guard let dict = obj as? [String: Any] else { return nil }
        if let works = dict["works"] as? [[String: Any]] {
            return works.compactMap { w in
                let key = w["key"] as? String
                let title = w["title"] as? String
                let cover = (w["cover_i"] as? NSNumber)?.intValue ?? (w["cover_id"] as? NSNumber)?.intValue
                let authorNames = w["author_name"] as? [String] ?? (w["authors"] as? [[String: Any]])?.compactMap { $0["name"] as? String }
                guard let title, !title.isEmpty else { return nil }
                return VolumePreview(
                    headline: title,
                    creators: authorNames ?? [],
                    isbnCode: nil,
                    jacketID: cover,
                    workRef: key,
                    editionRef: nil,
                    debutYear: (w["first_publish_year"] as? NSNumber)?.intValue,
                    topicTags: w["subject"] as? [String]
                )
            }
        }
        if let entries = dict["reading_log_entries"] as? [[String: Any]] {
            return entries.compactMap { entry in
                guard let work = entry["work"] as? [String: Any] else { return nil }
                let key = work["key"] as? String
                let title = work["title"] as? String
                let cover = (work["cover_i"] as? NSNumber)?.intValue
                let authorNames = work["author_name"] as? [String]
                guard let title, !title.isEmpty else { return nil }
                return VolumePreview(
                    headline: title,
                    creators: authorNames ?? [],
                    isbnCode: nil,
                    jacketID: cover,
                    workRef: key,
                    editionRef: nil,
                    debutYear: (work["first_publish_year"] as? NSNumber)?.intValue,
                    topicTags: work["subject"] as? [String]
                )
            }
        }
        return nil
    }
}
