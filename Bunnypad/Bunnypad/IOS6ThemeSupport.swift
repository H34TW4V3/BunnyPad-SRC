#if os(iOS)
import SwiftUI
import UIKit

// MARK: - iOS 6 Linen Texture Background
struct IOS6LinenBackground: View {
    var body: some View {
        ZStack {
            // Base slate-charcoal color
            Color(red: 0.18, green: 0.19, blue: 0.22)
                .ignoresSafeArea()

            // Procedural linen weave
            Canvas { context, size in
                let spacing: CGFloat = 3.0
                // Vertical weave threads
                var x: CGFloat = 0
                var i = 0
                while x < size.width {
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                    let alpha = (i % 2 == 0) ? 0.06 : 0.02
                    context.stroke(path, with: .color(Color.white.opacity(alpha)), lineWidth: 1)
                    x += spacing
                    i += 1
                }

                // Horizontal weave threads
                var y: CGFloat = 0
                var j = 0
                while y < size.height {
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    let darkAlpha = (j % 2 == 0) ? 0.14 : 0.05
                    context.stroke(path, with: .color(Color.black.opacity(darkAlpha)), lineWidth: 1)
                    y += spacing
                    j += 1
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            // Vignette shadow around edges
            RadialGradient(
                colors: [Color.clear, Color.black.opacity(0.55)],
                center: .center,
                startRadius: 100,
                endRadius: 500
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
    }
}

// MARK: - iOS 6 Torn Paper Background (Legal Pad)
struct IOS6PaperBackground: View {
    var showTornEdge: Bool = true

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                // Warm Canary Yellow Paper
                LinearGradient(
                    colors: [
                        Color(red: 0.99, green: 0.97, blue: 0.72),
                        Color(red: 0.97, green: 0.94, blue: 0.65),
                        Color(red: 0.95, green: 0.91, blue: 0.60)
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                // Ruled blue lines & Red margin
                Canvas { context, size in
                    let lineSpacing: CGFloat = 28.0
                    var y: CGFloat = 36.0
                    while y < size.height {
                        var path = Path()
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                        context.stroke(path, with: .color(Color(red: 0.40, green: 0.58, blue: 0.85).opacity(0.32)), lineWidth: 1)
                        y += lineSpacing
                    }

                    // Double red margin rule at left
                    var redMargin1 = Path()
                    redMargin1.move(to: CGPoint(x: 44, y: 0))
                    redMargin1.addLine(to: CGPoint(x: 44, y: size.height))
                    context.stroke(redMargin1, with: .color(Color(red: 0.88, green: 0.32, blue: 0.32).opacity(0.42)), lineWidth: 1.2)

                    var redMargin2 = Path()
                    redMargin2.move(to: CGPoint(x: 47.5, y: 0))
                    redMargin2.addLine(to: CGPoint(x: 47.5, y: size.height))
                    context.stroke(redMargin2, with: .color(Color(red: 0.88, green: 0.32, blue: 0.32).opacity(0.22)), lineWidth: 0.8)
                }
                .ignoresSafeArea()

                // Torn paper perforation strip at the top
                if showTornEdge {
                    VStack(spacing: 0) {
                        TornPaperEdgeShape()
                            .fill(Color(red: 0.99, green: 0.97, blue: 0.80))
                            .frame(height: 9)
                            .shadow(color: Color.black.opacity(0.28), radius: 2.5, x: 0, y: 2)
                    }
                    .allowsHitTesting(false)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Torn Paper Perforation Shape
struct TornPaperEdgeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 4))

        let toothWidth: CGFloat = 8.0
        var x = rect.maxX
        var toggle = false
        while x > 0 {
            let nextX = max(0, x - toothWidth)
            let toothY = toggle ? rect.maxY : rect.maxY - 4
            path.addLine(to: CGPoint(x: x - toothWidth / 2, y: toothY))
            path.addLine(to: CGPoint(x: nextX, y: rect.maxY - 4))
            x = nextX
            toggle.toggle()
        }

        path.addLine(to: CGPoint(x: 0, y: 0))
        path.closeSubpath()
        return path
    }
}

// MARK: - iOS 6 Stitched Leather Toolbar Bar
struct IOS6LeatherToolbarView: View {
    let session: EditorSession
    @Environment(\.undoManager) private var undoManager
    @Binding var showSettings: Bool
    @Binding var showAbout: Bool
    var onBack: (() -> Void)? = nil
    var onSave: (() -> Void)? = nil
    @Binding var isHandwritingMode: Bool

    init(
        session: EditorSession,
        showSettings: Binding<Bool>,
        showAbout: Binding<Bool>,
        onBack: (() -> Void)? = nil,
        onSave: (() -> Void)? = nil,
        isHandwritingMode: Binding<Bool> = .constant(false)
    ) {
        self.session = session
        self._showSettings = showSettings
        self._showAbout = showAbout
        self.onBack = onBack
        self.onSave = onSave
        self._isHandwritingMode = isHandwritingMode
    }

    private var leatherGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.38, green: 0.22, blue: 0.12),
                Color(red: 0.28, green: 0.15, blue: 0.08),
                Color(red: 0.18, green: 0.10, blue: 0.05),
                Color(red: 0.12, green: 0.06, blue: 0.03)
            ],
            startPoint: .top, endPoint: .bottom
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            // Leather Bar Header (Classic 44pt iOS bar)
            ZStack(alignment: .bottom) {
                // Deep rich brown leather gradient
                leatherGradient

                // Top highlight line (1px specular)
                VStack {
                    Rectangle()
                        .fill(Color.white.opacity(0.20))
                        .frame(height: 1)
                    Spacer()
                }
                .allowsHitTesting(false)

                // Single compact row with pinned back button and smooth scrollable tools
                HStack(spacing: 0) {
                    if let onBack {
                        IOS6BackButton(title: "Notes") {
                            onBack()
                        }
                        .padding(.leading, 8)
                        .padding(.trailing, 6)

                        ios6Separator
                            .padding(.trailing, 6)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            // Document actions: Save, Print
                            ios6Tool("Save", icon: "square.and.arrow.down.fill") { onSave?() }
                            ios6Tool("Print", icon: "printer.fill") { session.printDocument() }

                            ios6Separator

                            // Edit actions: Cut, Copy, Paste
                            ios6Tool("Cut", icon: "scissors") { session.textView?.cut(nil) }
                            ios6Tool("Copy", icon: "doc.on.doc.fill") { session.textView?.copy(nil) }
                            ios6Tool("Paste", icon: "clipboard.fill") { session.textView?.paste(nil) }

                            ios6Separator

                            // History actions: Undo, Redo
                            ios6Tool("Undo", icon: "arrow.uturn.backward") { undoManager?.undo() }
                                .disabled(undoManager?.canUndo != true)
                            ios6Tool("Redo", icon: "arrow.uturn.forward") { undoManager?.redo() }
                                .disabled(undoManager?.canRedo != true)

                            ios6Separator

                            // Utility actions: Find, Replace, Go to Line, Insert Date
                            ios6Tool("Find", icon: "magnifyingglass") { session.find(replacing: false) }
                            ios6Tool("Replace", icon: "arrow.left.arrow.right") { session.find(replacing: true) }
                            ios6Tool("Go to Line", icon: "arrow.up.forward.app") { session.showGoToLine = true }
                            ios6Tool("Insert Date", icon: "calendar.badge.plus") { session.insertDate() }

                            ios6Separator

                            // Apple Pencil / Handwriting mode
                            ios6Tool("Handwriting", icon: isHandwritingMode ? "pencil.and.scribble" : "pencil.tip") {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    isHandwritingMode.toggle()
                                }
                            }

                            ios6Separator

                            // Preferences actions: Settings, About
                            ios6Tool("Settings", icon: "gearshape.fill") { showSettings = true }
                            ios6Tool("About", icon: "info.circle.fill") { showAbout = true }
                        }
                        .padding(.leading, onBack == nil ? 8 : 0)
                        .padding(.trailing, 12)
                        .padding(.vertical, 7)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .frame(height: 44)

                // Stitched thread line along bottom edge drawn with Canvas (does not bloat view width)
                Canvas { context, size in
                    let stitchWidth: CGFloat = 4.0
                    let stitchSpacing: CGFloat = 4.0
                    var x: CGFloat = 2.0
                    let y = size.height - 2.0

                    while x < size.width {
                        var path = Path()
                        path.move(to: CGPoint(x: x, y: y))
                        path.addLine(to: CGPoint(x: x + stitchWidth, y: y))
                        context.stroke(
                            path,
                            with: .color(Color(red: 0.92, green: 0.82, blue: 0.55)),
                            lineWidth: 1.5
                        )
                        x += stitchWidth + stitchSpacing
                    }
                }
                .frame(height: 4)
                .allowsHitTesting(false)
            }
            .frame(height: 44)
            .background(leatherGradient.ignoresSafeArea(edges: .top))

            // Drop shadow casting onto the paper
            LinearGradient(
                colors: [Color.black.opacity(0.35), Color.clear],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 4)
            .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity)
    }

