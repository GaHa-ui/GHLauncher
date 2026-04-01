import Foundation
import Combine

@MainActor
class ModsViewModel: ObservableObject {
    @Published var searchQuery: String = ""
    @Published var searchResults: [ModrinthProject] = []
    @Published var featuredMods: [ModrinthProject] = []
    @Published var installedMods: [InstalledMod] = []
    @Published var isSearching: Bool = false
    @Published var downloadProgress: [String: Double] = [:] // modId -> progress
    @Published var error: String?
    @Published var showingImportPicker = false
    @Published var selectedModForDownload: ModrinthProject?

    private let modsService = ModsService.shared
    private var searchTask: Task<Void, Never>?
    private let settings: AppSettingsViewModel

    init(settings: AppSettingsViewModel = AppSettingsViewModel.shared) {
        self.settings = settings
        self.installedMods = settings.installedMods
        Task { await loadFeaturedMods() }
    }

    func searchMods() {
        searchTask?.cancel()
        searchTask = Task {
            guard !searchQuery.isEmpty else {
                searchResults = []
                return
            }
            isSearching = true
            defer { isSearching = false }

            do {
                searchResults = try await modsService.searchMods(query: searchQuery, limit: 20)
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    func loadFeaturedMods() async {
        do {
            featuredMods = try await modsService.getFeaturedMods()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func downloadMod(_ mod: ModrinthProject) async {
        do {
            let versions = try await modsService.getModVersions(projectId: mod.id)
            guard let latestVersion = versions.first,
                  let file = latestVersion.files.first(where: { $0.primary == true }) ?? latestVersion.files.first
            else {
                error = "Файлы не найдены"
                return
            }

            // Downloads folder in .minecraft/mods
            guard let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                error = "Не удалось получить доступ к документам"
                return
            }

            let minecraftDir = docsDir.appendingPathComponent(".minecraft")
            let modsDir = minecraftDir.appendingPathComponent("mods")
            let destination = modsDir.appendingPathComponent(file.filename)

            downloadProgress[mod.id] = 0.1
            _ = try await modsService.downloadModFile(url: URL(string: file.url)!, to: destination)
            downloadProgress[mod.id] = 1.0

            // Add to installed
            let installedMod = InstalledMod(
                name: mod.title,
                version: latestVersion.versionNumber,
                modrinthId: mod.id,
                fileURL: destination
            )
            installedMods.insert(installedMod, at: 0)
            settings.installedMods = installedMods
            downloadProgress.removeValue(forKey: mod.id)

        } catch {
            self.error = error.localizedDescription
            downloadProgress.removeValue(forKey: mod.id)
        }
    }

    func removeMod(_ mod: InstalledMod) {
        installedMods.removeAll { $0.id == mod.id }
        settings.installedMods = installedMods

        // Remove file
        if let url = mod.fileURL {
            try? FileManager.default.removeItem(at: url)
        }
    }

    func importMod(url: URL) {
        // Start accessing security-scoped resource
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let modsDir = docsDir.appendingPathComponent(".minecraft/mods")
            try FileManager.default.createDirectory(at: modsDir, withIntermediateDirectories: true)

            let destination = modsDir.appendingPathComponent(url.lastPathComponent)
            try FileManager.default.copyItem(at: url, to: destination)

            let name = url.deletingPathExtension().lastPathComponent
            let installedMod = InstalledMod(name: name, version: "1.0", fileURL: destination)
            installedMods.insert(installedMod, at: 0)
            settings.installedMods = installedMods
        } catch {
            self.error = error.localizedDescription
        }
    }
}
