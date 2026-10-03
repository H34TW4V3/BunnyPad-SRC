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

    static func textColor(for theme: String) -> Color {
        theme == "light" ? .black : .white
    }

    #if os(iOS)
    static func uiTextColor(for theme: String) -> UIColor {
        theme == "light" ? .black : .white
    }
    #elseif os(macOS)
    static func nsTextColor(for theme: String) -> NSColor {
        theme == "light" ? .black : .white
    }
    #endif

    static let editorGradient = backgroundGradient(for: "gradient")
    static let barGradient = LinearGradient(
        colors: [
            Color(red: 0.12, green: 0.40, blue: 0.82),
            Color(red: 0.52, green: 0.24, blue: 0.91),
            Color(red: 0.84, green: 0.42, blue: 0.71)
        ],
        startPoint: .leading, endPoint: .trailing
    )
}

struct BunnyToolbar: View {
    let session: EditorSession
    @Environment(\.undoManager) private var undoManager
    @Binding var showSettings: Bool
    @Binding var showAbout: Bool
    var onBack: (() -> Void)? = nil
    var onSave: (() -> Void)? = nil

    init(session: EditorSession, showSettings: Binding<Bool> = .constant(false), showAbout: Binding<Bool> = .constant(false), onBack: (() -> Void)? = nil, onSave: (() -> Void)? = nil) {
        self.session = session
        self._showSettings = showSettings
        self._showAbout = showAbout
        self.onBack = onBack
        self.onSave = onSave
    }

    var body: some View {
        #if os(iOS)
        floatingPillBody
        #else
        macOSBarBody
        #endif
    }

    #if os(iOS)
    private var floatingPillBody: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                if let onBack {
                    tool("Back", icon: "chevron.left") { onBack() }
                    separator
                }

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

                tool("Settings", icon: "gearshape.fill") { showSettings = true }
                tool("About", icon: "info.circle.fill") { showAbout = true }
            }
            .buttonStyle(BunnyToolButtonStyle())
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .background(
            Capsule()
                .fill(BunnyTheme.barGradient)
                .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 4)
                .overlay(Capsule().strokeBorder(.white.opacity(0.3), lineWidth: 1))
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
        .background(BunnyTheme.barGradient)
        .padding(.top, 28)
    }

    private var separator: some View {
        Rectangle().fill(.white.opacity(0.3)).frame(width: 1, height: 18).padding(.horizontal, 4)
    }

    private func tool(_ title: LocalizedStringKey, icon: String, action: @escaping () -> Void) -> some View {
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
