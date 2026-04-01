import SwiftUI

// MARK: - URL file type extensions

extension UTType {
    static let jar = UTType(filenameExtension: "jar") ?? .data
    static let archive = UTType(filenameExtension: "zip") ?? .zip
}

// AppSettingsViewModel.shared is defined in AppSettingsShared.swift

// MARK: - Formatted date helpers

extension Date {
    func formatted(date: Date.FormatStyle.DateStyle, time: Date.FormatStyle.TimeStyle) -> String {
        self.formatted(.dateTime.year().month(.abbreviated).day().hour().minute())
    }

    var relativeDescription: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

// MARK: - File size formatting

extension Int {
    var fileSizeDescription: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(self) * 1_000_000)
    }
}

// MARK: - View modifiers

struct ScrollableIfNecessary: ViewModifier {
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                ScrollView {
                    content
                }
            }
        }
    }
}
