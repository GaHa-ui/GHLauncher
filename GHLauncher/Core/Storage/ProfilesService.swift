import Foundation

/// Service for managing launcher profiles stored on disk
class ProfilesService {
    static let shared = ProfilesService()

    private let profilesDirectory: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        profilesDirectory = docs.appendingPathComponent("GHLauncher/profiles")
        createProfilesDirectoryIfNeeded()
    }

    private func createProfilesDirectoryIfNeeded() {
        let fm = FileManager.default
        if !fm.fileExists(atPath: profilesDirectory.path) {
            try? fm.createDirectory(at: profilesDirectory, withIntermediateDirectories: true)
        }
    }

    func saveProfile(_ profile: LauncherProfile) {
        let fileURL = profilesDirectory.appendingPathComponent("\(profile.id.uuidString).json")
        let data = try? encoder.encode(profile)
        try? data?.write(to: fileURL, options: .atomic)
    }

    func getRecentProfiles(limit: Int = 10) -> [LauncherProfile] {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(
            at: profilesDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: .skipsHiddenFiles
        ) else { return [] }

        let profiles = files
            .filter { $0.pathExtension == "json" }
            .compactMap { file -> (LauncherProfile?, Date)? in
                guard let data = try? Data(contentsOf: file),
                      let profile = try? decoder.decode(LauncherProfile.self, from: data),
                      let attrs = try? fm.attributesOfItem(atPath: file.path),
                      let modDate = attrs[.modificationDate] as? Date
                else { return nil }
                return (profile, modDate)
            }
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .compactMap { $0.0 }

        return Array(profiles)
    }

    func getProfile(id: UUID) -> LauncherProfile? {
        let fileURL = profilesDirectory.appendingPathComponent("\(id.uuidString).json")
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? decoder.decode(LauncherProfile.self, from: data)
    }

    func deleteProfile(id: UUID) {
        let fileURL = profilesDirectory.appendingPathComponent("\(id.uuidString).json")
        try? FileManager.default.removeItem(at: fileURL)
    }
}
