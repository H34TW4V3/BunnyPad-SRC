import SwiftUI
import WidgetKit

@main
struct BunnyPadControlsBundle: WidgetBundle {
    var body: some Widget {
        QuickNoteWidget()
        if #available(iOS 18.0, macOS 26.0, *) {
            BunnyPadControls()
        }
    }
}
