import AppIntents
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
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

// MARK: - Dynamic App Icon Support
@MainActor
func updatePlatformAppIcon(for theme: String) {
    #if os(macOS)
    let bundlePath = Bundle.main.bundlePath
    if theme == "skeuomorphic" {
        let iconImage: NSImage? = NSImage(named: "MacLegacyLogo")
            ?? NSImage(named: "BunnyPadMacLegacyLogo")
            ?? (Bundle.main.path(forResource: "BunnyPadMacLegacyLogo", ofType: "png").flatMap { NSImage(contentsOfFile: $0) })
            ?? (Bundle.main.path(forResource: "BunnyPadLegacyLogo", ofType: "png").flatMap { NSImage(contentsOfFile: $0) })
        if let iconImage {
            NSApplication.shared.applicationIconImage = iconImage
            _ = NSWorkspace.shared.setIcon(iconImage, forFile: bundlePath, options: [])
        }
    } else {
        NSApplication.shared.applicationIconImage = nil
        _ = NSWorkspace.shared.setIcon(nil, forFile: bundlePath, options: [])
    }
    #elseif os(iOS)
    guard UIApplication.shared.supportsAlternateIcons else { return }
    let currentIcon = UIApplication.shared.alternateIconName
    if theme == "skeuomorphic" {
        if currentIcon != "LegacyIcon" {
            UIApplication.shared.setAlternateIconName("LegacyIcon") { error in
                if let error = error {
                    print("Error setting legacy alternate icon: \(error.localizedDescription)")
                }
            }
        }
    } else {
        if currentIcon != nil {
            UIApplication.shared.setAlternateIconName(nil) { error in
                if let error = error {
                    print("Error resetting alternate icon to default: \(error.localizedDescription)")
                }
            }
        }
    }
    #endif
}

@main
struct BunnypadApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor(BunnyPadAppDelegate.self) private var appDelegate
    @AppStorage("showMenuBarItem") private var showMenuBarItem = true
    #endif
    @AppStorage("appTheme") private var appTheme = "gradient"

    init() {
        // Retire the old dark/light choices without changing the Legacy preference.
        let defaults = UserDefaults.standard
        if let theme = defaults.string(forKey: "appTheme"),
           theme != "gradient" && theme != "skeuomorphic" {
            defaults.set("gradient", forKey: "appTheme")
        }
    }

    var body: some Scene {
        #if os(macOS)
        DocumentGroup(newDocument: { NoteDocument() }) { configuration in
            ContentView(document: configuration.document)
        }
        .defaultSize(width: 860, height: 620)
        .commands {
            EditorCommands()
        }
        .onChange(of: appTheme) { _, newTheme in
            updatePlatformAppIcon(for: newTheme)
        }

        Settings {
            SettingsView()
                .onChange(of: appTheme) { _, newTheme in
                    updatePlatformAppIcon(for: newTheme)
                }
        }

        MenuBarExtra(isInserted: $showMenuBarItem) {
            BunnyPadMenuBarContent()
        } label: {
            Image(nsImage: BunnyPadMenuBarIcon.image)
                .accessibilityLabel("BunnyPad")
        }
        .menuBarExtraStyle(.menu)
        .onChange(of: showMenuBarItem) { _, isVisible in
            MenuBarLoginItem.configure(isVisible: isVisible, userChangedPreference: true)
        }

        Window("About BunnyPad", id: "about") {
            AboutView()
        }
        .windowResizability(.contentSize)
        #else
        WindowGroup {
            iOSHomeView()
                .onAppear {
                    updatePlatformAppIcon(for: appTheme)
                }
                .onChange(of: appTheme) { _, newTheme in
                    updatePlatformAppIcon(for: newTheme)
                }
        }
        #endif
    }
}

#if os(macOS)
private final class BunnyPadAppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        // Skip SwiftUI's default document picker; create the editor after scene setup.
        false
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let showMenuBarItem = UserDefaults.standard.object(forKey: "showMenuBarItem") as? Bool ?? true
        MenuBarLoginItem.configure(isVisible: showMenuBarItem)
        let theme = UserDefaults.standard.string(forKey: "appTheme") ?? "gradient"
        updatePlatformAppIcon(for: theme)
        DispatchQueue.main.async {
            let controller = NSDocumentController.shared
            guard controller.documents.isEmpty else { return }
            controller.newDocument(nil)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        MenuBarLoginItem.refreshStatus()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        guard !flag else { return true }
        let controller = NSDocumentController.shared
        if controller.documents.isEmpty {
            controller.newDocument(nil)
        } else {
            controller.documents.forEach { $0.showWindows() }
        }
        return true
    }
}

