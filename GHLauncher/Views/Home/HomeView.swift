import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject var settings: AppSettingsViewModel
    @State private var showingError = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                versionPickerSection
                accountSection
                playButtonSection
                recentProjectsSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("GH Launcher")
        .task {
            await viewModel.loadVersions()
            viewModel.loadRecentProjects()
        }
        .onChange(of: viewModel.launchError) { _ in
            if viewModel.launchError != nil { showingError = true }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 4) {
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green.gradient)
            Text("GH Launcher")
                .font(.title.bold())
                .foregroundStyle(.primary)
            Text("Minecraft для iOS")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 12)
    }

    private var versionPickerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Версия Minecraft", systemImage: "tag.fill")
                .font(.headline)
            Picker("Версия", selection: $viewModel.selectedVersion) {
                if viewModel.allVersions.isEmpty {
                    Text("Загрузка...").tag("")
                } else {
                    ForEach(viewModel.allVersions) { version in
                        Text(version.displayName).tag(version.id)
                    }
                }
            }
            .pickerStyle(.menu)
            .disabled(viewModel.allVersions.isEmpty)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    private var accountSection: some View {
        VStack(spacing: 12) {
            TextField("Никнейм", text: $viewModel.username)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .disableAutocorrection(true)

            Toggle(isOn: $viewModel.offlineMode) {
                HStack {
                    Image(systemName: viewModel.offlineMode ? "wifi.slash" : "wifi")
                    Text("Офлайн-режим")
                }
            }
            .padding(.horizontal, 4)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    private var playButtonSection: some View {
        Button(action: {
            Task { await viewModel.launchGame() }
        }) {
            HStack {
                if viewModel.isLaunching {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "play.fill")
                        .font(.title2)
                }
                Text(viewModel.isLaunching ? "Запуск..." : "Играть")
                    .font(.title3.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(colors: [.green, .green.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                    .opacity(viewModel.isLaunching ? 0.7 : 1.0)
            )
            .foregroundStyle(.white)
            .clipShape(Capsule())
        }
        .disabled(viewModel.isLaunching)
        .shadow(color: .green.opacity(0.4), radius: 12, x: 0, y: 6)
        .alert("Ошибка", isPresented: $showingError) {
            Button("OK") { viewModel.launchError = nil }
        } message: {
            Text(viewModel.launchError ?? "")
        }
    }

    private var recentProjectsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Последние проекты", systemImage: "clock.fill")
                .font(.headline)
                .padding(.horizontal)

            if viewModel.recentProjects.isEmpty {
                Text("Нет проектов. Запустите игру!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(viewModel.recentProjects.prefix(5)) { profile in
                    Button(action: {
                        viewModel.selectProject(profile)
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(profile.name)
                                    .font(.body.bold())
                                HStack(spacing: 8) {
                                    Label(profile.minecraftVersion, systemImage: "tag")
                                    if profile.offlineMode {
                                        Label("Офлайн", systemImage: "wifi.slash")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if let lastPlayed = profile.lastPlayed {
                                Text(lastPlayed.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
