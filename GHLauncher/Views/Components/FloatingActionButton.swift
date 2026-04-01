import SwiftUI

struct FloatingActionButton: View {
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 8) {
            // Action items (shown when expanded)
            if isExpanded {
                ForEach(LauncherAction.allCases) { action in
                    actionButton(for: action)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isExpanded)
        .overlay(
            // Main FAB button
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                Image(systemName: isExpanded ? "xmark" : "plus")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.blue.gradient)
                    .clipShape(Circle())
                    .shadow(color: .blue.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            , alignment: .bottom
        )
    }

    @ViewBuilder
    private func actionButton(for action: LauncherAction) -> some View {
        Button(action: {
            handleAction(action)
            withAnimation { isExpanded = false }
        }) {
            HStack(spacing: 12) {
                Text(action.title)
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                Image(systemName: action.icon)
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.blue)
                    .clipShape(Circle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Color(.systemBackground)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
            .cornerRadius(24)
        }
    }

    private func handleAction(_ action: LauncherAction) {
        switch action {
        case .changeResolution:
            break // Navigate to settings
        case .changeJVM:
            break
        case .clearCache:
            clearCache()
        case .restartLauncher:
            restartLauncher()
        case .viewLogs:
            break
        }
    }

    private func clearCache() {
        let fileManager = FileManager.default
        let cacheURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]

        do {
            let contents = try fileManager.contentsOfDirectory(at: cacheURL, includingPropertiesForKeys: nil)
            for file in contents {
                // Use NSFileManager trashItem for safe deletion (recoverable)
                if #available(iOS 11.0, *) {
                    // trash not available for cache dirs, so selectively delete
                    // Skip .DS_Store and .localized
                    if file.lastPathComponent.hasPrefix(".") { continue }
                    try fileManager.removeItem(at: file)
                } else {
                    try fileManager.removeItem(at: file)
                }
            }
            UserDefaults.standard.removeObject(forKey: "lastCacheClear")
            print("✅ Кэш очищен")
        } catch {
            print("❌ Failed to clear cache: \(error)")
        }
    }

    private func restartLauncher() {
        // exit(0) kills the app on iOS (Watchdog termination)
        // Instead: reset app state and let user relaunch manually
        // In a real app, you'd use a coordinator to reset everything
        let nc = NotificationCenter.default
        nc.post(name: NSNotification.Name("ResetAppState"), object: nil)
    }
}

extension LauncherAction: CaseIterable {
    static var allCases: [LauncherAction] {
        [.changeResolution, .changeJVM, .clearCache, .restartLauncher, .viewLogs]
    }
}
