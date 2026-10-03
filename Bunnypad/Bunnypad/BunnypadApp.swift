import AppIntents
#if os(macOS)
import AppKit
#endif
import SwiftUI
import UniformTypeIdentifiers

let bunnyPadRepositoryURL = URL(string: "https://github.com/GSYT-Productions/BunnyPad-SRC") ?? URL(fileURLWithPath: "/")

struct CreateQuickNoteIntent: AppIntent {
    static var title: LocalizedStringResource = "Create Quick Note"
    static var description = IntentDescription("Creates a new quick note in BunnyPad.")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: .createQuickNoteRequested, object: nil)
        return .result()
    }
}

extension NSNotification.Name {
    static let createQuickNoteRequested = NSNotification.Name("createQuickNoteRequested")
}

struct BunnyPadShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CreateQuickNoteIntent(),
            phrases: [
                "Create a quick note in \(.applicationName)",
                "Take a quick note in \(.applicationName)",
                "New quick note in \(.applicationName)"
            ],
            shortTitle: "Create Quick Note",
            systemImageName: "bolt.fill"
        )
    }
}

@main
struct BunnypadApp: App {
    var body: some Scene {
        #if os(macOS)
        DocumentGroup(newDocument: { NoteDocument() }) { configuration in
            ContentView(document: configuration.document)
        }
        .defaultSize(width: 860, height: 620)
        .commands {
            EditorCommands()
        }

        Settings {
            SettingsView()
        }

        Window("About BunnyPad", id: "about") {
            AboutView()
        }
        .windowResizability(.contentSize)
        #else
        WindowGroup {
            iOSHomeView()
        }
        #endif
    }
}

#if os(iOS)
private struct NoteDocumentWrapper: Identifiable, Hashable {
    let id = UUID()
    let document: NoteDocument

    static func == (lhs: NoteDocumentWrapper, rhs: NoteDocumentWrapper) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct iOSHomeView: View {
    @State private var activeWrapper: NoteDocumentWrapper? = nil
    @State private var showSettings = false
    @State private var showAbout = false
    @State private var showFileImporter = false
    @AppStorage("appTheme") private var appTheme = "gradient"
    @AppStorage("showQuickNoteTile") private var showQuickNoteTile = true

    var body: some View {
        NavigationStack {
            ZStack {
                BunnyTheme.backgroundGradient(for: appTheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        Spacer(minLength: 30)

                        // Header with Logo
                        VStack(spacing: 14) {
                            Image("AboutLogo")
                                .renderingMode(.original)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 110, height: 110)
                                .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 6)

                            Text("BunnyPad")
                                .font(.system(size: 38, weight: .bold, design: .rounded))
                                .foregroundStyle(BunnyTheme.textColor(for: appTheme))

                            Text("The Newest and Cutest way to take notes")
                                .font(.subheadline)
                                .foregroundStyle(BunnyTheme.textColor(for: appTheme).opacity(0.85))
                                .multilineTextAlignment(.center)
                        }

                        // Main Action Tiles: New Note & Open File
                        VStack(spacing: 14) {
                            HStack(spacing: 12) {
                                Button {
                                    let newDoc = NoteDocument()
                                    activeWrapper = NoteDocumentWrapper(document: newDoc)
                                } label: {
                                    VStack(spacing: 8) {
                                        Image(systemName: "square.and.pencil")
                                            .font(.title)
                                        Text("New Note")
                                            .font(.subheadline.bold())
                                    }
                                    .foregroundStyle(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(BunnyTheme.gold, in: RoundedRectangle(cornerRadius: 18))
                                    .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
                                }

                                Button {
                                    showFileImporter = true
                                } label: {
                                    VStack(spacing: 8) {
                                        Image(systemName: "folder.fill")
                                            .font(.title)
                                        Text("Open File")
                                            .font(.subheadline.bold())
                                    }
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 18))
                                    .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.white.opacity(0.3), lineWidth: 1))
                                    .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
                                }
                            }

                            // Quick Note Tile (configurable in Quick Settings)
                            if showQuickNoteTile {
                                Button {
                                    let doc = NoteDocument()
                                    let timestamp = Date.now.formatted(date: .abbreviated, time: .shortened)
                                    doc.content = TextSnapshot(text: "--- Quick Note (\(timestamp)) ---\n\n")
                                    activeWrapper = NoteDocumentWrapper(document: doc)
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: "bolt.fill")
                                            .font(.title2)
                                            .foregroundStyle(BunnyTheme.gold)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Quick Note Tile")
                                                .font(.headline)
                                                .foregroundStyle(.white)
                                            Text("Instant scratchpad for quick ideas")
                                                .font(.caption)
                                                .foregroundStyle(.white.opacity(0.8))
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(.white.opacity(0.5))
                                    }
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 14)
                                    .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 18))
                                    .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(BunnyTheme.gold.opacity(0.5), lineWidth: 1))
                                    .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
                                }
                            }
                        }
                        .padding(.horizontal, 24)

                        // Quick Settings & About Footer Buttons
                        HStack(spacing: 20) {
                            Button {
                                showSettings = true
                            } label: {
                                Label("Settings", systemImage: "gearshape.fill")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(BunnyTheme.gold)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 12)
                                    .background(.white.opacity(0.15), in: Capsule())
                            }

                            Button {
                                showAbout = true
                            } label: {
                                Label("About", systemImage: "info.circle.fill")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(BunnyTheme.gold)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 12)
                                    .background(.white.opacity(0.15), in: Capsule())
                            }
                        }
                        .padding(.top, 12)

                        Spacer(minLength: 30)
                    }
                }
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.plainText],
                allowsMultipleSelection: false
            ) { result in
                guard let urls = try? result.get(), let url = urls.first else { return }
                guard url.startAccessingSecurityScopedResource() else { return }
                defer { url.stopAccessingSecurityScopedResource() }
                if let data = try? Data(contentsOf: url),
                   let snapshot = try? TextSnapshot.decode(data) {
                    let doc = NoteDocument()
                    doc.content = snapshot
                    activeWrapper = NoteDocumentWrapper(document: doc)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .createQuickNoteRequested)) { _ in
                let doc = NoteDocument()
                let timestamp = Date.now.formatted(date: .abbreviated, time: .shortened)
                doc.content = TextSnapshot(text: "--- Quick Note (\(timestamp)) ---\n\n")
                activeWrapper = NoteDocumentWrapper(document: doc)
            }
            .navigationDestination(item: $activeWrapper) { wrapper in
                ContentView(document: wrapper.document, onBack: { activeWrapper = nil })
                    .navigationBarBackButtonHidden(true)
            }
            .sheet(isPresented: $showSettings) {
                NavigationStack {
                    SettingsView(onQuickNote: {
                        showSettings = false
                        let doc = NoteDocument()
                        let timestamp = Date.now.formatted(date: .abbreviated, time: .shortened)
                        doc.content = TextSnapshot(text: "--- Quick Note (\(timestamp)) ---\n\n")
                        activeWrapper = NoteDocumentWrapper(document: doc)
                    })
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { showSettings = false }
                                .foregroundStyle(BunnyTheme.gold)
                        }
                    }
                }
            }
            .sheet(isPresented: $showAbout) {
                NavigationStack {
                    AboutView()
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { showAbout = false }
                                    .foregroundStyle(BunnyTheme.gold)
                            }
                        }
                }
            }
        }
    }
}
#endif