    private var ios6Separator: some View {
        HStack(spacing: 1) {
            Rectangle().fill(Color.black.opacity(0.6)).frame(width: 1, height: 20)
            Rectangle().fill(Color.white.opacity(0.18)).frame(width: 1, height: 20)
        }
        .padding(.horizontal, 2)
    }

    private func ios6Tool(_ title: LocalizedStringKey, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 32, height: 28)
        }
        .buttonStyle(IOS6LeatherButtonStyle())
        .accessibilityLabel(Text(title))
    }
}

// MARK: - iOS 6 Leather Button Style
struct IOS6LeatherButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color(red: 0.96, green: 0.92, blue: 0.82).opacity(isEnabled ? 1 : 0.4))
            .shadow(color: Color.black.opacity(0.8), radius: 0, x: 0, y: -1) // Embossed inset icon shadow
            .background(
                ZStack {
                    // Beveled gradient
                    RoundedRectangle(cornerRadius: 4.5)
                        .fill(
                            configuration.isPressed
                                ? LinearGradient(
                                    colors: [Color(red: 0.12, green: 0.07, blue: 0.04), Color(red: 0.22, green: 0.12, blue: 0.07)],
                                    startPoint: .top, endPoint: .bottom
                                )
                                : LinearGradient(
                                    colors: [Color(red: 0.28, green: 0.16, blue: 0.09), Color(red: 0.16, green: 0.09, blue: 0.05)],
                                    startPoint: .top, endPoint: .bottom
                                )
                        )

                    // Specular gloss on top half
                    VStack {
                        RoundedRectangle(cornerRadius: 4.5)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.28), Color.white.opacity(0.05)],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                            .frame(height: 14)
                        Spacer()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 4.5))

                    // 1px Border
                    RoundedRectangle(cornerRadius: 4.5)
                        .strokeBorder(Color.black.opacity(0.75), lineWidth: 1)

                    // 1px Bottom Highlight (Classic iOS 6 3D edge)
                    VStack {
                        Spacer()
                        RoundedRectangle(cornerRadius: 4.5)
                            .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                            .frame(height: 2)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 4.5))
                }
            )
            .shadow(color: Color.black.opacity(0.4), radius: 1, x: 0, y: 1)
    }
}

