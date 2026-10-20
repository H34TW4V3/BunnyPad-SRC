#if os(macOS)
import AppKit
#endif
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @ObservedObject var document: NoteDocument
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
                #if os(iOS)
                IOS6PaperBackground()
                    .ignoresSafeArea()
                #else
                SkeuomorphicPaperBackground()
                    .ignoresSafeArea()
                #endif
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
        .onChange(of: appTheme) { _, newTheme in
            updatePlatformAppIcon(for: newTheme)
        }
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
            #if os(iOS)
            if appTheme == "skeuomorphic" {
                SettingsView(
                    onDismiss: { showSettings = false },
                    onQuickNote: {
                        showSettings = false
                        let timestamp = Date.now.formatted(date: .abbreviated, time: .shortened)
                        document.content = TextSnapshot(text: "--- Quick Note (\(timestamp)) ---\n\n")
                    }
                )
            } else {
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
            #else
            if appTheme == "skeuomorphic" {
                SettingsView(
                    onDismiss: { showSettings = false },
                    onQuickNote: {
                        showSettings = false
                        let timestamp = Date.now.formatted(date: .abbreviated, time: .shortened)
                        document.content = TextSnapshot(text: "--- Quick Note (\(timestamp)) ---\n\n")
                    }
                )
            } else {
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
            #endif
        }
        .sheet(isPresented: $showAbout) {
            #if os(iOS)
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
            #else
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
            #endif
        }
        .onAppear {
            let args = ProcessInfo.processInfo.arguments
            if args.contains("-screenshotEditor") {
                if document.content.text.isEmpty {
                    #if os(iOS)
                    document.content = TextSnapshot(text: """
# Welcome to BunnyPad! 🐰✨

BunnyPad is the cutest, fastest, and most delightful way to capture notes, thoughts, and ideas across all your Apple devices.

Features:
• Floating gold toolbar with one-tap text formatting
• Beautiful Bunny Gradient, Dark, and Light modern themes
• Nostalgic Apple skeuomorphic themes (Snow Leopard & iOS 6)
• Live word count, character count, and reading time stats
• Full iCloud syncing with instant background autosave
• Sandboxed plain text editing with markdown support

Enjoy writing with BunnyPad!
""")
                    #else
                    document.content = TextSnapshot(text: """
# Welcome to BunnyPad for Mac OS X! 🐰✨

BunnyPad brings the beloved nostalgic Mac OS X Snow Leopard Aqua aesthetic together with a lightning-fast, sandboxed plain text editor.

Features:
• Authentic Snow Leopard Aqua unified toolbar & brushed metal styling
• Specular glass Aqua buttons with custom active states
• Lucida Grande typography and classic pinstripe window background
• Live word and character counting status bar
• Seamless iCloud Drive syncing across macOS, iOS, and iPadOS
• Native find & replace with regex search support

Enjoy writing with BunnyPad!
""")
                    #endif
                }
                #if os(iOS)
                session.textView?.text = document.content.text
                #endif
            } else if args.contains("-screenshotSettings") {
                showSettings = true
            } else if args.contains("-screenshotAbout") {
                showAbout = true
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
        #if os(iOS)
        if theme == "skeuomorphic" {
            HStack {
                Text("Ln \(session.line), Col \(session.column)")
                Spacer()
                Text("\(content.text.count) characters")
                Divider().frame(height: 12)
                Text(content.encoding == .utf8 ? "UTF-8" : content.encoding == .isoLatin1 ? "Latin-1" : "UTF-16")
                Text(content.lineEnding == "\r\n" ? "CRLF" : content.lineEnding == "\r" ? "CR" : "LF")
            }
            .font(.caption.bold())
            .foregroundStyle(Color(red: 0.95, green: 0.90, blue: 0.80))
            .shadow(color: Color.black.opacity(0.85), radius: 0, x: 0, y: -1)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.32, green: 0.18, blue: 0.09),
                        Color(red: 0.18, green: 0.10, blue: 0.05)
                    ],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .overlay(alignment: .top) {
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 1)
                }
            }
        } else {
            defaultStatusBar
        }
        #else
        defaultStatusBar
        #endif
    }

    private var defaultStatusBar: some View {
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
    var onDismiss: (() -> Void)? = nil
    var onQuickNote: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @AppStorage("wordWrap") private var wordWrap = true
    @AppStorage("fontSize") private var fontSize = 16.0
    @AppStorage("showStatusBar") private var showStatusBar = true
    @AppStorage("appTheme") private var appTheme = "gradient"
    #if os(macOS)
    @AppStorage("windowOpacity") private var windowOpacity = 0.95
    @AppStorage("showMenuBarItem") private var showMenuBarItem = true
    @AppStorage("menuBarLoginStatus") private var menuBarLoginStatus = ""
    #endif

    #if os(macOS)
    @State private var osxTab: OSXPreferencesTab = .general
    #endif

    var body: some View {
        Group {
            #if os(iOS)
            if appTheme == "skeuomorphic" {
                ios6SettingsContent
            } else {
                defaultSettingsContent
            }
            #elseif os(macOS)
            if appTheme == "skeuomorphic" {
                osxLegacySettingsContent
            } else {
                defaultSettingsContent
            }
            #else
            defaultSettingsContent
            #endif
        }
        .onChange(of: appTheme) { _, newTheme in
            updatePlatformAppIcon(for: newTheme)
        }
    }

    #if os(iOS)
    private var ios6SettingsContent: some View {
        ZStack {
            IOS6LinenBackground()

            VStack(spacing: 0) {
                // Classic iOS 6 Modal Navigation Bar with Done Button
                IOS6ModalNavBar(title: "Settings") {
                    if let onDismiss {
                        onDismiss()
                    } else {
                        dismiss()
                    }
                }

                ScrollView {
                    VStack(spacing: 18) {
                        // Theme Options
                        VStack(alignment: .leading, spacing: 6) {
                            IOS6SectionHeader(title: "Theme Options")
                            IOS6SegmentedControl(
                                selected: $appTheme,
                                options: [
                                    IOS6SegmentedOption(title: "Default", icon: "AboutLogo", value: "gradient"),
                                    IOS6SegmentedOption(title: "Legacy", icon: "LegacyLogo", value: "skeuomorphic")
                                ]
                            )
                        }

                        // Editor Preferences
                        VStack(alignment: .leading, spacing: 6) {
                            IOS6SectionHeader(title: "Editor Preferences")
                            IOS6GroupedCard {
                                HStack {
                                    Text("Wrap Lines")
                                        .font(.system(size: 16, weight: .regular))
                                        .foregroundStyle(Color(red: 0.12, green: 0.12, blue: 0.14))
                                    Spacer()
                                    IOS6Switch(isOn: $wordWrap)
                                }
                                .frame(height: 34)

                                Divider()

                                HStack {
                                    Text("Show Status Bar")
                                        .font(.system(size: 16, weight: .regular))
                                        .foregroundStyle(Color(red: 0.12, green: 0.12, blue: 0.14))
                                    Spacer()
                                    IOS6Switch(isOn: $showStatusBar)
                                }
                                .frame(height: 34)

                                Divider()

                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text("Font Size")
                                            .font(.system(size: 16, weight: .regular))
                                            .foregroundStyle(Color(red: 0.12, green: 0.12, blue: 0.14))
                                        Spacer()
                                        Text("\(Int(fontSize)) pt")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(Color(red: 0.25, green: 0.35, blue: 0.55))
                                    }

                                    HStack(spacing: 12) {
                                        Text("A")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundStyle(Color(red: 0.48, green: 0.48, blue: 0.52))

                                        IOS6Slider(value: $fontSize, in: 10...32, step: 1)

                                        Text("A")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundStyle(Color(red: 0.48, green: 0.48, blue: 0.52))
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
            }
        }
    }
    #endif

    private var defaultSettingsContent: some View {
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
                        if #available(macOS 15.0, *) {
                            Text("To add Quick Note to Control Center or the Menu Bar, open Control Center, click Edit Controls, then choose BunnyPad → Quick Note.")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                        } else {
                            Text("Create a quick note from the BunnyPad menu bar item.")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        #else
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
                        if #available(iOS 18.0, *) {
                            Text("To add Quick Note to Control Centre, open Control Centre, touch and hold the background, tap Add a Control, then choose BunnyPad → Quick Note.")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                        }
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

                        HStack(spacing: 12) {
                            #if os(macOS)
                            themeOption(title: "Default", icon: "AboutLogo", value: "gradient")
                            themeOption(title: "Legacy", icon: "MacLegacyLogo", value: "skeuomorphic")
                            #else
                            themeOption(title: "Default", icon: "AboutLogo", value: "gradient")
                            themeOption(title: "Legacy", icon: "LegacyLogo", value: "skeuomorphic")
                            #endif
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

    private func themeOption(title: LocalizedStringKey, icon: String, value: String) -> some View {
        Button {
            appTheme = value
        } label: {
            HStack(spacing: 8) {
                Image(icon)
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .clipShape(RoundedRectangle(cornerRadius: 5))

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(appTheme == value ? Color.black : Color.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                appTheme == value ? BunnyTheme.gold : Color.white.opacity(0.12),
                in: RoundedRectangle(cornerRadius: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(appTheme == value ? BunnyTheme.gold : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(appTheme == value ? .isSelected : [])
    }

    #if os(macOS)
    private var osxLegacySettingsContent: some View {
        ZStack {
            OSXAquaWindowBackground()

            VStack(spacing: 0) {
                OSXPreferencesToolbar(selectedTab: $osxTab, onDismiss: onDismiss)

                ScrollView {
                    VStack(spacing: 16) {
                        switch osxTab {
                        case .general:
                            osxGeneralPane
                        case .editor:
                            osxEditorPane
                        case .theme:
                            osxThemePane
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: 520)
                }
            }
        }
        .frame(minWidth: 480, idealWidth: 520, maxWidth: 560, minHeight: 380, idealHeight: 420)
        .tint(Color(red: 0.20, green: 0.55, blue: 0.95))
    }

    private var osxGeneralPane: some View {
        VStack(spacing: 14) {
            OSXGroupBox(title: "Menu Bar") {
                VStack(alignment: .leading, spacing: 10) {
                    OSXAquaCheckbox(title: "Show BunnyPad in menu bar", isOn: $showMenuBarItem)

                    if showMenuBarItem {
                        Text(menuBarLoginStatus)
                            .font(.system(size: 11))
                            .foregroundStyle(Color(red: 0.35, green: 0.35, blue: 0.38))
                            .shadow(color: Color.white.opacity(0.8), radius: 0, x: 0, y: 1)
                            .padding(.leading, 24)

                        HStack(spacing: 10) {
                            OSXAquaButton(title: "Enable Launch at Login") {
                                MenuBarLoginItem.configure(isVisible: true, userChangedPreference: true)
                            }
                            OSXAquaButton(title: "Login Items Settings…") {
                                MenuBarLoginItem.openSettings()
                            }
                        }
                        .padding(.leading, 24)
                    }
                }
            }
        }
    }

    private var osxEditorPane: some View {
        VStack(spacing: 14) {
            OSXGroupBox(title: "Editor Preferences") {
                VStack(alignment: .leading, spacing: 12) {
                    OSXAquaCheckbox(title: "Wrap lines automatically to window width", isOn: $wordWrap)
                    OSXAquaCheckbox(title: "Show document status bar (lines, columns, character count)", isOn: $showStatusBar)
                }
            }

            OSXGroupBox(title: "Typography & Window") {
                VStack(spacing: 14) {
                    HStack {
                        Text("Font Size:")
                            .font(.system(size: 12, weight: .medium))
                            .frame(width: 105, alignment: .trailing)
                            .foregroundStyle(Color(red: 0.20, green: 0.20, blue: 0.22))
                            .shadow(color: Color.white.opacity(0.8), radius: 0, x: 0, y: 1)
                        OSXAquaSlider(value: $fontSize, range: 11...32, step: 1)
                        Text("\(Int(fontSize)) pt")
                            .font(.system(size: 12, weight: .bold))
                            .frame(width: 48, alignment: .leading)
                            .foregroundStyle(Color(red: 0.20, green: 0.20, blue: 0.22))
                            .shadow(color: Color.white.opacity(0.8), radius: 0, x: 0, y: 1)
                    }

                    HStack {
                        Text("Window Opacity:")
                            .font(.system(size: 12, weight: .medium))
                            .frame(width: 105, alignment: .trailing)
                            .foregroundStyle(Color(red: 0.20, green: 0.20, blue: 0.22))
                            .shadow(color: Color.white.opacity(0.8), radius: 0, x: 0, y: 1)
                        OSXAquaSlider(value: $windowOpacity, range: 0.5...1.0, step: 0.05)
                        Text("\(Int(windowOpacity * 100))%")
                            .font(.system(size: 12, weight: .bold))
                            .frame(width: 48, alignment: .leading)
                            .foregroundStyle(Color(red: 0.20, green: 0.20, blue: 0.22))
                            .shadow(color: Color.white.opacity(0.8), radius: 0, x: 0, y: 1)
                    }
                }
            }
        }
    }

    private var osxThemePane: some View {
        VStack(spacing: 14) {
            OSXGroupBox(title: "Appearance & Themes") {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 16) {
                        Image("MacLegacyLogo")
                            .renderingMode(.original)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 64, height: 64)
                            .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 2)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Classic Mac OS X Experience")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Color(red: 0.15, green: 0.15, blue: 0.18))
                                .shadow(color: Color.white.opacity(0.8), radius: 0, x: 0, y: 1)
                            Text("Aqua pinstripes, classic brushed metal controls, and authentic Snow Leopard styling.")
                                .font(.system(size: 11))
                                .foregroundStyle(Color(red: 0.40, green: 0.40, blue: 0.42))
                                .shadow(color: Color.white.opacity(0.8), radius: 0, x: 0, y: 1)
                        }
                    }

                    Divider().padding(.vertical, 2)

                    HStack(spacing: 14) {
                        Text("Active Theme:")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color(red: 0.20, green: 0.20, blue: 0.22))
                            .shadow(color: Color.white.opacity(0.8), radius: 0, x: 0, y: 1)

                        HStack(spacing: 12) {
                            Button {
                                appTheme = "gradient"
                            } label: {
                                HStack(spacing: 6) {
                                    Image("AboutLogo")
                                        .renderingMode(.original)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                        .clipShape(RoundedRectangle(cornerRadius: 4))

                                    Text("Modern")
                                        .font(.system(size: 12, weight: appTheme == "gradient" ? .bold : .medium))
                                        .foregroundStyle(appTheme == "gradient" ? Color.white : Color(red: 0.20, green: 0.20, blue: 0.22))
                                        .shadow(color: appTheme == "gradient" ? Color.black.opacity(0.5) : Color.white.opacity(0.8), radius: 0, x: 0, y: appTheme == "gradient" ? -1 : 1)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(
                                            appTheme == "gradient"
                                                ? LinearGradient(colors: [Color(red: 0.18, green: 0.42, blue: 0.82), Color(red: 0.10, green: 0.30, blue: 0.65)], startPoint: .top, endPoint: .bottom)
                                                : LinearGradient(colors: [Color.white.opacity(0.85), Color.white.opacity(0.40)], startPoint: .top, endPoint: .bottom)
                                        )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .strokeBorder(appTheme == "gradient" ? Color(red: 0.08, green: 0.24, blue: 0.55) : Color.black.opacity(0.28), lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.12), radius: 1, x: 0, y: 1)
                            }
                            .buttonStyle(.plain)
                            .focusEffectDisabled()
                            .tint(Color(red: 0.20, green: 0.55, blue: 0.95))

                            Button {
                                appTheme = "skeuomorphic"
                            } label: {
                                HStack(spacing: 6) {
                                    Image("MacLegacyLogo")
                                        .renderingMode(.original)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)

                                    Text("Legacy")
                                        .font(.system(size: 12, weight: appTheme == "skeuomorphic" ? .bold : .medium))
                                        .foregroundStyle(appTheme == "skeuomorphic" ? Color.white : Color(red: 0.20, green: 0.20, blue: 0.22))
                                        .shadow(color: appTheme == "skeuomorphic" ? Color.black.opacity(0.5) : Color.white.opacity(0.8), radius: 0, x: 0, y: appTheme == "skeuomorphic" ? -1 : 1)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(
                                            appTheme == "skeuomorphic"
                                                ? LinearGradient(colors: [Color(red: 0.18, green: 0.42, blue: 0.82), Color(red: 0.10, green: 0.30, blue: 0.65)], startPoint: .top, endPoint: .bottom)
                                                : LinearGradient(colors: [Color.white.opacity(0.85), Color.white.opacity(0.40)], startPoint: .top, endPoint: .bottom)
                                        )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .strokeBorder(appTheme == "skeuomorphic" ? Color(red: 0.08, green: 0.24, blue: 0.55) : Color.black.opacity(0.28), lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.12), radius: 1, x: 0, y: 1)
                            }
                            .buttonStyle(.plain)
                            .focusEffectDisabled()
                            .tint(Color(red: 0.20, green: 0.55, blue: 0.95))
                        }
                    }
                }
            }
        }
    }
    #endif
}

#Preview("About BunnyPad") {
    AboutView()
}

struct AboutView: View {
    var theme: String? = nil
    var onDismiss: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appTheme") private var storedTheme = "gradient"

    private var appTheme: String {
        theme ?? storedTheme
    }

    var body: some View {
        #if os(iOS)
        if appTheme == "skeuomorphic" {
            ios6AboutContent
        } else {
            defaultAboutContent
        }
        #elseif os(macOS)
        if appTheme == "skeuomorphic" {
            osxLegacyAboutContent
        } else {
            defaultAboutContent
        }
        #else
        defaultAboutContent
        #endif
    }

    #if os(iOS)
    private var ios6AboutContent: some View {
        ZStack {
            IOS6LinenBackground()

            VStack(spacing: 0) {
                IOS6ModalNavBar(title: "About") {
                    if let onDismiss {
                        onDismiss()
                    } else {
                        dismiss()
                    }
                }

                ScrollView {
                    VStack(spacing: 20) {
                        IOS6GlossyAppIcon(size: 96)

                        Text("BunnyPad")
                            .font(.largeTitle.bold())
                            .foregroundStyle(.white)
                            .shadow(color: Color.black.opacity(0.85), radius: 0, x: 0, y: -1)

                        Text("The Newest and Cutest way to take notes")
                            .font(.headline)
                            .foregroundStyle(Color(white: 0.85))
                            .shadow(color: Color.black.opacity(0.75), radius: 0, x: 0, y: -1)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)

                        IOS6GroupedCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("BunnyPad by GSYT Productions")
                                    .font(.headline)
                                    .foregroundStyle(Color(red: 0.16, green: 0.16, blue: 0.18))

                                Text("An open-source notepad, dedicated to PBbunnypower. This native macOS and iOS app is developed by Aoterno Technologies, based on the original BunnyPad app.")
                                    .font(.subheadline)
                                    .foregroundStyle(Color(red: 0.35, green: 0.35, blue: 0.38))
                                    .fixedSize(horizontal: false, vertical: true)

                                Divider()

                                Text("Original app by GarryStraitYT. Dedicated to PBbunnypower, creator of the BunnyPad icon. Thanks to the BunnyPad contributors.")
                                    .font(.caption)
                                    .foregroundStyle(Color(red: 0.50, green: 0.50, blue: 0.55))
                                    .fixedSize(horizontal: false, vertical: true)

                                Divider()

                                Link("BunnyPad source and contributors", destination: bunnyPadRepositoryURL)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(Color(red: 0.08, green: 0.44, blue: 0.85))

                                Text("Licensed under Apache License 2.0")
                                    .font(.caption)
                                    .foregroundStyle(Color(red: 0.50, green: 0.50, blue: 0.55))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }
            }
        }
    }
    #endif

    private var defaultAboutContent: some View {
        ZStack {
            BunnyTheme.backgroundGradient(for: appTheme).ignoresSafeArea()

            if appTheme == "skeuomorphic" {
                SkeuomorphicPaperBackground()
                    .ignoresSafeArea()
            }

            ScrollView {
                VStack(spacing: 16) {
                    if appTheme == "skeuomorphic" {
                        #if os(iOS)
                        IOS6GlossyAppIcon(size: 96)
                        #else
                        Image("MacLegacyLogo")
                            .renderingMode(.original)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 104, height: 104)
                            .shadow(color: Color.black.opacity(0.35), radius: 6, x: 0, y: 3)
                        #endif
                    } else {
                        Image("AboutLogo")
                            .renderingMode(.original)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 96, height: 96)
                            .accessibilityHidden(true)
                    }
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

    #if os(macOS)
    private var osxLegacyAboutContent: some View {
        ZStack {
            OSXAquaWindowBackground()

            VStack(spacing: 0) {
                if let onDismiss {
                    HStack {
                        Spacer()
                        OSXAquaButton(title: "Done") {
                            onDismiss()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }

                ScrollView {
                    VStack(spacing: 16) {
                        Image("MacLegacyLogo")
                            .renderingMode(.original)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 96, height: 96)
                            .shadow(color: Color.black.opacity(0.35), radius: 4, x: 0, y: 2)
                            .padding(.top, onDismiss == nil ? 18 : 6)

                        VStack(spacing: 3) {
                            Text("BunnyPad")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(Color(red: 0.15, green: 0.15, blue: 0.18))
                                .shadow(color: Color.white.opacity(0.9), radius: 0, x: 0, y: 1)

                            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "5")")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color(red: 0.45, green: 0.45, blue: 0.48))
                                .shadow(color: Color.white.opacity(0.8), radius: 0, x: 0, y: 1)

                            Text("The Newest and Cutest way to take notes")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color(red: 0.30, green: 0.30, blue: 0.33))
                                .shadow(color: Color.white.opacity(0.8), radius: 0, x: 0, y: 1)
                        }

                        OSXGroupBox(title: "About BunnyPad") {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("BunnyPad by GSYT Productions")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(Color(red: 0.16, green: 0.16, blue: 0.18))

                                Text("An open-source notepad, dedicated to PBbunnypower. This native macOS and iOS app is developed by Aoterno Technologies, based on the original BunnyPad app.")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color(red: 0.35, green: 0.35, blue: 0.38))
                                    .fixedSize(horizontal: false, vertical: true)

                                Divider()

                                Text("Original app by GarryStraitYT. Dedicated to PBbunnypower, creator of the BunnyPad icon. Thanks to the BunnyPad contributors.")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color(red: 0.50, green: 0.50, blue: 0.55))
                                    .fixedSize(horizontal: false, vertical: true)

                                Divider()

                                Link("BunnyPad source and contributors", destination: bunnyPadRepositoryURL)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(Color(red: 0.08, green: 0.44, blue: 0.85))

                                Text("Licensed under Apache License 2.0")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color(red: 0.50, green: 0.50, blue: 0.55))
                            }
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: 420)
                }
            }
        }
        .frame(minWidth: 420, idealWidth: 450, maxWidth: 480, minHeight: 380, idealHeight: 440)
        .tint(Color(red: 0.20, green: 0.55, blue: 0.95))
    }
    #endif
}
