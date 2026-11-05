import SwiftUI
import Foundation
import AppKit

struct Finding: Identifiable, Sendable {
    let id = UUID()
    let name: String
    let detail: String
    let path: String
}

@MainActor
final class ScanModel: ObservableObject {
    @Published var scanning = false
    @Published var checked = 0
    @Published var findings: [Finding] = []
    @Published var message = "Ready to scan your Downloads folder."

    func scan() {
        guard !scanning else { return }
        scanning = true
        checked = 0
        findings = []
        message = "Scanning Downloads…"
        Task.detached(priority: .userInitiated) {
            let folder = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads")
            let keys: [URLResourceKey] = [.isRegularFileKey, .isDirectoryKey, .isSymbolicLinkKey, .fileSizeKey]
            var count = 0
            var hits: [Finding] = []
            let indicators = [
                ("Encoded shell pipeline", #"curl.{0,160}\|\s*(bash|sh)"#),
                ("Base64 decoding command", #"base64\s+(-d|--decode)"#),
                ("Script execution command", #"osascript\s+-e"#),
                ("Persistence-related command", #"launchctl\s+(load|bootstrap|enable)"#),
                ("Credential lookup command", #"security\s+find-(generic|internet)-password"#)
            ]
            if let enumerator = FileManager.default.enumerator(at: folder, includingPropertiesForKeys: keys, options: [.skipsHiddenFiles]) {
                for case let url as URL in enumerator {
                    autoreleasepool {
                        guard let values = try? url.resourceValues(forKeys: Set(keys)),
                              values.isSymbolicLink != true else { return }
                        if values.isDirectory == true && url.pathExtension.lowercased() == "app" {
                            return
                        }
                        guard values.isRegularFile == true else { return }
                        count += 1
                        let ext = url.pathExtension.lowercased()
                        guard ["sh","command","py","js","jsx","applescript","scpt"].contains(ext),
                              (values.fileSize ?? 0) <= 2_097_152,
                              let data = try? Data(contentsOf: url),
                              let source = String(data: data, encoding: .utf8) else { return }
                        let matched = indicators.filter {
                            source.range(of: $0.1, options: [.regularExpression, .caseInsensitive]) != nil
                        }
                        if matched.count >= 2 {
                            hits.append(Finding(name: url.lastPathComponent,
                                                detail: matched.map { $0.0 }.joined(separator: ", "),
                                                path: url.path))
                        }
                    }
                }
            }
            await MainActor.run {
                self.checked = count
                self.findings = hits
                self.scanning = false
                self.message = hits.isEmpty
                    ? "Scan complete. No heuristic matches found."
                    : "Scan complete. Review the items below."
            }
        }
    }

    func reveal(_ finding: Finding) {
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: finding.path)])
    }
}

@main
struct ProtecterApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
                .frame(minWidth: 680, minHeight: 520)
        }
        .windowStyle(.titleBar)
    }
}

struct MainView: View {
    @StateObject private var model = ScanModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 13) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(.cyan)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Protecter").font(.system(size: 29, weight: .bold))
                    Text("Local Downloads security review").foregroundStyle(.secondary)
                }
                Spacer()
                Label(model.scanning ? "Scanning" : "Ready",
                      systemImage: model.scanning ? "arrow.triangle.2.circlepath" : "checkmark.shield")
                    .foregroundStyle(model.scanning ? .orange : .green)
            }

            HStack(spacing: 12) {
                metric("Files checked", value: "\(model.checked)", symbol: "doc.text.magnifyingglass")
                metric("Items to review", value: "\(model.findings.count)", symbol: "exclamationmark.shield")
            }

            HStack {
                Button {
                    model.scan()
                } label: {
                    Label("Scan Downloads", systemImage: "magnifyingglass")
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.scanning)
                Spacer()
                Text(model.message).font(.callout).foregroundStyle(.secondary)
            }

            Text("Review results").font(.headline)
            if model.findings.isEmpty && !model.scanning {
                ContentUnavailableView("No flagged scripts", systemImage: "checkmark.shield",
                                       description: Text("Run a scan to check common script files for combinations of suspicious command indicators."))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(model.findings) { item in
                    HStack(alignment: .top) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name).fontWeight(.semibold)
                            Text(item.detail).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Reveal") { model.reveal(item) }.buttonStyle(.borderless)
                    }
                    .padding(.vertical, 3)
                }
            }

            Text("Protecter only reports heuristic matches; it does not delete, move, or modify files. This is not a full antivirus and may miss threats or flag legitimate scripts. Review results before taking action.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(22)
    }

    private func metric(_ title: String, value: String, symbol: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).font(.title2).foregroundStyle(.cyan)
            VStack(alignment: .leading, spacing: 2) {
                Text(value).font(.title2.bold()).monospacedDigit()
                Text(title).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 12))
    }
}