// MARK: - iOS 6 Pointed Back Button
struct IOS6BackButton: View {
    let title: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 3) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 11, weight: .bold))
                Text(title)
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundStyle(Color(red: 0.96, green: 0.92, blue: 0.82))
            .shadow(color: Color.black.opacity(0.8), radius: 0, x: 0, y: -1)
            .padding(.leading, 8)
            .padding(.trailing, 10)
            .frame(height: 28)
            .background(
                ZStack {
                    IOS6BackChevronShape()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.28, green: 0.16, blue: 0.09), Color(red: 0.16, green: 0.09, blue: 0.05)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )

                    // Top gloss
                    VStack {
                        IOS6BackChevronShape()
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.28), Color.white.opacity(0.05)],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                            .frame(height: 14)
                        Spacer()
                    }
                    .clipShape(IOS6BackChevronShape())

                    IOS6BackChevronShape()
                        .stroke(Color.black.opacity(0.75), lineWidth: 1)
                }
            )
            .shadow(color: Color.black.opacity(0.4), radius: 1, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}

struct IOS6BackChevronShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let pointWidth: CGFloat = 8.0
        let radius: CGFloat = 4.0

        path.move(to: CGPoint(x: rect.minX + pointWidth, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addArc(
            center: CGPoint(x: rect.maxX - radius, y: rect.minY + radius),
            radius: radius,
            startAngle: .degrees(-90),
            endAngle: .degrees(0),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        path.addArc(
            center: CGPoint(x: rect.maxX - radius, y: rect.maxY - radius),
            radius: radius,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.minX + pointWidth, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + 1, y: rect.midY + 1))
        path.addLine(to: CGPoint(x: rect.minX + 1, y: rect.midY - 1))
        path.closeSubpath()
        return path
    }
}

