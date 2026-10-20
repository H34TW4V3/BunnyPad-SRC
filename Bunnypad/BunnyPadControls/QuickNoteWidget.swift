import AppIntents
import SwiftUI
import WidgetKit

struct RecentFileItem: Identifiable, Hashable, Codable {
    var id: String { path.isEmpty ? name : path }
    let name: String
    let path: String
}

struct QuickNoteEntry: TimelineEntry {
    let date: Date
    let theme: String
    let recentFiles: [RecentFileItem]

    var logoImageName: String {
        theme == "skeuomorphic" ? "BunnyPadLegacyLogo" : "BunnyPadLogo"
    }

    var isSkeuomorphic: Bool {
        theme == "skeuomorphic"
    }
}

private enum WidgetDataLoader {
    static let sharedSuite = "group.com.charasoft.bunnypad"
    static let sharedFilePath = "/Users/Shared/com.charasoft.bunnypad/widget_state.json"

    static func load() -> (theme: String, recentFiles: [RecentFileItem]) {
        var theme = "gradient"
        var recentFiles: [RecentFileItem] = []

        // 1. Check /Users/Shared
        if let data = try? Data(contentsOf: URL(fileURLWithPath: sharedFilePath)),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let t = json["theme"] as? String, !t.isEmpty {
                theme = t
            }
            if let files = json["recentFiles"] as? [[String: String]] {
                recentFiles = files.compactMap { dict in
                    guard let name = dict["name"], let path = dict["path"] else { return nil }
                    return RecentFileItem(name: name, path: path)
                }
            }
            return (theme, recentFiles)
        }

        // 2. Check App Group UserDefaults
        if let groupDefaults = UserDefaults(suiteName: sharedSuite) {
            if let t = groupDefaults.string(forKey: "appTheme"), !t.isEmpty {
                theme = t
            }
            if let data = groupDefaults.data(forKey: "recentFiles"),
               let files = try? JSONDecoder().decode([[String: String]].self, from: data) {
                recentFiles = files.compactMap { dict in
                    guard let name = dict["name"], let path = dict["path"] else { return nil }
                    return RecentFileItem(name: name, path: path)
                }
            }
        }

        // 3. Standard UserDefaults fallback
        if let t = UserDefaults.standard.string(forKey: "appTheme"), !t.isEmpty {
            theme = t
        }

        return (theme, recentFiles)
    }
}

struct QuickNoteProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickNoteEntry {
        QuickNoteEntry(
            date: Date(),
            theme: "gradient",
            recentFiles: [
                RecentFileItem(name: "Welcome.txt", path: ""),
                RecentFileItem(name: "Ideas.md", path: "")
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (QuickNoteEntry) -> Void) {
        let (theme, files) = WidgetDataLoader.load()
        completion(QuickNoteEntry(date: Date(), theme: theme, recentFiles: files))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickNoteEntry>) -> Void) {
        let (theme, files) = WidgetDataLoader.load()
        let entry = QuickNoteEntry(date: Date(), theme: theme, recentFiles: files)
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct QuickNoteWidgetView: View {
    var entry: QuickNoteEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemMedium:
            mediumView
        default:
            smallView
        }
    }

