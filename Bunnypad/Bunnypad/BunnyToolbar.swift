#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif
import SwiftUI

enum BunnyTheme {
    static let gold = Color(red: 1, green: 0.77, blue: 0.23)
    #if os(iOS)
    static let goldUIColor = UIColor(red: 1, green: 0.77, blue: 0.23, alpha: 1)
    #elseif os(macOS)
    static let goldNSColor = NSColor(red: 1, green: 0.77, blue: 0.23, alpha: 1)
    #endif

    static func backgroundGradient(for theme: String) -> LinearGradient {
        switch theme {
        case "dark":
            return LinearGradient(
                colors: [Color(red: 0.10, green: 0.10, blue: 0.14), Color(red: 0.16, green: 0.16, blue: 0.22)],
                startPoint: .top, endPoint: .bottom
            )
        case "light":
            return LinearGradient(
                colors: [Color(red: 0.94, green: 0.94, blue: 0.97), Color(red: 0.88, green: 0.88, blue: 0.94)],
                startPoint: .top, endPoint: .bottom
            )
        case "skeuomorphic":
            return LinearGradient(
                colors: [
                    Color(red: 0.99, green: 0.97, blue: 0.89),
                    Color(red: 0.94, green: 0.91, blue: 0.81)
                ],
                startPoint: .top, endPoint: .bottom
            )
        default: // gradient
            return LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.38, blue: 0.68),
                    Color(red: 0.45, green: 0.25, blue: 0.73),
                    Color(red: 0.77, green: 0.51, blue: 0.65)
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
    }

    static func barGradient(for theme: String) -> LinearGradient {
        switch theme {
        case "dark":
            return LinearGradient(
                colors: [Color(red: 0.14, green: 0.14, blue: 0.18), Color(red: 0.18, green: 0.18, blue: 0.24)],
                startPoint: .top, endPoint: .bottom
            )
        case "light":
            return LinearGradient(
                colors: [Color(red: 0.86, green: 0.86, blue: 0.90), Color(red: 0.78, green: 0.78, blue: 0.84)],
                startPoint: .top, endPoint: .bottom
            )
        case "skeuomorphic":
            return LinearGradient(
                colors: [
                    Color(red: 0.38, green: 0.22, blue: 0.12),
                    Color(red: 0.26, green: 0.15, blue: 0.08),
                    Color(red: 0.18, green: 0.10, blue: 0.05)
                ],
                startPoint: .top, endPoint: .bottom
            )
        default: // gradient
            return LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.40, blue: 0.82),
                    Color(red: 0.52, green: 0.24, blue: 0.91),
                    Color(red: 0.84, green: 0.42, blue: 0.71)
                ],
                startPoint: .leading, endPoint: .trailing
            )
        }
    }

    static var barGradient: LinearGradient {
        barGradient(for: "gradient")
    }

    static func textColor(for theme: String) -> Color {
        switch theme {
        case "light":
            return .black
        case "skeuomorphic":
            return Color(red: 0.15, green: 0.12, blue: 0.10)
        default:
            return .white
        }
    }

    #if os(iOS)
    static func uiTextColor(for theme: String) -> UIColor {
        switch theme {
        case "light":
            return .black
        case "skeuomorphic":
            return UIColor(red: 0.15, green: 0.12, blue: 0.10, alpha: 1)
        default:
            return .white
        }
    }
    #elseif os(macOS)
    static func nsTextColor(for theme: String) -> NSColor {
        switch theme {
        case "light":
            return .black
        case "skeuomorphic":
            return NSColor(red: 0.15, green: 0.12, blue: 0.10, alpha: 1)
        default:
            return .white
        }
    }
    #endif

    static let editorGradient = backgroundGradient(for: "gradient")
}

