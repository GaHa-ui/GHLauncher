import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @EnvironmentObject var settings: AppSettingsViewModel

    init() {
        _viewModel = StateObject(wrappedValue: SettingsViewModel(settings: AppSettingsViewModel.shared ?? AppSettingsViewModel()))
    }

    var body: some View {
        Form {
            // Screen resolution
            Section {
                Picker("Разрешение экрана", selection: $viewModel.resolutionIndex) {
                    ForEach(viewModel.resolutionPresets) { preset in
                        Text(preset.description).tag(preset.rawValue)
                    }
                }
                .pickerStyle(.inline)
            } header: {
                Label("Разрешение", systemImage: "rectangle.pixelspread")
            } footer: {
                let res = ResolutionPreset(rawValue: viewModel.resolutionIndex)?.dimensions
                    ?? ResolutionPreset.res720p.dimensions
                Text("\(res.width)×\(res.height) пикселей")
            }

            // JVM memory
            Section {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Выделенная память")
                        Spacer()
                        Text("\(viewModel.javaAllocMB) МБ")
                            .foregroundStyle(.secondary)
                    }
                    Slider(
                        value: Binding(
                            get: { Double(viewModel.javaAllocMB) },
                            set: { viewModel.javaAllocMB = Int($0) }
                        ),
                        in: 512...4096,
                        step: 256
                    )
                    .accentColor(.blue)

                    Text("Рекомендуется: 2048 МБ для современных версий")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Label("Память JVM", systemImage: "memorychip")
            }

            // JVM Arguments
            Section {
                TextEditor(text: $viewModel.jvmArgs)
                    .frame(minHeight: 60)
                    .font(.system(.body, design: .monospaced))
            } header: {
                Label("JVM аргументы", systemImage: "terminal")
            } footer: {
                Text("Дополнительные параметры запуска Java. Каждый аргумент разделяется пробелом.")
            }

            // Control settings
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Чувствительность")
                        Spacer()
                        Text("\(Int(viewModel.controlSensitivity))")
                            .foregroundStyle(.secondary)
                    }
                    Slider(
                        value: $viewModel.controlSensitivity,
                        in: 10...100,
                        step: 5
                    )
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Дальность прорисовки")
                        Spacer()
                        Text("\(viewModel.renderDistance) чанков")
                            .foregroundStyle(.secondary)
                    }
                    Stepper(
                        value: $viewModel.renderDistance,
                        in: 2...16,
                        step: 1
                    ) {
                        EmptyView()
                    }
                }
            } header: {
                Label("Управление", systemImage: "gamecontroller")
            } footer: {
                Text("Настройки влияют на внутриигровой опыт и производительность")
            }

            // Username
            Section {
                TextField("Никнейм", text: $settings.username)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            } header: {
                Label("Аккаунт", systemImage: "person.fill")
            }

            // Reset
            Section {
                Button(role: .destructive) {
                    viewModel.resetToDefaults()
                } label: {
                    Label("Сбросить настройки по умолчанию", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Настройки")
    }
}
