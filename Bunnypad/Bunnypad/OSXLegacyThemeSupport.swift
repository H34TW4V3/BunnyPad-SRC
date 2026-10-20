#if os(macOS)
import AppKit
import SwiftUI

// MARK: - OS X Aqua Preferences Tab
enum OSXPreferencesTab: String, CaseIterable, Identifiable {
    case general = "General"
    case editor = "Editor"
    case theme = "Theme"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .general: return "gearshape.fill"
        case .editor: return "textformat"
        case .theme: return "paintpalette.fill"
        }
    }
}

// MARK: - OS X Aqua Window Background
struct OSXAquaWindowBackground: View {
    var body: some View {
        ZStack {
            // Classic Mac OS X Platinum / Snow Leopard gradient
            LinearGradient(
                colors: [
                    Color(red: 0.94, green: 0.94, blue: 0.95),
                    Color(red: 0.89, green: 0.89, blue: 0.91),
                    Color(red: 0.83, green: 0.83, blue: 0.85)
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // Subtle 2px Aqua pinstripe texture
            Canvas { context, size in
                var y: CGFloat = 0
                while y < size.height {
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    context.stroke(path, with: .color(Color.black.opacity(0.025)), lineWidth: 1)
                    y += 2
                }
            }
            .ignoresSafeArea()
        }
    }
}

// MARK: - Classic OS X Cocoa Group Box (NSBox)
struct OSXGroupBox<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Group title with etched shadow
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color(red: 0.18, green: 0.18, blue: 0.20))
                .shadow(color: Color.white.opacity(0.85), radius: 0, x: 0, y: 1)
                .padding(.leading, 4)

            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(0.55))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Color.black.opacity(0.22), lineWidth: 1)
                    .shadow(color: Color.white.opacity(0.75), radius: 0, x: 0, y: 1)
            )
        }
    }
}

// MARK: - Classic OS X Snow Leopard Aqua Push Button
struct OSXAquaButton: View {
    let title: LocalizedStringKey
    var icon: String? = nil
    var isDefault: Bool = false
    let action: () -> Void

    @FocusState private var isFocused: Bool
    @State private var isHovered: Bool = false

    private var isBlue: Bool {
        isDefault || isFocused
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 12, weight: isBlue ? .bold : .regular))
            }
            .foregroundStyle(isBlue ? Color.white : Color(red: 0.12, green: 0.12, blue: 0.14))
            .shadow(
                color: isBlue
                    ? Color(red: 0.05, green: 0.16, blue: 0.45).opacity(0.85)
                    : Color.white.opacity(0.85),
                radius: 0,
                x: 0,
                y: isBlue ? -1 : 1
            )
            .padding(.horizontal, 14)
            .padding(.vertical, 4)
            .frame(minHeight: 21)
        }
        .buttonStyle(OSXAquaButtonStyle(isBlue: isBlue))
        .focused($isFocused)
        .focusable()
        .focusEffectDisabled()
        .tint(Color(red: 0.20, green: 0.55, blue: 0.95))
        .onHover { isHovered = $0 }
    }
}

