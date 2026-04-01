import Foundation
import SwiftUI

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var resolutionIndex: Int {
        didSet { settings.resolutionIndex = resolutionIndex }
    }
    @Published var javaAllocMB: Int {
        didSet { settings.javaAllocMB = javaAllocMB }
    }
    @Published var jvmArgs: String {
        didSet { settings.jvmArgs = jvmArgs }
    }
    @Published var controlSensitivity: Double {
        didSet { settings.controlSensitivity = controlSensitivity }
    }
    @Published var renderDistance: Int {
        didSet { settings.renderDistance = renderDistance }
    }

    let resolutionPresets = ResolutionPreset.allCases
    let settings: AppSettingsViewModel

    init(settings: AppSettingsViewModel = AppSettingsViewModel.shared) {
        self.settings = settings
        self.resolutionIndex = settings.resolutionIndex
        self.javaAllocMB = settings.javaAllocMB
        self.jvmArgs = settings.jvmArgs
        self.controlSensitivity = settings.controlSensitivity
        self.renderDistance = settings.renderDistance
    }

    func save() {
        settings.saveSettings()
    }

    func resetToDefaults() {
        resolutionIndex = 4
        javaAllocMB = 2048
        jvmArgs = "-XX:+UseG1GC -XX:+UnlockExperimentalVMOptions"
        controlSensitivity = 50.0
        renderDistance = 8
        save()
    }
}
