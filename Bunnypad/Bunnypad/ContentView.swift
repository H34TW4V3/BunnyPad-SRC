#if os(macOS)
import AppKit
#endif
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    let document: NoteDocument
    var onBack: (() -> Void)? = nil
    @State private var session = EditorSession()
    @AppStorage("wordWrap") private var wordWrap = true
    @AppStorage("fontSize") private var fontSize = 16.0
    @AppStorage("showStatusBar") private var showStatusBar = true
    @AppStorage("appTheme") private var appTheme = "gradient"
    #if os(macOS)
    @AppStorage("windowOpacity") private var windowOpacity = 0.95
    #endif

    @State private var showSettings = false
    @State private var showAbout = false
    @State private var showExportSheet = false
    @State private var showSaveError = false
    @State private var saveError = ""

    var body: some View {
        ZStack {
            BunnyTheme.backgroundGradient(for: appTheme)
                .ignoresSafeArea()

            if appTheme == "skeuomorphic" {
                SkeuomorphicPaperBackground()
                    .ignoresSafeArea()
            }

            VStack(spacing: 0) {
                BunnyToolbar(
                    session: session,
                    showSettings: $showSettings,
                    showAbout: $showAbout,
                    onBack: onBack,
                    onSave: { showExportSheet = true },
                    theme: appTheme
                )
                NativeTextEditor(document: document, session: session, wrapsLines: wordWrap, fontSize: fontSize, theme: appTheme)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                if showStatusBar {
                    EditorStatusBar(session: session, content: document.content, theme: appTheme)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 520, minHeight: 340)
        .background(WindowConfigurator(opacity: windowOpacity))
        .ignoresSafeArea()
        #endif
        .preferredColorScheme(appTheme == "light" || appTheme == "skeuomorphic" ? .light : .dark)
        .focusedSceneValue(\.editorSession, session)
        .overlay {
            Rectangle().strokeBorder(.white.opacity(0.3), lineWidth: 1)
                .allowsHitTesting(false)
        }
        .fileExporter(
            isPresented: $showExportSheet,
            document: document,
            contentType: .data,
            defaultFilename: document.suggestedFilename
        ) { result in
            switch result {
            case .success(let url):
                document.suggestedFilename = url.lastPathComponent
            case .failure(let error):
                saveError = error.localizedDescription
                showSaveError = true
            }
        }
        .alert("Unable to Save File", isPresented: $showSaveError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveError)
        }
        .onReceive(NotificationCenter.default.publisher(for: .createQuickNoteRequested)) { _ in
            let timestamp = Date.now.formatted(date: .abbreviated, time: .shortened)
            document.content = TextSnapshot(text: "--- Quick Note (\(timestamp)) ---\n\n")
        }
        .sheet(isPresented: $session.showGoToLine) {
            GoToLineView(session: session)
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView(onQuickNote: {
                    showSettings = false
                    let timestamp = Date.now.formatted(date: .abbreviated, time: .shortened)
                    document.content = TextSnapshot(text: "--- Quick Note (\(timestamp)) ---\n\n")
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

#if os(macOS)
private struct WindowConfigurator: NSViewRepresentable {
    let opacity: Double

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            configureWindow(for: view)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            configureWindow(for: nsView)
        }
    }

    private func configureWindow(for view: NSView) {
        guard let window = view.window else { return }
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.styleMask.insert(.fullSizeContentView)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.alphaValue = CGFloat(opacity)
    }
}
#endif

private struct EditorStatusBar: View {
    let session: EditorSession
    let content: TextSnapshot
    var theme: String = "gradient"

    var body: some View {
        HStack {
            Text("Ln \(session.line), Col \(session.column)")
            Spacer()
            Text("\(content.text.count) characters")
            Divider().frame(height: 12)
            Text(content.encoding == .utf8 ? "UTF-8" : content.encoding == .isoLatin1 ? "Latin-1" : "UTF-16")
            Text(content.lineEnding == "\r\n" ? "CRLF" : content.lineEnding == "\r" ? "CR" : "LF")
        }
        .font(.caption)
        .foregroundStyle(theme == "skeuomorphic" ? Color(red: 0.95, green: 0.90, blue: 0.80) : .white)
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(BunnyTheme.barGradient(for: theme))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(theme == "skeuomorphic" ? Color(red: 0.85, green: 0.72, blue: 0.45).opacity(0.4) : .white.opacity(0.25))
                .frame(height: 1)
        }
    }
}

private struct GoToLineView: View {
    let session: EditorSession
    @Environment(\.dismiss) private var dismiss
    @State private var line = ""
    @State private var invalidLine = false
    @AppStorage("appTheme") private var appTheme = "gradient"

    var body: some View {
        ZStack {
            BunnyTheme.backgroundGradient(for: appTheme).ignoresSafeArea()

            VStack(spacing: 16) {
                Text("Go to Line").font(.headline).foregroundStyle(BunnyTheme.textColor(for: appTheme))
                TextField("Line number", text: $line)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 120)
                if invalidLine {
                    Text("Invalid line number").font(.caption).foregroundStyle(.red)
                }
                HStack {
                    Button("Cancel") { dismiss() }
                    Button("Go") {
                        guard let number = Int(line), session.go(to: number) else {
                            invalidLine = true
                            return
                        }
                        dismiss()
                    }
                    .foregroundStyle(BunnyTheme.textColor(for: appTheme))
                    .keyboardShortcut(.defaultAction)
                }
            }
            .tint(BunnyTheme.gold)
            .padding(24)
        }
    }
}

struct SettingsView: View {
    var onQuickNote: (() -> Void)? = nil
    @AppStorage("wordWrap") private var wordWrap = true
    @AppStorage("fontSize") private var fontSize = 16.0
    @AppStorage("showStatusBar") private var showStatusBar = true
    @AppStorage("appTheme") private var appTheme = "gradient"
    @AppStorage("showQuickNoteTile") private var showQuickNoteTile = true
    #if os(macOS)
    @AppStorage("windowOpacity") private var windowOpacity = 0.95
    @AppStorage("showMenuBarItem") private var showMenuBarItem = true
    @AppStorage("menuBarLoginStatus") private var menuBarLoginStatus = ""
    #endif

    var body: some View {
        ZStack {
            BunnyTheme.backgroundGradient(for: appTheme)
                .ignoresSafeArea()

            if appTheme == "skeuomorphic" {
                SkeuomorphicPaperBackground()
                    .ignoresSafeArea()
            }

            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundStyle(BunnyTheme.gold)
                        Text("Settings")
                            .font(.title2.bold())
                            .foregroundStyle(BunnyTheme.textColor(for: appTheme))
                        Spacer()
                    }
                    .padding(.bottom, 4)

                    // Quick Settings Liquid Glass / Stitched Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("QUICK SETTINGS")
                            .font(.caption.bold())
                            .foregroundStyle(BunnyTheme.gold)

                        #if os(macOS)
                        Toggle("Show BunnyPad in Menu Bar", isOn: $showMenuBarItem)
                            .tint(BunnyTheme.gold)
                        if showMenuBarItem {
                            Text(menuBarLoginStatus)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                                .fixedSize(horizontal: false, vertical: true)
                            HStack {
                                Button("Enable Launch at Login") {
                                    MenuBarLoginItem.configure(isVisible: true, userChangedPreference: true)
                                }
                                Button("Login Items Settings…") {
                                    MenuBarLoginItem.openSettings()
                                }
                            }
                            .font(.caption)
                        }
                        Text("Create a quick note from the BunnyPad menu bar item.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                        #else
                        Toggle("Show Quick Note Tile", isOn: $showQuickNoteTile)
                            .tint(BunnyTheme.gold)
                        Button {
                            onQuickNote?()
                        } label: {
                            HStack {
                                Image(systemName: "bolt.fill")
                                    .foregroundStyle(BunnyTheme.gold)
                                Text("New Quick Note Now")
                                    .fontWeight(.medium)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                            .foregroundStyle(.white)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                        #endif
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(appTheme == "skeuomorphic" ? AnyShapeStyle(Color(red: 0.22, green: 0.14, blue: 0.08).opacity(0.85)) : AnyShapeStyle(Color.black.opacity(0.35)))
                            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(appTheme == "skeuomorphic" ? Color(red: 0.85, green: 0.72, blue: 0.45).opacity(0.5) : .white.opacity(0.25), lineWidth: 1))
                    )

                    // Theme Options Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("THEME OPTIONS")
                            .font(.caption.bold())
                            .foregroundStyle(BunnyTheme.gold)

                        HStack(spacing: 8) {
                            themeOption("Default", value: "gradient")
                            themeOption("Legacy", value: "skeuomorphic")
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(appTheme == "skeuomorphic" ? AnyShapeStyle(Color(red: 0.22, green: 0.14, blue: 0.08).opacity(0.85)) : AnyShapeStyle(Color.black.opacity(0.35)))
                            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(appTheme == "skeuomorphic" ? Color(red: 0.85, green: 0.72, blue: 0.45).opacity(0.5) : .white.opacity(0.25), lineWidth: 1))
                    )

                    #if os(macOS)
                    // Window Transparency Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("WINDOW TRANSPARENCY")
                            .font(.caption.bold())
                            .foregroundStyle(BunnyTheme.gold)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Opacity")
                                    .foregroundStyle(.white)
                                Spacer()
                                Text("\(Int(windowOpacity * 100))%").bold().foregroundStyle(BunnyTheme.gold)
                            }
                            Slider(value: $windowOpacity, in: 0.4...1.0, step: 0.05)
                                .tint(BunnyTheme.gold)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(appTheme == "skeuomorphic" ? AnyShapeStyle(Color(red: 0.22, green: 0.14, blue: 0.08).opacity(0.85)) : AnyShapeStyle(Color.black.opacity(0.35)))
                            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(appTheme == "skeuomorphic" ? Color(red: 0.85, green: 0.72, blue: 0.45).opacity(0.5) : .white.opacity(0.25), lineWidth: 1))
                    )
                    #endif

                    // Editor Layout Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("EDITOR PREFERENCES")
                            .font(.caption.bold())
                            .foregroundStyle(BunnyTheme.gold)

                        Toggle("Wrap Lines", isOn: $wordWrap)
                            .tint(BunnyTheme.gold)
                        Toggle("Show Status Bar", isOn: $showStatusBar)
                            .tint(BunnyTheme.gold)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Font Size")
                                    .foregroundStyle(.white)
                                Spacer()
                                Text("\(Int(fontSize)) pt").bold().foregroundStyle(BunnyTheme.gold)
                            }
                            Slider(value: $fontSize, in: 10...32, step: 1)
                                .tint(BunnyTheme.gold)
                        }
                        .padding(.top, 4)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(appTheme == "skeuomorphic" ? AnyShapeStyle(Color(red: 0.22, green: 0.14, blue: 0.08).opacity(0.85)) : AnyShapeStyle(Color.black.opacity(0.35)))
                            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(appTheme == "skeuomorphic" ? Color(red: 0.85, green: 0.72, blue: 0.45).opacity(0.5) : .white.opacity(0.25), lineWidth: 1))
                    )
                }
                .foregroundStyle(.white)
                .padding(20)
                #if os(macOS)
                .frame(width: 440)
                #endif
            }
        }
    }

    private func themeOption(_ title: LocalizedStringKey, value: String) -> some View {
        Button {
            appTheme = value
        } label: {
            Text(title)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .foregroundStyle(appTheme == value ? Color.black : Color.white)
                .background(
                    appTheme == value ? BunnyTheme.gold : Color.white.opacity(0.12),
                    in: RoundedRectangle(cornerRadius: 10)
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(appTheme == value ? .isSelected : [])
    }
}

#Preview("About BunnyPad") {
    AboutView()
}