struct OSXAquaButtonStyle: ButtonStyle {
    var isBlue: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                ZStack {
                    if isBlue {
                        // Snow Leopard Aqua Blue Glowing Button
                        // 1. Two-tone Jelly Glass split gradient
                        RoundedRectangle(cornerRadius: 4.5)
                            .fill(
                                configuration.isPressed
                                    ? LinearGradient(
                                        stops: [
                                            .init(color: Color(red: 0.06, green: 0.25, blue: 0.65), location: 0.0),
                                            .init(color: Color(red: 0.12, green: 0.42, blue: 0.82), location: 0.50),
                                            .init(color: Color(red: 0.05, green: 0.22, blue: 0.60), location: 0.51),
                                            .init(color: Color(red: 0.03, green: 0.16, blue: 0.50), location: 1.0)
                                        ],
                                        startPoint: .top, endPoint: .bottom
                                    )
                                    : LinearGradient(
                                        stops: [
                                            .init(color: Color(red: 0.55, green: 0.85, blue: 1.00), location: 0.0),
                                            .init(color: Color(red: 0.28, green: 0.65, blue: 0.96), location: 0.49),
                                            .init(color: Color(red: 0.10, green: 0.44, blue: 0.88), location: 0.50),
                                            .init(color: Color(red: 0.14, green: 0.54, blue: 0.94), location: 0.90),
                                            .init(color: Color(red: 0.20, green: 0.64, blue: 0.98), location: 1.0)
                                        ],
                                        startPoint: .top, endPoint: .bottom
                                    )
                            )

                        // 2. Specular highlight line / shine at top
                        VStack(spacing: 0) {
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(configuration.isPressed ? 0.1 : 0.65),
                                    Color.white.opacity(configuration.isPressed ? 0.0 : 0.15)
                                ],
                                startPoint: .top, endPoint: .bottom
                            )
                            .frame(height: 9)
                            Spacer()
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 4.5))

                        // 3. Crisp Inner border
                        RoundedRectangle(cornerRadius: 4.5)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.40, green: 0.78, blue: 1.0).opacity(0.7),
                                        Color(red: 0.06, green: 0.28, blue: 0.68).opacity(0.8)
                                    ],
                                    startPoint: .top, endPoint: .bottom
                                ),
                                lineWidth: 1
                            )

                        // 4. Dark Outer Border
                        RoundedRectangle(cornerRadius: 4.5)
                            .strokeBorder(Color(red: 0.05, green: 0.22, blue: 0.58), lineWidth: 1)
                    } else {
                        // Snow Leopard Standard Platinum Aqua Button
                        // 1. Two-tone Platinum split gradient
                        RoundedRectangle(cornerRadius: 4.5)
                            .fill(
                                configuration.isPressed
                                    ? LinearGradient(
                                        stops: [
                                            .init(color: Color(white: 0.65), location: 0.0),
                                            .init(color: Color(white: 0.76), location: 0.50),
                                            .init(color: Color(white: 0.60), location: 0.51),
                                            .init(color: Color(white: 0.56), location: 1.0)
                                        ],
                                        startPoint: .top, endPoint: .bottom
                                    )
                                    : LinearGradient(
                                        stops: [
                                            .init(color: Color(white: 0.99), location: 0.0),
                                            .init(color: Color(white: 0.92), location: 0.49),
                                            .init(color: Color(white: 0.81), location: 0.50),
                                            .init(color: Color(white: 0.85), location: 0.90),
                                            .init(color: Color(white: 0.89), location: 1.0)
                                        ],
                                        startPoint: .top, endPoint: .bottom
                                    )
                            )

                        // 2. Specular highlight line / shine at top
                        VStack(spacing: 0) {
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(configuration.isPressed ? 0.0 : 0.8),
                                    Color.white.opacity(configuration.isPressed ? 0.0 : 0.2)
                                ],
                                startPoint: .top, endPoint: .bottom
                            )
                            .frame(height: 9)
                            Spacer()
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 4.5))

                        // 3. Crisp Inner top highlight
                        VStack(spacing: 0) {
                            Rectangle()
                                .fill(Color.white.opacity(0.85))
                                .frame(height: 1)
                            Spacer()
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 4.5))

                        // 4. Dark Outer Border
                        RoundedRectangle(cornerRadius: 4.5)
                            .strokeBorder(Color(white: 0.42), lineWidth: 1)
                    }
                }
            )
            .shadow(
                color: isBlue
                    ? Color(red: 0.18, green: 0.52, blue: 0.95).opacity(0.80)
                    : Color.black.opacity(0.12),
                radius: isBlue ? 4 : 1,
                x: 0,
                y: isBlue ? 0 : 1
            )
            .overlay(
                // Snow Leopard authentic Aqua focus ring (Pure Sky Blue, strictly NO pink)
                Group {
                    if isBlue {
                        RoundedRectangle(cornerRadius: 5.5)
                            .strokeBorder(Color(red: 0.32, green: 0.68, blue: 1.0).opacity(0.80), lineWidth: 1.5)
                            .padding(-2)
                    }
                }
            )
    }
}

// MARK: - Classic OS X Aqua Checkbox
struct OSXAquaCheckbox: View {
    let title: LocalizedStringKey
    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 3.5)
                        .fill(
                            isOn
                                ? LinearGradient(
                                    colors: [
                                        Color(red: 0.22, green: 0.55, blue: 0.95),
                                        Color(red: 0.08, green: 0.38, blue: 0.85)
                                    ],
                                    startPoint: .top, endPoint: .bottom
                                )
                                : LinearGradient(
                                    colors: [
                                        Color(white: 0.98),
                                        Color(white: 0.88)
                                    ],
                                    startPoint: .top, endPoint: .bottom
                                )
                        )
                        .frame(width: 15, height: 15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3.5)
                                .strokeBorder(Color.black.opacity(0.38), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.15), radius: 1, x: 0, y: 0.5)

                    if isOn {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .shadow(color: Color.black.opacity(0.5), radius: 0, x: 0, y: -1)
                    }
                }

                Text(title)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color(red: 0.15, green: 0.15, blue: 0.18))
                    .shadow(color: Color.white.opacity(0.85), radius: 0, x: 0, y: 1)
            }
        }
        .buttonStyle(.plain)
        .focusEffectDisabled()
        .tint(Color(red: 0.20, green: 0.55, blue: 0.95))
    }
}

