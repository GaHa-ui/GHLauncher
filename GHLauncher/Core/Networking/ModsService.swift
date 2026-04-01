import Foundation
import Combine

protocol ModsServiceProtocol {
    func searchMods(query: String, limit: Int) async throws -> [ModrinthProject]
    func getModVersions(projectId: String) async throws -> [ModrinthVersion]
    func downloadModFile(url: URL, to destination: URL) async throws -> URL
    func getFeaturedMods() async throws -> [ModrinthProject]
}

class ModsService: ObservableObject, ModsServiceProtocol {
    static let shared = ModsService()

    private let baseURL = URL(string: "https://api.modrinth.com/v2")!
    private let decoder = JSONDecoder()
    private let headers = ["User-Agent": "GHLauncher/1.0"]

    init() {
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    func searchMods(query: String, limit: Int = 20) async throws -> [ModrinthProject] {
        guard !query.isEmpty else { return [] }

        var components = URLComponents(string: baseURL.appendingPathComponent("search").absoluteString)!
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "facets", value: "[[\"project_type:mod\"]]"),
            URLQueryItem(name: "index", value: "relevance")
        ]

        let request = try makeRequest(url: components.url!)
        let (data, _) = try await URLSession.shared.data(for: request)
        let result = try decoder.decode(ModrinthSearchResponse.self, from: data)
        return result.hits
    }

    func getModVersions(projectId: String) async throws -> [ModrinthVersion] {
        let url = baseURL
            .appendingPathComponent("project")
            .appendingPathComponent(projectId)
            .appendingPathComponent("version")

        let request = try makeRequest(url: url)
        let (data, _) = try await URLSession.shared.data(for: request)
        return try decoder.decode([ModrinthVersion].self, from: data)
    }

    func downloadModFile(url: URL, to destination: URL) async throws -> URL {
        let request = try makeRequest(url: url)
        let (tempURL, _) = try await URLSession.shared.download(for: request)

        let fm = FileManager.default
        let modsDir = destination.deletingLastPathComponent()
        if !fm.fileExists(atPath: modsDir.path) {
            try fm.createDirectory(at: modsDir, withIntermediateDirectories: true)
        }

        if fm.fileExists(atPath: destination.path) {
            try fm.removeItem(at: destination)
        }

        try fm.moveItem(at: tempURL, to: destination)
        return destination
    }

    func getFeaturedMods() async throws -> [ModrinthProject] {
        var components = URLComponents(string: baseURL.appendingPathComponent("search").absoluteString)!
        components.queryItems = [
            URLQueryItem(name: "query", value: ""),
            URLQueryItem(name: "limit", value: "12"),
            URLQueryItem(name: "facets", value: "[[\"project_type:mod\"]]"),
            URLQueryItem(name: "index", value: "downloads")
        ]

        let request = try makeRequest(url: components.url!)
        let (data, _) = try await URLSession.shared.data(for: request)
        let result = try decoder.decode(ModrinthSearchResponse.self, from: data)
        return result.hits
    }

    private func makeRequest(url: URL) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("GHLauncher/1.0 (ios; swiftui)", forHTTPHeaderField: "User-Agent")
        return request
    }
}

// MARK: - Search Response

struct ModrinthSearchResponse: Codable {
    let hits: [ModrinthProject]
    let offset: Int
    let limit: Int
    let totalHits: Int
}