private enum BunnyPadMenuBarIcon {
    static let image: NSImage = {
        guard let source = NSImage(named: "MenuBarBunny") else {
            return NSImage(systemSymbolName: "hare.fill", accessibilityDescription: "BunnyPad") ?? NSImage()
        }
        // MenuBarExtra uses the underlying NSImage size, not SwiftUI frame modifiers.
        let size = NSSize(width: 22, height: 22)
        let image = NSImage(size: size, flipped: false) { destination in
            let scale = min(destination.width / source.size.width, destination.height / source.size.height)
            let drawingSize = NSSize(width: source.size.width * scale, height: source.size.height * scale)
            let drawingRect = NSRect(
                x: destination.midX - drawingSize.width / 2,
                y: destination.midY - drawingSize.height / 2,
                width: drawingSize.width,
                height: drawingSize.height
            )
            source.draw(in: drawingRect, from: .zero, operation: .sourceOver, fraction: 1)
            return true
        }
        image.isTemplate = false
        image.accessibilityDescription = "BunnyPad"
        return image
    }()
}

private struct BunnyPadMenuBarContent: View {
    var body: some View {
        Button("New Quick Note", systemImage: "square.and.pencil") {
            NSApp.activate(ignoringOtherApps: true)
            NSDocumentController.shared.newDocument(nil)
        }
        Divider()
        SettingsLink {
            Text("Settings…")
        }
        Divider()
        Button("Quit BunnyPad") {
            NSApp.terminate(nil)
        }
    }
}

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
    @State private var fileError: String?
    @State private var showFileError = false
    @AppStorage("appTheme") private var appTheme = "gradient"

    var body: some View {
        NavigationStack {
            ZStack {
                if appTheme == "skeuomorphic" {
                    IOS6LinenBackground()
                } else {
                    BunnyTheme.backgroundGradient(for: appTheme)
                        .ignoresSafeArea()
                }

                ScrollView {
                    VStack(spacing: 28) {
                        Spacer(minLength: 30)

                        // Header with Logo
                        VStack(spacing: 14) {
                            if appTheme == "skeuomorphic" {
                                IOS6GlossyAppIcon(size: 110)

                                Text("BunnyPad")
                                    .font(.system(size: 38, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .shadow(color: Color.black.opacity(0.85), radius: 0, x: 0, y: -1)

                                Text("The Newest and Cutest way to take notes")
                                    .font(.subheadline)
                                    .foregroundStyle(Color(white: 0.85))
                                    .shadow(color: Color.black.opacity(0.75), radius: 0, x: 0, y: -1)
                                    .multilineTextAlignment(.center)
                            } else {
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
                        }

                        // Main Action Tiles: New Note & Open File
                        VStack(spacing: 14) {
                            if appTheme == "skeuomorphic" {
                                HStack(spacing: 12) {
                                    IOS6GlossyActionTile(title: "New Note", icon: "square.and.pencil", isPrimary: true) {
                                        let newDoc = NoteDocument()
                                        activeWrapper = NoteDocumentWrapper(document: newDoc)
                                    }

                                    IOS6GlossyActionTile(title: "Open File", icon: "folder.fill", isPrimary: false) {
                                        showFileImporter = true
                                    }
                                }
                            } else {
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
                                        .background(
                                            Color.white.opacity(0.18),
                                            in: RoundedRectangle(cornerRadius: 18)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 18)
                                                .strokeBorder(.white.opacity(0.3), lineWidth: 1)
                                        )
                                        .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
                                    }
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
                                    .background(
                                        appTheme == "skeuomorphic"
                                            ? AnyShapeStyle(
                                                LinearGradient(
                                                    colors: [Color(red: 0.32, green: 0.22, blue: 0.16), Color(red: 0.18, green: 0.10, blue: 0.06)],
                                                    startPoint: .top, endPoint: .bottom
                                                )
                                            )
                                            : AnyShapeStyle(Color.white.opacity(0.15)),
                                        in: Capsule()
                                    )
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(appTheme == "skeuomorphic" ? Color.black.opacity(0.7) : .clear, lineWidth: 1)
                                    )
                                    .shadow(color: Color.black.opacity(appTheme == "skeuomorphic" ? 0.35 : 0), radius: 2, x: 0, y: 1)
                            }

                            Button {
                                showAbout = true
                            } label: {
                                Label("About", systemImage: "info.circle.fill")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(BunnyTheme.gold)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 12)
                                    .background(
                                        appTheme == "skeuomorphic"
                                            ? AnyShapeStyle(
                                                LinearGradient(
                                                    colors: [Color(red: 0.32, green: 0.22, blue: 0.16), Color(red: 0.18, green: 0.10, blue: 0.06)],
                                                    startPoint: .top, endPoint: .bottom
                                                )
                                            )
                                            : AnyShapeStyle(Color.white.opacity(0.15)),
                                        in: Capsule()
                                    )
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(appTheme == "skeuomorphic" ? Color.black.opacity(0.7) : .clear, lineWidth: 1)
                                    )
                                    .shadow(color: Color.black.opacity(appTheme == "skeuomorphic" ? 0.35 : 0), radius: 2, x: 0, y: 1)
                            }
                        }
                        .padding(.top, 12)

                        Spacer(minLength: 30)
                    }
                }
            }
            .onAppear {
                updatePlatformAppIcon(for: appTheme)
                let args = ProcessInfo.processInfo.arguments
                if args.contains("-screenshotEditor") {
                    let sampleDoc = NoteDocument()
                    sampleDoc.content = TextSnapshot(text: """
                    # Welcome to BunnyPad for iPadOS! 🐰✨

                    BunnyPad is the newest and cutest way to capture notes, ideas, code snippets, and plain text documents seamlessly across all your Apple devices.

                    Features:
                    • Native iPadOS & macOS multiplatform experience
                    • Floating gold pill toolbar with instant text tools
                    • Dynamic theme gradients: Bunny Gradient, Dark & Light
                    • Custom window transparency and liquid glass modals
                    • Built-in Siri & Apple Shortcuts integration ("Create Quick Note")
                    • Plain text file import & export with zero lock-in

                    Enjoy taking notes with BunnyPad!
                    """)
                    activeWrapper = NoteDocumentWrapper(document: sampleDoc)
                } else if args.contains("-screenshotSettings") {
                    showSettings = true
                }
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: NoteDocument.readableContentTypes,
                allowsMultipleSelection: false
            ) { result in
                do {
                    guard let url = try result.get().first else { return }
                    let scoped = url.startAccessingSecurityScopedResource()
                    defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                    let doc = NoteDocument()
                    doc.content = try TextSnapshot.decode(Data(contentsOf: url))
                    doc.suggestedFilename = url.lastPathComponent
                    activeWrapper = NoteDocumentWrapper(document: doc)
                } catch {
                    fileError = error.localizedDescription
                    showFileError = true
                }
            }
            .alert("Unable to Open File", isPresented: $showFileError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(fileError ?? "The file could not be opened.")
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
                if appTheme == "skeuomorphic" {
                    SettingsView(
                        onDismiss: { showSettings = false },
                        onQuickNote: {
                            showSettings = false
                            let doc = NoteDocument()
                            let timestamp = Date.now.formatted(date: .abbreviated, time: .shortened)
                            doc.content = TextSnapshot(text: "--- Quick Note (\(timestamp)) ---\n\n")
                            activeWrapper = NoteDocumentWrapper(document: doc)
                        }
                    )
                } else {
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
            }
            .sheet(isPresented: $showAbout) {
                if appTheme == "skeuomorphic" {
                    AboutView(theme: appTheme, onDismiss: { showAbout = false })
                } else {
                    NavigationStack {
                        AboutView(theme: appTheme)
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button("Done") { showAbout = false }
                                        .foregroundStyle(BunnyTheme.gold)
                                }
                            }
                    }
                }
            }
            .onChange(of: appTheme) { _, newTheme in
                updatePlatformAppIcon(for: newTheme)
            }
        }
    }
}
#endif