    // MARK: - Small View
    private var smallView: some View {
        Button(intent: OpenQuickNoteIntent()) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    Image(entry.logoImageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 38, height: 38)
                        .clipShape(RoundedRectangle(cornerRadius: 8.5, style: .continuous))
                        .shadow(color: .black.opacity(entry.isSkeuomorphic ? 0.5 : 0.35), radius: 3, x: 0, y: 1.5)

                    Spacer()

                    if entry.isSkeuomorphic {
                        // Classic stitched/embossed badge
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(red: 0.95, green: 0.82, blue: 0.45), Color(red: 0.75, green: 0.55, blue: 0.20)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 30, height: 30)
                                .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
                            Image(systemName: "pencil")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Color(red: 0.25, green: 0.15, blue: 0.05))
                        }
                    } else {
                        // Modern gold pill
                        ZStack {
                            Circle()
                                .fill(Color(red: 1, green: 0.77, blue: 0.23).opacity(0.25))
                                .frame(width: 32, height: 32)
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Color(red: 1, green: 0.77, blue: 0.23))
                        }
                    }
                }

                Spacer()

                VStack(alignment: .leading, spacing: 2) {
                    Text("Quick Note")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(entry.isSkeuomorphic ? Color(red: 0.96, green: 0.95, blue: 0.90) : .white)
                        .shadow(color: entry.isSkeuomorphic ? .black.opacity(0.6) : .clear, radius: 1, x: 0, y: 1)
                    Text(entry.isSkeuomorphic ? "Snow Leopard Notes" : "Tap to write in BunnyPad")
                        .font(.caption2)
                        .foregroundStyle(entry.isSkeuomorphic ? Color(red: 0.85, green: 0.82, blue: 0.76) : .white.opacity(0.75))
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Medium View
    private var mediumView: some View {
        HStack(spacing: 12) {
            // Left column: New Quick Note
            Button(intent: OpenQuickNoteIntent()) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        Image(entry.logoImageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 36, height: 36)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .shadow(color: .black.opacity(entry.isSkeuomorphic ? 0.5 : 0.35), radius: 3, x: 0, y: 1.5)

                        VStack(alignment: .leading, spacing: 1) {
                            Text("BunnyPad")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(entry.isSkeuomorphic ? Color(red: 0.95, green: 0.82, blue: 0.45) : Color(red: 1, green: 0.77, blue: 0.23))
                            Text(entry.isSkeuomorphic ? "Classic Notes" : "Fast Plain Text")
                                .font(.caption2)
                                .foregroundStyle(entry.isSkeuomorphic ? Color(red: 0.85, green: 0.82, blue: 0.76) : .white.opacity(0.7))
                        }
                    }

                    Spacer()

                    VStack(alignment: .leading, spacing: 2) {
                        Text("New Quick Note")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(entry.isSkeuomorphic ? Color(red: 0.96, green: 0.95, blue: 0.90) : .white)
                            .shadow(color: entry.isSkeuomorphic ? .black.opacity(0.6) : .clear, radius: 1, x: 0, y: 1)
                        Text("Click to create a new note")
                            .font(.caption2)
                            .foregroundStyle(entry.isSkeuomorphic ? Color(red: 0.85, green: 0.82, blue: 0.76) : .white.opacity(0.75))
                    }
                }
                .padding(.vertical, 12)
                .padding(.leading, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            // Divider
            if entry.isSkeuomorphic {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.black.opacity(0.5), Color.white.opacity(0.15)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 1.5)
                    .padding(.vertical, 10)
            } else {
                Divider()
                    .background(Color.white.opacity(0.2))
                    .padding(.vertical, 10)
            }

            // Right column: Recent Files
            recentFilesColumn
                .padding(.vertical, 10)
                .padding(.trailing, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Recent Files Column
    private var recentFilesColumn: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.caption.bold())
                Text("Recent Files")
                    .font(.caption.bold())
                Spacer()
            }
            .foregroundStyle(entry.isSkeuomorphic ? Color(red: 0.95, green: 0.82, blue: 0.45) : Color(red: 1, green: 0.77, blue: 0.23))

            if entry.recentFiles.isEmpty {
                // Empty state
                VStack(alignment: .center, spacing: 4) {
                    Spacer()
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 20))
                        .foregroundStyle(entry.isSkeuomorphic ? Color(red: 0.80, green: 0.77, blue: 0.70) : .white.opacity(0.5))
                    Text("No recent notes")
                        .font(.caption.bold())
                        .foregroundStyle(entry.isSkeuomorphic ? Color(red: 0.92, green: 0.90, blue: 0.85) : .white.opacity(0.85))
                    Text("Files opened in BunnyPad will appear here.")
                        .font(.system(size: 9))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(entry.isSkeuomorphic ? Color(red: 0.75, green: 0.72, blue: 0.65) : .white.opacity(0.6))
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                // Files list
                VStack(spacing: 4) {
                    ForEach(Array(entry.recentFiles.prefix(3)), id: \.id) { file in
                        Button(intent: OpenQuickNoteIntent(filePath: file.path)) {
                            HStack(spacing: 6) {
                                Image(systemName: "doc.text.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(entry.isSkeuomorphic ? Color(red: 0.95, green: 0.82, blue: 0.45) : Color(red: 1, green: 0.77, blue: 0.23))

                                Text(file.name)
                                    .font(.system(size: 11, weight: .medium))
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .foregroundStyle(entry.isSkeuomorphic ? Color(red: 0.95, green: 0.93, blue: 0.88) : .white)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundStyle(entry.isSkeuomorphic ? Color(red: 0.75, green: 0.72, blue: 0.65) : .white.opacity(0.4))
                            }
                            .padding(.horizontal, 7)
                            .padding(.vertical, 5)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(entry.isSkeuomorphic ? Color.black.opacity(0.25) : Color.white.opacity(0.08))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .strokeBorder(entry.isSkeuomorphic ? Color.white.opacity(0.08) : Color.white.opacity(0.12), lineWidth: 0.5)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }
}

struct QuickNoteWidget: Widget {
    let kind: String = "com.charasoft.bunnypad.quick-note-widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickNoteProvider()) { entry in
            QuickNoteWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    if entry.isSkeuomorphic {
                        // Snow Leopard / OS X classic dark linen
                        ZStack {
                            LinearGradient(
                                colors: [
                                    Color(red: 0.22, green: 0.23, blue: 0.26),
                                    Color(red: 0.14, green: 0.15, blue: 0.17)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            // Subtle texture highlight
                            Rectangle()
                                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                        }
                    } else {
                        // Modern BunnyPad violet/plum gradient
                        LinearGradient(
                            colors: [
                                Color(red: 0.12, green: 0.14, blue: 0.22),
                                Color(red: 0.24, green: 0.16, blue: 0.32),
                                Color(red: 0.36, green: 0.20, blue: 0.30)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
        }
        .configurationDisplayName("Quick Note")
        .description("Instantly open BunnyPad and create a new quick note.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
