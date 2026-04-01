import SwiftUI

struct MoreView: View {
    @EnvironmentObject var settings: AppSettingsViewModel
    @State private var showingResetAlert = false
    @State private var showingLogs = false
    @State private var showingProfileExport = false
    @State private var updateAvailable = false
    @State private var checkingForUpdates = false
    @State private var latestLog: String = ""
    @State private var lastLaunchLog: String = ""

    let appVersion = "1.0.0"
    let githubURL = "https://github.com/user/GHLauncher"

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // App info
                appInfoSection

                // Actions
                actionsSection

                // Logs preview
                logsPreviewSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Ещё")
        .sheet(isPresented: $showingLogs) {
            LogsView()
                .presentationDetents([.medium, .large])
        }
        .alert("Сбросить все данные?", isPresented: $showingResetAlert) {
            Button("Отмена", role: .cancel) {}
            Button("Сбросить", role: .destructive) {
                settings.resetSettings()
            }
        } message: {
            Text("Все настройки и данные будут удалены. Это необратимо.")
        }
    }

    // MARK: - App Info

    private var appInfoSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "app.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green.gradient)

            Text("GH Launcher")
                .font(.title.bold())
            Text("Версия \(appVersion)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Minecraft Launcher для iOS")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Actions

    private var actionsSection: some View {
        VStack(spacing: 8) {
            // GitHub
            Link(destination: URL(string: githubURL)!) {
                HStack {
                    Image(systemName: "link")
                    Text("GitHub репозиторий")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
            }

            // Check for updates
            Button(action: { checkForUpdates() }) {
                HStack {
                    if checkingForUpdates {
                        ProgressView()
                    } else {
                        Image(systemName: updateAvailable ? "arrow.down.circle.fill" : "checkmark.shield")
                    }
                    Text("Проверить обновления")
                    Spacer()
                    if updateAvailable {
                        Text("Доступно")
                            .foregroundStyle(.green)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
            }
            .disabled(checkingForUpdates)

            // Export profile
            Button(action: { showingProfileExport = true }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Экспорт профиля")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
            }

            // Reset
            Button(role: .destructive, action: { showingResetAlert = true }) {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Сбросить все настройки")
                    Spacer()
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Logs Preview

    private var logsPreviewSection: some View {
        Button(action: { showingLogs = true }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "doc.text.fill")
                    Text("Просмотр логов")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }

                Text("latest.log, lastlaunch.log и другие.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("Нажмите для просмотра, копирования или очистки")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func checkForUpdates() {
        checkingForUpdates = true
        Task {
            // Simulate check
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            updateAvailable = false // Placeholder
            checkingForUpdates = false
        }
    }
}
