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
    @AppStorage("showStatusBar") private var showStatusBar = true
    @AppStorage("showQuickNoteTile") private var showQuickNoteTile = true
    @AppStorage("editorFontSize") private var fontSize = 14.0
    @AppStorage("appTheme") private var appTheme = "gradient"
    #if os(macOS)
    @AppStorage("windowOpacity") private var windowOpacity = 0.95
    #endif

    @State private var showSettings = false
    @State private var showAbout = false
    @State private var showExportSheet = false

    var body: some View {
        ZStack {
            BunnyTheme.backgroundGradient(for: appTheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                BunnyToolbar(
                    session: session,
                    showSettings: $showSettings,
                    showAbout: $showAbout,
                    onBack: onBack,
                    onSave: { showExportSheet = true }
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
        .preferredColorScheme(appTheme == "light" ? .light : .dark)
        .focusedSceneValue(\.editorSession, session)
        .overlay {
            Rectangle().strokeBorder(.white.opacity(0.3), lineWidth: 1)
                .allowsHitTesting(false)
        }
        .fileExporter(
            isPresented: $showExportSheet,
            document: document,
            contentType: .plainText,
            defaultFilename: "Note.txt"
        ) { _ in }
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
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(BunnyTheme.barGradient)
        .overlay(alignment: .top) {
            Rectangle().fill(.white.opacity(0.25)).frame(height: 1)
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

            VStack(alignment: .leading, spacing: 16) {
                Text("Go to Line").font(.headline).foregroundStyle(BunnyTheme.textColor(for: appTheme))
                TextField("Line number", text: $line)
                    .textFieldStyle(.roundedBorder)
                    #if os(iOS)
                    .keyboardType(.numberPad)
                    #endif
                    .onSubmit { navigate() }
                if invalidLine {
                    Text("Enter a line number in this document.")
                        .foregroundStyle(Color(red: 1.0, green: 0.4, blue: 0.4))
                }
                HStack {
                    Spacer()
                    Button("Cancel") { dismiss() }
                        .keyboardShortcut(.cancelAction)
                        .foregroundStyle(BunnyTheme.textColor(for: appTheme))
                    Button("Go") { navigate() }
                        .keyboardShortcut(.defaultAction)
                        .buttonStyle(.borderedProminent)
                        .tint(BunnyTheme.gold)
                        .foregroundStyle(.black)
                }
            }
            .padding(24)
            .frame(width: 300)
        }
    }

    private func navigate() {
        if let number = Int(line), session.go(to: number) {
            dismiss()
        } else {
            invalidLine = true
        }
    }
}

#Preview {
    ContentView(document: NoteDocument())
        #if os(macOS)
        .frame(width: 860, height: 620)
        #endif
}

struct SettingsView: View {
    var onQuickNote: (() -> Void)? = nil
    @AppStorage("wordWrap") private var wordWrap = true
    @AppStorage("showStatusBar") private var showStatusBar = true
    @AppStorage("showQuickNoteTile") private var showQuickNoteTile = true
    @AppStorage("editorFontSize") private var fontSize = 14.0
    @AppStorage("appTheme") private var appTheme = "gradient"
    #if os(macOS)
    @AppStorage("windowOpacity") private var windowOpacity = 0.95
    #endif

    var body: some View {
        ZStack {
            BunnyTheme.backgroundGradient(for: appTheme)
                .ignoresSafeArea()

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

                    // Quick Settings Liquid Glass Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("QUICK SETTINGS")
                            .font(.caption.bold())
                            .foregroundStyle(BunnyTheme.gold)

                        Toggle("Show Quick Note Tile", isOn: $showQuickNoteTile)
                            .tint(BunnyTheme.gold)

                        if showQuickNoteTile {
                            Button {
                                #if os(macOS)
                                NSDocumentController.shared.newDocument(nil)
                                #else
                                onQuickNote?()
                                #endif
                            } label: {
                                HStack {
                                    Image(systemName: "bolt.fill")
                                        .font(.title3)
                                        .foregroundStyle(BunnyTheme.gold)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("New Quick Note")
                                            .font(.headline)
                                            .foregroundStyle(.white)
                                        Text("Start typing immediately")
                                            .font(.caption)
                                            .foregroundStyle(.white.opacity(0.8))
                                    }
                                    Spacer()
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(BunnyTheme.gold)
                                }
                                .padding(12)
                                .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(.black.opacity(0.35))
                            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.white.opacity(0.25), lineWidth: 1))
                    )

                    // Theme Options Liquid Glass Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("THEME OPTIONS")
                            .font(.caption.bold())
                            .foregroundStyle(BunnyTheme.gold)

                        Picker("App Theme", selection: $appTheme) {
                            Text("Bunny Gradient").tag("gradient")
                            Text("Dark").tag("dark")
                            Text("Light").tag("light")
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(.black.opacity(0.35))
                            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.white.opacity(0.25), lineWidth: 1))
                    )

                    #if os(macOS)
                    // Window Transparency Liquid Glass Card
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
                            .fill(.black.opacity(0.35))
                            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.white.opacity(0.25), lineWidth: 1))
                    )
                    #endif

                    // Editor Preferences Liquid Glass Card
                    VStack(alignment: .leading, spacing: 14) {
                        Text("EDITOR PREFERENCES")
                            .font(.caption.bold())
                            .foregroundStyle(BunnyTheme.gold)

                        Toggle("Wrap long lines", isOn: $wordWrap)
                            .tint(BunnyTheme.gold)
                        Toggle("Show status bar", isOn: $showStatusBar)
                            .tint(BunnyTheme.gold)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Text size")
                                    .foregroundStyle(.white)
                                Spacer()
                                Text("\(Int(fontSize)) pt").bold().foregroundStyle(BunnyTheme.gold)
                            }
                            Slider(value: $fontSize, in: 10...32, step: 1)
                                .tint(BunnyTheme.gold)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(.black.opacity(0.35))
                            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.white.opacity(0.25), lineWidth: 1))
                    )
                }
                .padding(24)
            }
        }
        .foregroundStyle(.white)
        #if os(macOS)
        .frame(width: 440, height: 520)
        #endif
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
