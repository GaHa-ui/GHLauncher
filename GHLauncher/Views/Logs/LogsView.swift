import SwiftUI

struct LogsView: View {
    @State private var selectedLog = LogType.latest
    @State private var logContent = ""
    @State private var loading = false
    @State private var showingCopied = false

    enum LogType: String, CaseIterable, Identifiable {
        case latest = "latest.log"
        case lastLaunch = "lastlaunch.log"
        case debug = "debug.log"

        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Log selector
                Picker("Лог", selection: $selectedLog) {
                    ForEach(LogType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .onChange(of: selectedLog) { loadLog() }

                // Log content
                ScrollView {
                    if loading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if logContent.isEmpty {
                        Text("Лог пуст или не найден")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        Text(logContent)
                            .font(.system(.caption2, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .textSelection(.enabled)
                    }
                }
                .background(Color(.systemBackground))
            }
            .navigationTitle("Логи")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Закрыть") {
                        // Dismiss via environment
                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        copyToClipboard()
                    } label: {
                        Image(systemName: showingCopied ? "checkmark" : "doc.on.doc")
                    }
                    .disabled(logContent.isEmpty)

                    Button {
                        clearLog()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .disabled(logContent.isEmpty)
                }
            }
            .task {
                loadLog()
            }
        }
    }

    private func loadLog() {
        loading = true
        logContent = ""

        let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let minecraftDir = docsDir.appendingPathComponent(".minecraft")
        let logsDir = minecraftDir.appendingPathComponent("logs")
        let logURL = logsDir.appendingPathComponent(selectedLog.rawValue)

        do {
            logContent = try String(contentsOf: logURL, encoding: .utf8)
        } catch {
            // Log not found
            logContent = ""
        }

        loading = false
    }

    private func copyToClipboard() {
        UIPasteboard.general.string = logContent
        showingCopied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showingCopied = false
        }
    }

    private func clearLog() {
        do {
            let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let logsDir = docsDir
                .appendingPathComponent(".minecraft")
                .appendingPathComponent("logs")
            let logURL = logsDir.appendingPathComponent(selectedLog.rawValue)
            try "".write(to: logURL, atomically: true, encoding: .utf8)
            logContent = ""
        } catch {
            print("Failed to clear log: \(error)")
        }
    }
}
