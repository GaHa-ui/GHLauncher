import Foundation
import CoreGraphics

// MARK: - CGSize Codable wrapper
struct CodableSize: Codable {
    var width: CGFloat
    var height: CGFloat

    init(_ size: CGSize) {
        self.width = size.width
        self.height = size.height
    }

    var cgSizeValue: CGSize {
        CGSize(width: width, height: height)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        width = try container.decode(CGFloat.self, forKey: .width)
        height = try container.decode(CGFloat.self, forKey: .height)
    }

    private enum CodingKeys: String, CodingKey {
        case width, height
    }
}

// MARK: - LauncherProfile
struct LauncherProfile: Identifiable, Codable {
    let id: UUID
    var name: String
    var minecraftVersion: String
    var resolutionWidth: Double
    var resolutionHeight: Double
    var javaAllocMB: Int
    var jvmArgs: String
    var offlineMode: Bool
    var username: String
    var installedModIds: [UUID]
    var lastPlayed: Date?
    var playCount: Int

    var resolution: CGSize {
        CGSize(width: resolutionWidth, height: resolutionHeight)
    }

    init(
        id: UUID = UUID(),
        name: String = "Default",
        minecraftVersion: String = "1.21.4",
        resolution: CGSize = CGSize(width: 854, height: 480),
        javaAllocMB: Int = 2048,
        jvmArgs: String = "-XX:+UseG1GC",
        offlineMode: Bool = false,
        username: String = "",
        installedModIds: [UUID] = [],
        lastPlayed: Date? = nil,
        playCount: Int = 0
    ) {
        self.id = id
        self.name = name
        self.minecraftVersion = minecraftVersion
        self.resolutionWidth = resolution.width
        self.resolutionHeight = resolution.height
        self.javaAllocMB = javaAllocMB
        self.jvmArgs = jvmArgs
        self.offlineMode = offlineMode
        self.username = username
        self.installedModIds = installedModIds
        self.lastPlayed = lastPlayed
        self.playCount = playCount
    }
}
