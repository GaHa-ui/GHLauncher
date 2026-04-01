import Foundation

struct McVersion: Codable, Identifiable, Hashable {
    let id: String
    let type: String // release, snapshot, old_beta, old_alpha
    let releaseTime: Date
    let url: String?

    var displayName: String {
        "\(id) (\(type.capitalized))"
    }

    var isRelease: Bool { type == "release" }
}

struct ModrinthProject: Codable, Identifiable {
    let id: String
    let slug: String
    let title: String
    let description: String
    let iconUrl: String?
    let author: String?
    let downloads: Int
    let followers: Int
    let categories: [String]
    let versions: [String]?
    let projectType: String? // mod, modpack, plugin, etc.

    enum CodingKeys: String, CodingKey {
        case id, slug, title, description
        case iconUrl = "icon_url"
        case author = "author"
        case downloads, followers, categories, versions
        case projectType = "project_type"
    }

    var authorName: String {
        author ?? "Unknown"
    }
}

struct ModrinthVersion: Codable, Identifiable {
    let id: String
    let projectId: String
    let name: String
    let versionNumber: String
    let files: [ModrinthFile]
    let gameVersions: [String]
    let loaders: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case projectId = "project_id"
        case name
        case versionNumber = "version_number"
        case files
        case gameVersions = "game_versions"
        case loaders
    }
}

struct ModrinthFile: Codable {
    let url: String
    let filename: String
    let primary: Bool?
}

struct InstalledMod: Identifiable, Codable {
    let id: UUID
    let name: String
    let version: String
    let modrinthId: String?
    let fileURL: URL?
    let installedAt: Date

    init(id: UUID = UUID(), name: String, version: String, modrinthId: String? = nil, fileURL: URL? = nil) {
        self.id = id
        self.name = name
        self.version = version
        self.modrinthId = modrinthId
        self.fileURL = fileURL
        self.installedAt = Date()
    }
}