// MARK: - iOS 6 Grouped Section Header (Letterpress Text)
struct IOS6SectionHeader: View {
    let title: LocalizedStringKey

    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(Color(red: 0.30, green: 0.35, blue: 0.44)) // Classic iOS 6 slate blue-gray
            .shadow(color: Color.white.opacity(0.85), radius: 0, x: 0, y: 1) // 1px white bottom shadow gives engraved effect
            .textCase(.uppercase)
            .padding(.horizontal, 4)
            .padding(.bottom, 4)
    }
}

// MARK: - iOS 6 Grouped Table Card Container
struct IOS6GroupedCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            content()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.99, green: 0.99, blue: 0.99),
                            Color(red: 0.96, green: 0.96, blue: 0.96)
                        ],
                        startPoint: .top, endPoint: .bottom
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color(red: 0.78, green: 0.78, blue: 0.80), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 2, x: 0, y: 1)
        .shadow(color: Color.white.opacity(0.7), radius: 0, x: 0, y: 1)
    }
}

// MARK: - iOS 6 Skeuomorphic Switch
struct IOS6Switch: View {
    @Binding var isOn: Bool

    private let trackWidth: CGFloat = 78
    private let trackHeight: CGFloat = 27
    private let knobSize: CGFloat = 27

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.26, dampingFraction: 0.85)) {
                isOn.toggle()
            }
        } label: {
            ZStack(alignment: .leading) {
                // Background Track
                Capsule()
                    .fill(
                        isOn
                            ? LinearGradient(
                                colors: [
                                    Color(red: 0.06, green: 0.42, blue: 0.86),
                                    Color(red: 0.18, green: 0.64, blue: 0.95)
                                ],
                                startPoint: .top, endPoint: .bottom
                            )
                            : LinearGradient(
                                colors: [
                                    Color(white: 0.86),
                                    Color(white: 0.94)
                                ],
                                startPoint: .top, endPoint: .bottom
                            )
                    )
                    .frame(width: trackWidth, height: trackHeight)
                    .overlay(
                        Capsule()
                            .strokeBorder(Color(white: 0.58), lineWidth: 1)
                    )
                    .overlay(
                        // Inner inset track shadow
                        Capsule()
                            .strokeBorder(Color.black.opacity(0.22), lineWidth: 1.5)
                            .offset(y: 1)
                            .mask(Capsule().frame(width: trackWidth, height: trackHeight))
                    )

                // Track Labels
                ZStack {
                    if isOn {
                        HStack {
                            Text("ON")
                                .font(.system(size: 13, weight: .black))
                                .foregroundStyle(.white)
                                .shadow(color: Color.black.opacity(0.6), radius: 0, x: 0, y: -1)
                                .padding(.leading, 10)
                            Spacer()
                        }
                    } else {
                        HStack {
                            Spacer()
                            Text("OFF")
                                .font(.system(size: 13, weight: .black))
                                .foregroundStyle(Color(white: 0.48))
                                .shadow(color: Color.white.opacity(0.8), radius: 0, x: 0, y: 1)
                                .padding(.trailing, 10)
                        }
                    }
                }
                .frame(width: trackWidth, height: trackHeight)

                // Sliding Silver Knob
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(white: 0.99),
                                    Color(white: 0.88),
                                    Color(white: 0.78)
                                ],
                                startPoint: .top, endPoint: .bottom
                            )
                        )

                    // Vertical grip notches
                    HStack(spacing: 2) {
                        Rectangle().fill(Color.gray.opacity(0.65)).frame(width: 1, height: 11)
                        Rectangle().fill(Color.gray.opacity(0.65)).frame(width: 1, height: 11)
                        Rectangle().fill(Color.gray.opacity(0.65)).frame(width: 1, height: 11)
                    }

                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.white.opacity(0.8), Color.black.opacity(0.35)],
                                startPoint: .top, endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                }
                .frame(width: knobSize, height: knobSize)
                .shadow(color: Color.black.opacity(0.35), radius: 2, x: 0, y: 1)
                .offset(x: isOn ? (trackWidth - knobSize) : 0)
            }
            .frame(width: trackWidth, height: trackHeight, alignment: .leading)
            .clipped()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - iOS 6 Skeuomorphic Slider
