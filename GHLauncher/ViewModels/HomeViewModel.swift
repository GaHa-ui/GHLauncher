import Foundation
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    @Published var selectedVersion: String = ""
    @Published var username: String
    @Published var offlineMode: Bool
    @Published var isLaunching: Bool = false
    @Published var launchError: String?
    @Published var recentProjects: [LauncherProfile] = []
    @Published var allVersions: [McVersion] = []
    @Published var isLoadingVersions: Bool = false

    private let versionsService = VersionsService.shared
    private let profilesService = ProfilesService.shared

    init() {
        let settings = AppSettingsViewModel.shared
        self.selectedVersion = settings.selectedVersion
        self.username = settings.username
        self.offlineMode = settings.offlineMode
    }

    func loadVersions() async {
        isLoadingVersions = true
        defer { isLoadingVersions = false }

        // Load cached versions first
        allVersions = versionsService.getReleaseVersions()

        // Try fetching fresh manifest
        do {
            try await versionsService.fetchManifest()
            allVersions = versionsService.getReleaseVersions()
        } catch {
            // Use defaults
            print("Failed to fetch manifest: \(error.localizedDescription)")
        }
    }

    func loadRecentProjects() {
        recentProjects = profilesService.getRecentProfiles()
    }

    func launchGame() async {
        guard !selectedVersion.isEmpty else {
            launchError = "Выберите версию Minecraft"
            return
        }

        isLaunching = true
        launchError = nil

        do {
            // Save profile
            var profile = LauncherProfile(
                name: "Игра \(selectedVersion)",
                minecraftVersion: selectedVersion,
                offlineMode: offlineMode,
                username: username.isEmpty ? "Player" : username
            )

            // Update settings
            let settings = AppSettingsViewModel.shared ?? AppSettingsViewModel()
            settings.selectedVersion = selectedVersion
            settings.username = username
            settings.offlineMode = offlineMode

            // Save to recent
            profilesService.saveProfile(profile)
            loadRecentProjects()

            // Simulate launch (would integrate PojavLauncher SPM here)
            try await Task.sleep(nanoseconds: 2_000_000_000)

            isLaunching = false
            print("Game launched: \(selectedVersion)")
        } catch {
            launchError = error.localizedDescription
            isLaunching = false
        }
    }

    func selectProject(_ profile: LauncherProfile) {
        selectedVersion = profile.minecraftVersion
        username = profile.username
        offlineMode = profile.offlineMode
    }
}
