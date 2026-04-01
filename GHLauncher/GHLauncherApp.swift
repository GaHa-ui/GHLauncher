import SwiftUI

@main
struct GHLauncherApp: App {
    @StateObject private var appSettings = AppSettingsViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appSettings)
                .preferredColorScheme(appSettings.appTheme == "dark" ? .dark : appSettings.appTheme == "light" ? .light : .none)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                    // Save state on background
                    appSettings.saveSettings()
                }
        }
    }
}

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Главная", systemImage: "play.fill")
            }
            .tag(0)

            NavigationStack {
                ModsView()
            }
            .tabItem {
                Label("Моды", systemImage: "puzzlepiece.fill")
            }
            .tag(1)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Настройки", systemImage: "gearshape.fill")
            }
            .tag(2)

            NavigationStack {
                MoreView()
            }
            .tabItem {
                Label("Ещё", systemImage: "ellipsis.circle.fill")
            }
            .tag(3)
        }
        .tint(.accentColor)
    }
}