struct IOS6Slider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double

    init(value: Binding<Double>, in range: ClosedRange<Double>, step: Double = 1) {
        self._value = value
        self.range = range
        self.step = step
    }

    private let thumbSize: CGFloat = 28
    private let trackHeight: CGFloat = 8

    var body: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let usableWidth = max(totalWidth - thumbSize, 1)
            let progress = CGFloat(min(max((value - range.lowerBound) / (range.upperBound - range.lowerBound), 0.0), 1.0))
            let thumbX = progress * usableWidth

            ZStack(alignment: .leading) {
                // Background Unfilled Track (Debossed Silver Inset Groove)
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.72, green: 0.72, blue: 0.74),
                                Color(red: 0.88, green: 0.88, blue: 0.90)
                            ],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .frame(height: trackHeight)
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.black.opacity(0.30), lineWidth: 1)
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.black.opacity(0.15), lineWidth: 1)
                            .offset(y: 0.5)
                            .mask(Capsule().frame(height: trackHeight))
                    )

                // Active Filled Track (iOS 6 Glossy Blue)
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.06, green: 0.42, blue: 0.86),
                                Color(red: 0.18, green: 0.64, blue: 0.95)
                            ],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .frame(width: max(thumbX + thumbSize / 2, trackHeight), height: trackHeight)
                    .overlay(
                        Capsule()
                            .strokeBorder(Color(red: 0.04, green: 0.30, blue: 0.65), lineWidth: 1)
                    )

                // iOS 6 Glossy Silver Thumb / Knob
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(white: 0.99),
                                    Color(white: 0.90),
                                    Color(white: 0.78)
                                ],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .frame(width: thumbSize, height: thumbSize)

                    // Subtle inner metallic bevel
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.white, Color(white: 0.65)],
                                startPoint: .top, endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                        .frame(width: thumbSize - 2, height: thumbSize - 2)

                    Circle()
                        .strokeBorder(Color.black.opacity(0.30), lineWidth: 1)
                        .frame(width: thumbSize, height: thumbSize)
                }
                .shadow(color: Color.black.opacity(0.35), radius: 2, x: 0, y: 1.5)
                .offset(x: thumbX)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            let rawFraction = (gesture.location.x - thumbSize / 2) / usableWidth
                            let clamped = min(max(Double(rawFraction), 0.0), 1.0)
                            let unstepped = range.lowerBound + clamped * (range.upperBound - range.lowerBound)
                            let stepped = (unstepped / step).rounded() * step
                            value = min(max(stepped, range.lowerBound), range.upperBound)
                        }
                )
            }
            .frame(height: max(thumbSize, 32))
        }
        .frame(height: max(thumbSize, 32))
    }
}

// MARK: - iOS 6 Modal Top Navigation Bar
struct IOS6ModalNavBar: View {
    let title: LocalizedStringKey
    let doneAction: () -> Void

