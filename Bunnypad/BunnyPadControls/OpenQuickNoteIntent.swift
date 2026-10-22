import AppIntents
import Foundation

// Keep this intent's type and target identical in the app and control extension.
// OpenIntent executes in the containing app, including when it launches cold.
enum QuickNoteDestination: String, AppEnum {
    case newNote

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Quick Note")
    static let caseDisplayRepresentations: [QuickNoteDestination: DisplayRepresentation] = [
        .newNote: "New Quick Note"
    ]
}

struct OpenQuickNoteIntent: OpenIntent {
    static let title: LocalizedStringResource = "New Quick Note"
    static let description = IntentDescription("Opens BunnyPad with a new quick note or opens a recent note.")
    static let openAppWhenRun = true

    @Parameter(title: "Destination")
    var target: QuickNoteDestination

    @Parameter(title: "File Path")
    var filePath: String?

    init() {
        target = .newNote
        filePath = nil
    }

    init(filePath: String?) {
        target = .newNote
        self.filePath = filePath
    }

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            if let filePath, !filePath.isEmpty {
                UserDefaults.standard.set(filePath, forKey: "controlOpenDocumentPath")
            } else {
                UserDefaults.standard.set(UUID().uuidString, forKey: "controlQuickNoteRequest")
            }
        }
        return .result()
    }
}
