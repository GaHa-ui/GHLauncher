import Foundation
import Combine

protocol VersionsServiceProtocol {
    var manifest: Manifest? { get }
    func fetchManifest() async throws
    func getReleaseVersions() -> [McVersion]
    func getSnapshotVersions() -> [McVersion]
}

struct Manifest: Codable {
    let latest: LatestVersions
    let versions: [ManifestVersion]

    struct LatestVersions: Codable {
        let release: String
        let snapshot: String
    }

    struct ManifestVersion: Codable {
        let id: String
        let type: String
        let url: String
        let time: String
        let releaseTime: String
    }
}

class VersionsService: ObservableObject, VersionsServiceProtocol {
    static let shared = VersionsService()

    @Published private(set) var manifest: Manifest?
    @Published var isLoading = false
    @Published var error: Error?

    private let manifestURL = URL(string: "https://launchermeta.mojang.com/mc/game/version_manifest_v2.json")!
    private let decoder = JSONDecoder()

    init() {
        decoder.dateDecodingStrategy = .iso8601
    }

    func fetchManifest() async throws {
        isLoading = true
        defer { isLoading = false }

        let (data, _) = try await URLSession.shared.data(from: manifestURL)
        self.manifest = try decoder.decode(Manifest.self, from: data)
    }

    func getReleaseVersions() -> [McVersion] {
        let formatter = ISO8601DateFormatter()
        return (manifest?.versions
            .filter { $0.type == "release" }
            .compactMap { version in
                McVersion(
                    id: version.id,
                    type: version.type,
                    releaseTime: formatter.date(from: version.releaseTime) ?? Date(),
                    url: version.url
                )
            }) ?? defaultReleaseVersions
    }

    func getSnapshotVersions() -> [McVersion] {
        let formatter = ISO8601DateFormatter()
        return (manifest?.versions
            .filter { $0.type == "snapshot" }
            .compactMap { version in
                McVersion(
                    id: version.id,
                    type: version.type,
                    releaseTime: formatter.date(from: version.releaseTime) ?? Date(),
                    url: version.url
                )
            }) ?? []
    }

    private var defaultReleaseVersions: [McVersion] {
        [
            McVersion(id: "1.21.4", type: "release", releaseTime: Date(), url: nil),
            McVersion(id: "1.21.3", type: "release", releaseTime: Date(), url: nil),
            McVersion(id: "1.21.1", type: "release", releaseTime: Date(), url: nil),
            McVersion(id: "1.21", type: "release", releaseTime: Date(), url: nil),
            McVersion(id: "1.20.6", type: "release", releaseTime: Date(), url: nil),
            McVersion(id: "1.20.4", type: "release", releaseTime: Date(), url: nil),
            McVersion(id: "1.20.2", type: "release", releaseTime: Date(), url: nil),
            McVersion(id: "1.20.1", type: "release", releaseTime: Date(), url: nil),
            McVersion(id: "1.20", type: "release", releaseTime: Date(), url: nil),
            McVersion(id: "1.19.4", type: "release", releaseTime: Date(), url: nil),
            McVersion(id: "1.19.2", type: "release", releaseTime: Date(), url: nil),
            McVersion(id: "1.18.2", type: "release", releaseTime: Date(), url: nil),
            McVersion(id: "1.17.1", type: "release", releaseTime: Date(), url: nil),
            McVersion(id: "1.16.5", type: "release", releaseTime: Date(), url: nil),
            McVersion(id: "1.12.2", type: "release", releaseTime: Date(), url: nil),
            McVersion(id: "1.8.9", type: "release", releaseTime: Date(), url: nil),
            McVersion(id: "1.7.10", type: "release", releaseTime: Date(), url: nil),
        ]
    }
}
