import Foundation
import Combine

/// Manages app-wide settings persisted in UserDefaults
class AppSettingsViewModel: ObservableObject {
    static let shared = AppSettingsViewModel()

    @Published var resolutionIndex: Int = 4 { // 720p default
        didSet { saveSettings() }
    }
    @Published var javaAllocMB: Int = 2048 {
        didSet { saveSettings() }
    }
    @Published var jvmArgs: String = "-XX:+UseG1GC -XX:+UnlockExperimentalVMOptions" {
        didSet { saveSettings() }
    }
    @Published var username: String = "" {
        didSet { saveSettings() }
    }
    @Published var offlineMode: Bool = true {
        didSet { saveSettings() }
    }
    @Published var selectedVersion: String = "1.21.4" {
        didSet { saveSettings() }
    }
    @Published var controlSensitivity: Double = 50.0 {
        didSet { saveSettings() }
    }
    @Published var renderDistance: Int = 8 {
        didSet { saveSettings() }
    }
    @Published var installedMods: [InstalledMod] = [] {
        didSet { saveSettings() }
    }
    @Published var appTheme: String = "system" {
        didSet { saveSettings() }
    }

    init() {
        loadSettings()
    }

    func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(resolutionIndex, forKey: SettingsKeys.resolutionIndex)
        defaults.set(javaAllocMB, forKey: SettingsKeys.javaAllocMB)
        defaults.set(jvmArgs, forKey: SettingsKeys.jvmArgs)
        defaults.set(username, forKey: SettingsKeys.username)
        defaults.set(offlineMode, forKey: SettingsKeys.offlineMode)
        defaults.set(selectedVersion, forKey: SettingsKeys.selectedVersion)
        defaults.set(controlSensitivity, forKey: SettingsKeys.controlSensitivity)
        defaults.set(renderDistance, forKey: SettingsKeys.renderDistance)
        defaults.set(appTheme, forKey: SettingsKeys.appTheme)

        // Encode installed mods
        if let data = try? JSONEncoder().encode(installedMods) {
            defaults.set(data, forKey: SettingsKeys.installedMods)
        }
        defaults.synchronize()
    }

    func loadSettings() {
        let defaults = UserDefaults.standard
        resolutionIndex = defaults.integer(forKey: SettingsKeys.resolutionIndex)
        javaAllocMB = defaults.integer(forKey: SettingsKeys.javaAllocMB)
        jvmArgs = defaults.string(forKey: SettingsKeys.jvmArgs) ?? jvmArgs
        username = defaults.string(forKey: SettingsKeys.username) ?? ""
        offlineMode = defaults.bool(forKey: SettingsKeys.offlineMode)
        selectedVersion = defaults.string(forKey: SettingsKeys.selectedVersion) ?? "1.21.4"
        controlSensitivity = defaults.double(forKey: SettingsKeys.controlSensitivity)
        renderDistance = defaults.integer(forKey: SettingsKeys.renderDistance)
        appTheme = defaults.string(forKey: SettingsKeys.appTheme) ?? "system"

        if let data = defaults.data(forKey: SettingsKeys.installedMods),
           let mods = try? JSONDecoder().decode([InstalledMod].self, from: data) {
            installedMods = mods
        }
    }

    func resetSettings() {
        let defaults = UserDefaults.standard
        let domain = Bundle.main.bundleIdentifier ?? "com.ghlauncher.app"
        defaults.removePersistentDomain(forName: domain)
        // Reset to defaults in memory
        resolutionIndex = 4
        javaAllocMB = 2048
        jvmArgs = "-XX:+UseG1GC -XX:+UnlockExperimentalVMOptions"
        username = ""
        offlineMode = true
        selectedVersion = "1.21.4"
        controlSensitivity = 50.0
        renderDistance = 8
        appTheme = "system"
        installedMods = []
    }
}