    var body: some View {
        ZStack {
            // Dark glossy nav bar gradient
            LinearGradient(
                colors: [
                    Color(red: 0.32, green: 0.22, blue: 0.16),
                    Color(red: 0.20, green: 0.13, blue: 0.08),
                    Color(red: 0.12, green: 0.07, blue: 0.04)
                ],
                startPoint: .top, endPoint: .bottom
            )

            // Top 1px highlight line and bottom dark border
            VStack {
                Rectangle().fill(Color.white.opacity(0.22)).frame(height: 1)
                Spacer()
                Rectangle().fill(Color.black.opacity(0.85)).frame(height: 1)
            }

            // Centered Title
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .shadow(color: Color.black.opacity(0.85), radius: 0, x: 0, y: -1)

            // Done Button on Right
            HStack {
                Spacer()
                IOS6DoneButton(title: "Done", action: doneAction)
                    .padding(.trailing, 12)
            }
        }
        .frame(height: 46)
        .shadow(color: Color.black.opacity(0.35), radius: 3, x: 0, y: 2)
    }
}

// MARK: - iOS 6 Segmented Control Option
struct IOS6SegmentedOption {
    var title: LocalizedStringKey? = nil
    var icon: String? = nil
    let value: String

    init(title: LocalizedStringKey? = nil, icon: String? = nil, value: String) {
        self.title = title
        self.icon = icon
        self.value = value
    }
}

// MARK: - iOS 6 Segmented Control
struct IOS6SegmentedControl: View {
    @Binding var selected: String
    let options: [IOS6SegmentedOption]

    init(selected: Binding<String>, options: [IOS6SegmentedOption]) {
        self._selected = selected
        self.options = options
    }