struct SkeuomorphicPaperBackground: View {
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                // Subtle ruled lines on yellow legal pad
                Canvas { context, size in
                    let lineSpacing: CGFloat = 28.0
                    var y: CGFloat = 40.0
                    while y < size.height {
                        var path = Path()
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                        context.stroke(path, with: .color(Color(red: 0.35, green: 0.52, blue: 0.80).opacity(0.18)), lineWidth: 1)
                        y += lineSpacing
                    }

                    // Vertical red margin rule
                    var marginPath = Path()
                    marginPath.move(to: CGPoint(x: 44, y: 0))
                    marginPath.addLine(to: CGPoint(x: 44, y: size.height))
                    context.stroke(marginPath, with: .color(Color(red: 0.88, green: 0.32, blue: 0.32).opacity(0.35)), lineWidth: 1.5)
                }

                // Stitched rich leather header strip at the top
                VStack(spacing: 0) {
                    ZStack(alignment: .bottom) {
                        LinearGradient(
                            colors: [
                                Color(red: 0.36, green: 0.20, blue: 0.10),
                                Color(red: 0.24, green: 0.13, blue: 0.06)
                            ],
                            startPoint: .top, endPoint: .bottom
                        )
                        .frame(height: 24)

                        // Golden stitches
                        HStack(spacing: 6) {
                            ForEach(0..<max(1, Int(geo.size.width / 10)), id: \.self) { _ in
                                Rectangle()
                                    .fill(Color(red: 0.90, green: 0.80, blue: 0.50).opacity(0.85))
                                    .frame(width: 4, height: 1.5)
                            }
                        }
                        .padding(.bottom, 3)
                    }

                    // Drop shadow underneath leather trim
                    LinearGradient(
                        colors: [Color.black.opacity(0.3), Color.clear],
                        startPoint: .top, endPoint: .bottom
                    )
                    .frame(height: 5)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

struct BunnyToolbar: View {
    let session: EditorSession
    @Environment(\.undoManager) private var undoManager
    @Binding var showSettings: Bool
    @Binding var showAbout: Bool
    var onBack: (() -> Void)? = nil
    var onSave: (() -> Void)? = nil
    var theme: String = "gradient"
    @Binding var isHandwritingMode: Bool

    init(
        session: EditorSession,
        showSettings: Binding<Bool> = .constant(false),
        showAbout: Binding<Bool> = .constant(false),
        onBack: (() -> Void)? = nil,
        onSave: (() -> Void)? = nil,
        theme: String = "gradient",
        isHandwritingMode: Binding<Bool> = .constant(false)
    ) {
        self.session = session
        self._showSettings = showSettings
        self._showAbout = showAbout
        self.onBack = onBack
        self.onSave = onSave
        self.theme = theme
        self._isHandwritingMode = isHandwritingMode
    }

    var body: some View {
        #if os(iOS)
        if theme == "skeuomorphic" {
            IOS6LeatherToolbarView(
                session: session,
                showSettings: $showSettings,
                showAbout: $showAbout,
                onBack: onBack,
                onSave: onSave,
                isHandwritingMode: $isHandwritingMode
            )
        } else {
            floatingPillBody
        }
        #else
        macOSBarBody
        #endif
    }

    #if os(iOS)
    private var floatingPillBody: some View {
        HStack(spacing: 0) {
            if let onBack {
                tool("Back", icon: "chevron.left") { onBack() }
                    .padding(.leading, 12)
                    .padding(.trailing, 6)

                separator
                    .padding(.trailing, 6)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    tool("Save", icon: "square.and.arrow.down.fill") { onSave?() }
                    tool("Print", icon: "printer.fill") { session.printDocument() }

                    separator

                    tool("Cut", icon: "scissors") { session.textView?.cut(nil) }
                    tool("Copy", icon: "doc.on.doc.fill") { session.textView?.copy(nil) }
                    tool("Paste", icon: "clipboard.fill") { session.textView?.paste(nil) }

                    separator

                    tool("Undo", icon: "arrow.uturn.backward") { undoManager?.undo() }
                        .disabled(undoManager?.canUndo != true)
                    tool("Redo", icon: "arrow.uturn.forward") { undoManager?.redo() }
                        .disabled(undoManager?.canRedo != true)

                    separator

                    tool("Find", icon: "magnifyingglass") { session.find(replacing: false) }
                    tool("Replace", icon: "arrow.left.arrow.right") { session.find(replacing: true) }

                    separator

                    tool("Go to Line", icon: "arrow.up.forward.app") { session.showGoToLine = true }
                    tool("Insert Date", icon: "calendar.badge.plus") { session.insertDate() }

                    separator

                    #if os(iOS)
                    tool("Handwriting", icon: isHandwritingMode ? "pencil.and.scribble" : "pencil.tip.crop.circle") {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            isHandwritingMode.toggle()
                        }
                    }

                    separator
                    #endif

                    tool("Settings", icon: "gearshape.fill") { showSettings = true }
                    tool("About", icon: "info.circle.fill") { showAbout = true }
                }
                .padding(.leading, onBack == nil ? 12 : 0)
                .padding(.trailing, 12)
                .padding(.vertical, 8)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(BunnyToolButtonStyle())
        .frame(height: 48)
        .background(
            Capsule()
                .fill(BunnyTheme.barGradient(for: theme))
                .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 4)
                .overlay(
                    Capsule()
                        .strokeBorder(
                            theme == "skeuomorphic"
                                ? AnyShapeStyle(LinearGradient(colors: [Color(red: 0.85, green: 0.72, blue: 0.42), Color(red: 0.50, green: 0.35, blue: 0.18)], startPoint: .top, endPoint: .bottom))
                                : AnyShapeStyle(.white.opacity(0.3)),
                            lineWidth: 1
                        )
                )
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
    #endif

    private var macOSBarBody: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                #if os(macOS)
                tool("New", icon: "doc.badge.plus") { send(#selector(NSDocumentController.newDocument(_:))) }
                tool("Open", icon: "folder.fill") { send(#selector(NSDocumentController.openDocument(_:))) }
                tool("Save", icon: "square.and.arrow.down.fill") { send(#selector(NSDocument.save(_:))) }
                tool("Print", icon: "printer.fill") { session.printDocument() }
                separator

                tool("Cut", icon: "scissors") { session.textView?.cut(nil) }
                tool("Copy", icon: "doc.on.doc.fill") { session.textView?.copy(nil) }
                tool("Paste", icon: "clipboard.fill") { session.textView?.paste(nil) }
                separator

                tool("Undo", icon: "arrow.uturn.backward") { undoManager?.undo() }
                    .disabled(undoManager?.canUndo != true)
                tool("Redo", icon: "arrow.uturn.forward") { undoManager?.redo() }
                    .disabled(undoManager?.canRedo != true)
                separator

                tool("Find", icon: "magnifyingglass") { session.find(replacing: false) }
                tool("Replace", icon: "arrow.left.arrow.right") { session.find(replacing: true) }

                tool("Font", icon: "textformat") { showFonts() }
                separator

                tool("Settings", icon: "gearshape.fill") { showSettings = true }
                tool("About", icon: "info.circle.fill") { showAbout = true }
                Spacer(minLength: 0)
                #endif
            }
            .buttonStyle(BunnyToolButtonStyle())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(BunnyTheme.barGradient(for: theme))
        .padding(.top, 28)
    }

    private var separator: some View {
        Rectangle().fill(.white.opacity(0.3)).frame(width: 1, height: 18).padding(.horizontal, 4)
    }

    private func tool(_ title: LocalizedKey, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon).labelStyle(.iconOnly)
        }
        .help(Text(title))
    }

    #if os(macOS)
    private func send(_ action: Selector) {
        session.textView?.window?.makeFirstResponder(session.textView)
        NSApp.sendAction(action, to: nil, from: nil)
    }

    private func showFonts() {
        session.textView?.window?.makeFirstResponder(session.textView)
        NSFontManager.shared.orderFrontFontPanel(nil)
    }
    #endif
}

typealias LocalizedKey = LocalizedStringKey

private struct BunnyToolButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(BunnyTheme.gold.opacity(isEnabled ? 1 : 0.4))
            .frame(width: 27, height: 26)
            .background(.white.opacity(configuration.isPressed ? 0.24 : 0), in: RoundedRectangle(cornerRadius: 3))
            .contentShape(Rectangle())
    }
}