// MARK: - Classic OS X Aqua Slider
struct OSXAquaSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double = 1.0

    var body: some View {
        GeometryReader { proxy in
            let trackWidth = proxy.size.width
            let knobSize: CGFloat = 16
            let usableWidth = max(trackWidth - knobSize, 1)
            let fraction = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
            let knobX = min(max(CGFloat(fraction) * usableWidth, 0), usableWidth)

            ZStack(alignment: .leading) {
                // Inset metal groove track
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.65, green: 0.65, blue: 0.68),
                                Color(red: 0.88, green: 0.88, blue: 0.90)
                            ],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .frame(height: 5)
                    .overlay(
                        Capsule().strokeBorder(Color.black.opacity(0.35), lineWidth: 0.5)
                    )

                // Classic Mac OS X circular Aqua silver pointer knob
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white,
                                    Color(white: 0.90),
                                    Color(white: 0.78)
                                ],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .frame(width: knobSize, height: knobSize)

                    Circle()
                        .strokeBorder(Color(white: 0.60), lineWidth: 0.5)
                        .frame(width: knobSize - 4, height: knobSize - 4)

                    Circle()
                        .strokeBorder(Color.black.opacity(0.35), lineWidth: 0.8)
                        .frame(width: knobSize, height: knobSize)
                }
                .shadow(color: Color.black.opacity(0.25), radius: 1.5, x: 0, y: 1)
                .offset(x: knobX)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            let rawFraction = (gesture.location.x - knobSize / 2) / usableWidth
                            let clamped = min(max(Double(rawFraction), 0.0), 1.0)
                            let unstepped = range.lowerBound + clamped * (range.upperBound - range.lowerBound)
                            let stepped = (unstepped / step).rounded() * step
                            value = min(max(stepped, range.lowerBound), range.upperBound)
                        }
                )
            }
            .frame(height: 20)
        }
        .frame(height: 20)
    }
}

// MARK: - Classic OS X Preferences Top Toolbar
struct OSXPreferencesToolbar: View {
    @Binding var selectedTab: OSXPreferencesTab
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Brushed aluminum bar gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.92, green: 0.92, blue: 0.93),
                        Color(red: 0.82, green: 0.82, blue: 0.84)
                    ],
                    startPoint: .top, endPoint: .bottom
                )

                // Center: Iconic Preferences Tabs
                HStack(spacing: 18) {
                    ForEach(OSXPreferencesTab.allCases) { tab in
                        Button {
                            selectedTab = tab
                        } label: {
                            VStack(spacing: 3) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 20, weight: .regular))
                                    .foregroundStyle(
                                        selectedTab == tab
                                            ? Color(red: 0.08, green: 0.38, blue: 0.85)
                                            : Color(red: 0.25, green: 0.25, blue: 0.28)
                                    )
                                    .shadow(color: Color.white.opacity(0.8), radius: 0, x: 0, y: 1)

                                Text(LocalizedStringKey(tab.rawValue))
                                    .font(.system(size: 11, weight: selectedTab == tab ? .bold : .medium))
                                    .foregroundStyle(Color(red: 0.15, green: 0.15, blue: 0.18))
                                    .shadow(color: Color.white.opacity(0.8), radius: 0, x: 0, y: 1)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 5)
                            .background(
                                Group {
                                    if selectedTab == tab {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.black.opacity(0.12))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .strokeBorder(Color.black.opacity(0.20), lineWidth: 1)
                                            )
                                    }
                                }
                            )
                        }
                        .buttonStyle(.plain)
                        .focusEffectDisabled()
                        .tint(Color(red: 0.20, green: 0.55, blue: 0.95))
                    }
                }

                // If in a sheet modal, Done button on trailing side
                if let onDismiss {
                    HStack {
                        Spacer()
                        OSXAquaButton(title: "Done", action: onDismiss)
                            .padding(.trailing, 16)
                    }
                }
            }
            .frame(height: 60)

            // Bottom border with etched highlight line
            Rectangle()
                .fill(Color.black.opacity(0.35))
                .frame(height: 1)
            Rectangle()
                .fill(Color.white.opacity(0.65))
                .frame(height: 1)
        }
    }
}
#endif