    init(selected: Binding<String>, textOptions: [(title: LocalizedStringKey, value: String)]) {
        self._selected = selected
        self.options = textOptions.map { IOS6SegmentedOption(title: $0.title, value: $0.value) }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                let isSelected = selected == option.value
                Button {
                    selected = option.value
                } label: {
                    ZStack {
                        if isSelected {
                            // Inset dark glossy selected state
                            LinearGradient(
                                colors: [
                                    Color(red: 0.16, green: 0.22, blue: 0.32),
                                    Color(red: 0.28, green: 0.36, blue: 0.48)
                                ],
                                startPoint: .top, endPoint: .bottom
                            )
                            .overlay(
                                // Inset shadow
                                RoundedRectangle(cornerRadius: 0)
                                    .strokeBorder(Color.black.opacity(0.4), lineWidth: 1)
                            )
                        } else {
                            // Glossy silver unselected state
                            LinearGradient(
                                colors: [
                                    Color(white: 0.95),
                                    Color(white: 0.85),
                                    Color(white: 0.80)
                                ],
                                startPoint: .top, endPoint: .bottom
                            )
                            // Top gloss reflection
                            VStack {
                                LinearGradient(
                                    colors: [Color.white.opacity(0.6), Color.white.opacity(0.1)],
                                    startPoint: .top, endPoint: .bottom
                                )
                                .frame(height: 14)
                                Spacer()
                            }
                        }

                        HStack(spacing: 6) {
                            if let icon = option.icon {
                                Image(icon)
                                    .renderingMode(.original)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 18, height: 18)
                                    .clipShape(RoundedRectangle(cornerRadius: 3.5))
                                    .shadow(color: Color.black.opacity(isSelected ? 0.35 : 0.15), radius: 1, x: 0, y: 1)
                            }

                            if let title = option.title {
                                Text(title)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(
                                        isSelected
                                            ? Color.white
                                            : Color(red: 0.20, green: 0.22, blue: 0.26)
                                    )
                                    .shadow(
                                        color: isSelected
                                            ? Color.black.opacity(0.7)
                                            : Color.white.opacity(0.85),
                                        radius: 0,
                                        x: 0,
                                        y: isSelected ? -1 : 1
                                    )
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 34)
                }
                .buttonStyle(.plain)

                if index < options.count - 1 {
                    Rectangle()
                        .fill(Color(red: 0.50, green: 0.52, blue: 0.56))
                        .frame(width: 1, height: 34)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(Color(red: 0.45, green: 0.48, blue: 0.52), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 1, x: 0, y: 1)
        .shadow(color: Color.white.opacity(0.7), radius: 0, x: 0, y: 1)
    }
}

// MARK: - iOS 6 Glossy Action Button (For Home View New Note & Open File)
struct IOS6GlossyActionTile: View {
    let title: LocalizedStringKey
    let icon: String
    let isPrimary: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title)
                    .shadow(
                        color: isPrimary
                            ? Color.white.opacity(0.6)
                            : Color.black.opacity(0.8),
                        radius: 0,
                        x: 0,
                        y: isPrimary ? 1 : -1
                    )

                Text(title)
                    .font(.subheadline.bold())
                    .shadow(
                        color: isPrimary
                            ? Color.white.opacity(0.6)
                            : Color.black.opacity(0.8),
                        radius: 0,
                        x: 0,
                        y: isPrimary ? 1 : -1
                    )
            }
            .foregroundStyle(
                isPrimary
                    ? Color(red: 0.22, green: 0.15, blue: 0.05)
                    : Color(red: 0.95, green: 0.95, blue: 0.95)
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    if isPrimary {
                        // Glossy gold/yellow legal pad tone
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.88, blue: 0.45),
                                Color(red: 0.98, green: 0.76, blue: 0.20),
                                Color(red: 0.88, green: 0.65, blue: 0.12)
                            ],
                            startPoint: .top, endPoint: .bottom
                        )
                    } else {
                        // Glossy dark slate / leather tone
                        LinearGradient(
                            colors: [
                                Color(red: 0.32, green: 0.22, blue: 0.16),
                                Color(red: 0.22, green: 0.14, blue: 0.09),
                                Color(red: 0.14, green: 0.08, blue: 0.05)
                            ],
                            startPoint: .top, endPoint: .bottom
                        )
                    }

                    // Curved top specular gloss
                    VStack {
                        LinearGradient(
                            colors: [Color.white.opacity(isPrimary ? 0.5 : 0.25), Color.white.opacity(0.05)],
                            startPoint: .top, endPoint: .bottom
                        )
                        .frame(height: 28)
                        Spacer()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    // Border
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            isPrimary
                                ? Color(red: 0.65, green: 0.48, blue: 0.10)
                                : Color.black.opacity(0.75),
                            lineWidth: 1
                        )

                    // Bottom 1px light reflection
                    VStack {
                        Spacer()
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
                            .frame(height: 2)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .clipShape(RoundedRectangle(cornerRadius: 14))
            )
            .shadow(color: Color.black.opacity(0.35), radius: 4, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - iOS 6 Glass Gloss App Icon
struct IOS6GlossyAppIcon: View {
    let size: CGFloat

    var body: some View {
        Image("LegacyLogo")
            .renderingMode(.original)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .shadow(color: Color.black.opacity(0.45), radius: 6, x: 0, y: 3)
    }
}

struct IOS6IconGlossShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY * 0.6))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY),
            control: CGPoint(x: rect.midX, y: rect.maxY * 0.7)
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - iOS 6 Glossy Navigation Bar "Done" Button
struct IOS6DoneButton: View {
    let title: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .shadow(color: Color.black.opacity(0.7), radius: 0, x: 0, y: -1)
                .padding(.horizontal, 14)
                .frame(height: 30)
                .background(
                    ZStack {
                        // Glossy blue navigation button gradient
                        LinearGradient(
                            colors: [
                                Color(red: 0.25, green: 0.50, blue: 0.88),
                                Color(red: 0.12, green: 0.35, blue: 0.76),
                                Color(red: 0.08, green: 0.28, blue: 0.65)
                            ],
                            startPoint: .top, endPoint: .bottom
                        )

                        // Top specular gloss
                        VStack {
                            LinearGradient(
                                colors: [Color.white.opacity(0.5), Color.white.opacity(0.08)],
                                startPoint: .top, endPoint: .bottom
                            )
                            .frame(height: 14)
                            Spacer()
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 5))

                        RoundedRectangle(cornerRadius: 5)
                            .strokeBorder(Color(red: 0.06, green: 0.20, blue: 0.48), lineWidth: 1)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                )
                .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}

#endif