#if os(macOS)
struct EditorCommands: Commands {
    @FocusedValue(\.editorSession) private var session
    @Environment(\.openWindow) private var openWindow
    @AppStorage("wordWrap") private var wordWrap = true
    @AppStorage("showStatusBar") private var showStatusBar = true

    var body: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button("About BunnyPad") { openWindow(id: "about") }
        }
        CommandGroup(after: .saveItem) {
            Divider()
            Button("Print…") { session?.printDocument() }
                .keyboardShortcut("p")
                .disabled(session == nil)
        }
        CommandGroup(after: .textEditing) {
            Divider()
            Button("Find…") { session?.find() }.keyboardShortcut("f")
            Button("Find and Replace…") { session?.find(replacing: true) }
                .keyboardShortcut("f", modifiers: [.command, .option])
            Button("Go to Line…") { session?.showGoToLine = true }
                .keyboardShortcut("l")
            Divider()
            Button("Insert Date and Time") { session?.insertDate() }
                .keyboardShortcut("d", modifiers: [.command, .shift])
        }
        CommandMenu("Format") {
            Toggle("Word Wrap", isOn: $wordWrap)
            Button("Font…") {
                guard let textView = session?.textView else { return }
                textView.window?.makeFirstResponder(textView)
                NSFontManager.shared.orderFrontFontPanel(nil)
            }
            .keyboardShortcut("t")
            .disabled(session == nil)
            Button("Use UTF-8 Encoding") {
                (session?.textView as? BunnyTextView)?.useUTF8(nil)
            }
            .disabled(session == nil)
        }
        CommandGroup(after: .toolbar) {
            Toggle("Show Status Bar", isOn: $showStatusBar)
        }
        CommandGroup(replacing: .help) {
            Link("BunnyPad Source and Help", destination: bunnyPadRepositoryURL)
        }
    }
}
#endif
