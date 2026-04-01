import SwiftUI

struct ModsView: View {
    @StateObject private var viewModel = ModsViewModel()
    @State private var showingLogView = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Search
                searchSection

                // Featured mods
                featuredSection

                // Search results
                searchResultsSection

                // Installed mods
                installedModsSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Моды")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        viewModel.showingImportPicker = true
                    } label: {
                        Label("Импортировать мод", systemImage: "square.and.arrow.down")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .fileImporter(
            isPresented: $viewModel.showingImportPicker,
            allowedContentTypes: [.jar, .zip, .archive],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                viewModel.importMod(url: url)
            }
        }
        .alert("Ошибка", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") { viewModel.error = nil }
        } message: {
            Text(viewModel.error ?? "")
        }
    }

    // MARK: - Search

    private var searchSection: some View {
        HStack(spacing: 8) {
            TextField("Поиск модов...", text: $viewModel.searchQuery)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    viewModel.searchMods()
                }

            Button(action: { viewModel.searchMods() }) {
                Image(systemName: "magnifyingglass")
                    .font(.title3)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.searchQuery.isEmpty)
        }
    }

    // MARK: - Featured

    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Популярные моды")
                .font(.headline)

            if viewModel.featuredMods.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                    ForEach(viewModel.featuredMods.prefix(6)) { mod in
                        ModCard(mod: mod) {
                            Task { await viewModel.downloadMod(mod) }
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Search Results

    @ViewBuilder
    private var searchResultsSection: some View {
        if !viewModel.searchQuery.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Результаты")
                        .font(.headline)
                    if viewModel.isSearching {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }

                if viewModel.searchResults.isEmpty && !viewModel.isSearching {
                    Text("Ничего не найдено")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                        ForEach(viewModel.searchResults) { mod in
                            ModCard(mod: mod) {
                                Task { await viewModel.downloadMod(mod) }
                            }
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
            .cornerRadius(16)
        }
    }

    // MARK: - Installed Mods

    private var installedModsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Установленные моды (\(viewModel.installedMods.count))", systemImage: "checkmark.circle.fill")
                .font(.headline)

            if viewModel.installedMods.isEmpty {
                Text("Нет установленных модов")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(viewModel.installedMods) { mod in
                    HStack {
                        Image(systemName: "cube.box.fill")
                            .foregroundStyle(.blue)
                            .font(.title2)
                        VStack(alignment: .leading) {
                            Text(mod.name)
                                .font(.body.bold())
                            Text("v\(mod.version)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(mod.installedAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            withAnimation {
                                viewModel.removeMod(mod)
                            }
                        } label: {
                            Label("Удалить", systemImage: "trash.fill")
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
}

// MARK: - Mod Card

struct ModCard: View {
    let mod: ModrinthProject
    let onDownload: () -> Void
    @EnvironmentObject var modsVM: ModsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray5))
                    .frame(height: 80)

                if let iconURL = URL(string: mod.iconUrl ?? "") {
                    AsyncImage(url: iconURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 48, height: 48)
                                .cornerRadius(8)
                        case .failure:
                            Image(systemName: "puzzlepiece.fill")
                                .font(.title)
                                .foregroundStyle(.secondary)
                        case .empty:
                            ProgressView()
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Image(systemName: "puzzlepiece.fill")
                        .font(.title)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)

            Text(mod.title)
                .font(.subheadline.bold())
                .lineLimit(2)

            Text(mod.authorName)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            HStack(spacing: 12) {
                Label("\(formatDownloads(mod.downloads))", systemImage: "arrow.down.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Скачать", action: onDownload)
                    .buttonStyle(MiniButtonStyle())
            }
            .padding(.top, 4)
        }
        .padding(10)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color(.systemGray4), lineWidth: 1)
        )
    }

    private func formatDownloads(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000)
        }
        return "\(count)"
    }
}

struct MiniButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(configuration.isPressed ? 0.7 : 1.0))
            .cornerRadius(8)
    }
}