struct AboutView: View {
    @AppStorage("appTheme") private var appTheme = "gradient"

    var body: some View {
        ZStack {
            BunnyTheme.backgroundGradient(for: appTheme).ignoresSafeArea()

            if appTheme == "skeuomorphic" {
                SkeuomorphicPaperBackground()
                    .ignoresSafeArea()
            }

            ScrollView {
                VStack(spacing: 16) {
                    Image("AboutLogo")
                        .renderingMode(.original)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 96, height: 96)
                        .accessibilityHidden(true)
                    Text("BunnyPad").font(.largeTitle.bold())
                    Text("The Newest and Cutest way to take notes")
                        .foregroundStyle(BunnyTheme.textColor(for: appTheme).opacity(0.9))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("BunnyPad by GSYT Productions")
                        .multilineTextAlignment(.center)
                    Text("An open-source notepad, dedicated to PBbunnypower. This native macOS and iOS app is developed by Aoterno Technologies, based on the original BunnyPad app.")
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Original app by GarryStraitYT. Dedicated to PBbunnypower, creator of the BunnyPad icon. Thanks to the BunnyPad contributors.")
                        .font(.caption)
                        .foregroundStyle(BunnyTheme.textColor(for: appTheme).opacity(0.8))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Link("BunnyPad source and contributors", destination: bunnyPadRepositoryURL)
                        .foregroundStyle(BunnyTheme.gold)
                    Text("Licensed under Apache License 2.0")
                        .font(.caption)
                        .foregroundStyle(BunnyTheme.textColor(for: appTheme).opacity(0.7))
                }
                .foregroundStyle(BunnyTheme.textColor(for: appTheme))
                .padding(32)
                #if os(macOS)
                .frame(width: 420)
                #endif
            }
        }
    }
}
