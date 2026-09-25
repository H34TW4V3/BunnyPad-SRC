import SwiftUI
import UniformTypeIdentifiers

struct TextSnapshot: Sendable {
    var text: String
    var encoding: String.Encoding = .utf8
    var hasBOM = false
    var lineEnding = "\n"

    nonisolated static func decode(_ data: Data) throws -> TextSnapshot {
        guard data.count <= 16 * 1024 * 1024 else { throw TextFileError.tooLarge }
        let encoding: String.Encoding
        let payload: Data
        let hasBOM: Bool
        if data.starts(with: [0xFF, 0xFE]) {
            encoding = .utf16LittleEndian
            payload = data.dropFirst(2)
            hasBOM = true
        } else if data.starts(with: [0xFE, 0xFF]) {
            encoding = .utf16BigEndian
            payload = data.dropFirst(2)
            hasBOM = true
        } else {
            hasBOM = data.starts(with: [0xEF, 0xBB, 0xBF])
            payload = hasBOM ? data.dropFirst(3) : data
            encoding = String(data: payload, encoding: .utf8) == nil ? .isoLatin1 : .utf8
        }
        guard let text = String(data: payload, encoding: encoding), !text.contains("\0") else {
            throw TextFileError.unsupported
        }
        let ending = text.contains("\r\n") ? "\r\n" : (text.contains("\r") ? "\r" : "\n")
        return TextSnapshot(
            text: text.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n"),
            encoding: encoding, hasBOM: hasBOM, lineEnding: ending
        )
    }

    nonisolated func encoded() throws -> Data {
        let output = text.replacingOccurrences(of: "\n", with: lineEnding)
        guard var data = output.data(using: encoding, allowLossyConversion: false) else {
            throw TextFileError.unrepresentable
        }
        if hasBOM {
            let prefix: [UInt8] = encoding == .utf16LittleEndian ? [0xFF, 0xFE]
                : encoding == .utf16BigEndian ? [0xFE, 0xFF] : [0xEF, 0xBB, 0xBF]
            data.insert(contentsOf: prefix, at: 0)
        }
        guard data.count <= 16 * 1024 * 1024 else { throw TextFileError.tooLarge }
        return data
    }
}

enum TextFileError: LocalizedError {
    case tooLarge, unsupported, unrepresentable

    var errorDescription: String? {
        switch self {
        case .tooLarge: "This file is larger than BunnyPad’s 16 MB editing limit. The file has not been changed."
        case .unsupported: "This file is not a supported plain-text document."
        case .unrepresentable: "Some characters cannot be saved in the original encoding. Choose Format > Use UTF-8 Encoding, then save again."
        }
    }
}

@Observable
final class NoteDocument: Document {
    static let readableContentTypes: [UTType] = [.plainText, .text]
    static let writableContentTypes: [UTType] = [.plainText]
    var content = TextSnapshot(text: "")

    struct Reader: DocumentReader {
        @concurrent
        func read(from source: URL, progress: consuming Subprogress) async throws -> sending TextSnapshot {
            let handle = try FileHandle(forReadingFrom: source)
            defer { try? handle.close() }
            let data = try handle.read(upToCount: 16 * 1024 * 1024 + 1) ?? Data()
            return try TextSnapshot.decode(data)
        }
    }

    func reader(configuration: sending ReadConfiguration) -> sending Reader { Reader() }

    func writer(configuration: sending WriteConfiguration) -> sending FileWrapperDocumentWriter<TextSnapshot> {
        FileWrapperDocumentWriter(configuration) { snapshot, _ in
            FileWrapper(regularFileWithContents: try snapshot.encoded())
        }
    }

    func snapshot(contentType: UTType) async throws -> sending TextSnapshot { content }

    func apply(snapshot: sending TextSnapshot, previous: sending TextSnapshot?) async throws {
        content = snapshot
    }

    func replace(with newContent: TextSnapshot, undoManager: UndoManager?) {
        let previous = content
        undoManager?.registerUndo(withTarget: self) { document in
            document.replace(with: previous, undoManager: undoManager)
        }
        content = newContent
    }
}
