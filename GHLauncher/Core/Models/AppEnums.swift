import Foundation

enum SettingsKeys {
    static let resolutionIndex = "resolutionIndex"
    static let javaAllocMB = "javaAllocMB"
    static let jvmArgs = "jvmArgs"
    static let username = "username"
    static let offlineMode = "offlineMode"
    static let selectedVersion = "selectedVersion"
    static let lastProjectId = "lastProjectId"
    static let installedMods = "installedMods"
    static let appTheme = "appTheme"
    static let controlSensitivity = "controlSensitivity"
    static let renderDistance = "renderDistance"
}

enum ResolutionPreset: Int, CaseIterable, Identifiable, CustomStringConvertible {
    case res240p = 0
    case res360p
    case res480p
    case res540p
    case res720p
    case res1080p
    case custom

    var id: Int { rawValue }

    var dimensions: (width: Int, height: Int) {
        switch self {
        case .res240p: return (426, 240)
        case .res360p: return (640, 360)
        case .res480p: return (854, 480)
        case .res540p: return (960, 540)
        case .res720p: return (1280, 720)
        case .res1080p: return (1920, 1080)
        case .custom: return (854, 480)
        }
    }

    var description: String {
        switch self {
        case .res240p: return "240p (426×240)"
        case .res360p: return "360p (640×360)"
        case .res480p: return "480p (854×480)"
        case .res540p: return "540p (960×540)"
        case .res720p: return "720p (1280×720)"
        case .res1080p: return "1080p (1920×1080)"
        case .custom: return "Пользовательское"
        }
    }
}

enum LauncherAction: Identifiable {
    case changeResolution
    case changeJVM
    case clearCache
    case restartLauncher
    case viewLogs

    var id: String {
        switch self {
        case .changeResolution: return "resolution"
        case .changeJVM: return "jvm"
        case .clearCache: return "cache"
        case .restartLauncher: return "restart"
        case .viewLogs: return "logs"
        }
    }

    var title: String {
        switch self {
        case .changeResolution: return "Сменить разрешение"
        case .changeJVM: return "Сменить JVM"
        case .clearCache: return "Очистить кэш"
        case .restartLauncher: return "Перезапустить лаунчер"
        case .viewLogs: return "Просмотр логов"
        }
    }

    var icon: String {
        switch self {
        case .changeResolution: return "arrow.up.left.and.arrow.down.right"
        case .changeJVM: return "terminal"
        case .clearCache: return "trash"
        case .restartLauncher: return "arrow.clockwise"
        case .viewLogs: return "doc.text"
        }
    }
}
