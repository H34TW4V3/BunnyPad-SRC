import AppIntents
import SwiftUI
import WidgetKit

@available(iOS 18.0, macOS 26.0, *)
struct BunnyPadControls: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.charasoft.bunnypad.quick-note") {
            ControlWidgetButton(action: OpenQuickNoteIntent()) {
                Label("Quick Note", systemImage: "square.and.pencil")
            }
        }
        .displayName("Quick Note")
        .description("Open BunnyPad and start a new quick note.")
    }
}
