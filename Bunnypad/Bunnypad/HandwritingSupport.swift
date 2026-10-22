#if os(iOS)
import SwiftUI
import PencilKit
import UIKit
import Vision

// MARK: - Handwriting Recognizer
@MainActor
final class HandwritingRecognizer {
    static func recognizeText(from drawing: PKDrawing) async -> String {
        guard !drawing.bounds.isEmpty else { return "" }
        
        // 1. On iOS 27.0+, PKStrokeRecognizer provides stroke-level on-device recognition
        if #available(iOS 27.0, *) {
            let strokeRecognizer = PKStrokeRecognizer()
            await strokeRecognizer.updateDrawing(drawing)
            if let recognized = await strokeRecognizer.recognizedText(),
               !recognized.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return recognized.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        // 2. High-accuracy Vision OCR engine
        let paddedBounds = drawing.bounds.insetBy(dx: -24, dy: -24)
        let renderBounds = CGRect(
            x: max(0, paddedBounds.origin.x),
            y: max(0, paddedBounds.origin.y),
            width: max(100, paddedBounds.width),
            height: max(60, paddedBounds.height)
        )
        
        // Render drawing at 3x scale with white background for optimal OCR contrast
        let format = UIGraphicsImageRendererFormat()
        format.scale = 3.0
        let renderer = UIGraphicsImageRenderer(bounds: renderBounds, format: format)
        let renderedImage = renderer.image { context in
            UIColor.white.setFill()
            context.fill(renderBounds)
            drawing.image(from: renderBounds, scale: 3.0).draw(in: renderBounds)
        }
        
        guard let cgImage = renderedImage.cgImage else { return "" }
        
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { req, error in
                guard error == nil,
                      let observations = req.results as? [VNRecognizedTextObservation],
                      !observations.isEmpty else {
                    continuation.resume(returning: "")
                    return
                }
                
                // Sort observations by line top-to-bottom, then left-to-right
                // Note: Vision bounding boxes use normalized coordinates with (0,0) at bottom-left
                let sorted = observations.sorted { a, b in
                    let yA = a.boundingBox.origin.y
                    let yB = b.boundingBox.origin.y
                    if abs(yA - yB) > 0.035 {
                        return yA > yB // Higher Y in Vision is higher on page
                    }
                    return a.boundingBox.origin.x < b.boundingBox.origin.x
                }
                
                var lines: [String] = []
                for obs in sorted {
                    if let candidate = obs.topCandidates(1).first?.string {
                        let trimmed = candidate.trimmingCharacters(in: .whitespaces)
                        if !trimmed.isEmpty {
                            lines.append(trimmed)
                        }
                    }
                }
                
                continuation.resume(returning: lines.joined(separator: "\n"))
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            if #available(iOS 16.0, *) {
                request.automaticallyDetectsLanguage = true
            }
            request.recognitionLanguages = ["en-US", "en-GB", "es-ES", "fr-FR", "de-DE", "it-IT", "ja-JP", "zh-Hans"]
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(returning: "")
                }
            }
        }
    }
    
    static func renderImage(from drawing: PKDrawing, transparent: Bool = false) -> UIImage? {
        guard !drawing.bounds.isEmpty else { return nil }
        let bounds = drawing.bounds.insetBy(dx: -16, dy: -16)
        if transparent {
            return drawing.image(from: bounds, scale: 2.0)
        } else {
            let format = UIGraphicsImageRendererFormat()
            format.scale = 2.0
            let renderer = UIGraphicsImageRenderer(bounds: bounds, format: format)
            return renderer.image { context in
                UIColor.systemBackground.setFill()
                context.fill(bounds)
                drawing.image(from: bounds, scale: 2.0).draw(in: bounds)
            }
        }
    }
}

// MARK: - PencilKit Canvas Representable
struct HandwritingCanvasRepresentable: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    let allowsFingerDrawing: Bool
    var onDrawingChanged: ((PKDrawing) -> Void)?
    var onPencilDoubleTap: (() -> Void)?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        canvasView.drawing = drawing
        canvasView.delegate = context.coordinator
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.drawingPolicy = allowsFingerDrawing ? .anyInput : .pencilOnly
        canvasView.alwaysBounceVertical = true
        
        let toolPicker = PKToolPicker()
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        toolPicker.addObserver(context.coordinator)
        context.coordinator.toolPicker = toolPicker
        context.coordinator.canvasView = canvasView
        
        let pencilInteraction = UIPencilInteraction()
        pencilInteraction.delegate = context.coordinator
        canvasView.addInteraction(pencilInteraction)
        
        DispatchQueue.main.async {
            canvasView.becomeFirstResponder()
        }
        
        return canvasView
    }
    
    func updateUIView(_ canvasView: PKCanvasView, context: Context) {
        context.coordinator.parent = self
        
        let desiredPolicy: PKCanvasViewDrawingPolicy = allowsFingerDrawing ? .anyInput : .pencilOnly
        if canvasView.drawingPolicy != desiredPolicy {
            canvasView.drawingPolicy = desiredPolicy
        }
        
        if !context.coordinator.isInternalUpdate && canvasView.drawing != drawing {
            canvasView.drawing = drawing
        }
    }
    
    final class Coordinator: NSObject, PKCanvasViewDelegate, PKToolPickerObserver, UIPencilInteractionDelegate {
        var parent: HandwritingCanvasRepresentable
        weak var canvasView: PKCanvasView?
        var toolPicker: PKToolPicker?
        var isInternalUpdate = false
        
        init(_ parent: HandwritingCanvasRepresentable) {
            self.parent = parent
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            isInternalUpdate = true
            let newDrawing = canvasView.drawing
            parent.drawing = newDrawing
            parent.onDrawingChanged?(newDrawing)
            isInternalUpdate = false
        }
        
        func pencilInteractionDidTap(_ interaction: UIPencilInteraction) {
            Task { @MainActor in
                self.parent.onPencilDoubleTap?()
            }
        }
        
        @available(iOS 17.5, *)
        func pencilInteraction(_ interaction: UIPencilInteraction, didReceiveTap tap: UIPencilInteraction.Tap) {
            Task { @MainActor in
                self.parent.onPencilDoubleTap?()
            }
        }
    }
}

// MARK: - Full Handwriting Pad View
struct HandwritingPadView: View {
    @Binding var isPresented: Bool
    @Binding var drawing: PKDrawing
    let document: NoteDocument
    let session: EditorSession
    var theme: String = "gradient"
    
    @AppStorage("pencilOnlyDrawing") private var pencilOnlyDrawing = false
    @AppStorage("autoTranscribeHandwriting") private var autoTranscribeHandwriting = false
    
    @State private var isTranscribing = false
    @State private var transcribedPreview: String?
    @State private var showTranscribeResult = false
    @State private var toastMessage: String?
    
    var body: some View {
        ZStack {
            // Lined handwriting guide background
            handwritingBackground
                .ignoresSafeArea()
            
            // Interactive PencilKit Canvas
            HandwritingCanvasRepresentable(
                drawing: $drawing,
                allowsFingerDrawing: !pencilOnlyDrawing,
                onDrawingChanged: { _ in },
                onPencilDoubleTap: {
                    showToast("Apple Pencil Double-Tap")
                }
            )
            .ignoresSafeArea(edges: .bottom)
            
            // Floating control pill
            VStack {
                floatingControls
                    .padding(.top, 8)
                Spacer()
            }
            
            // Toast notification overlay
            if let toast = toastMessage {
                VStack {
                    Spacer()
                    Text(toast)
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: Capsule())
                        .shadow(radius: 6)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 36)
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: toastMessage)
            }
            
            // Transcribing activity indicator
            if isTranscribing {
                ZStack {
                    Color.black.opacity(0.35).ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.3)
                            .tint(.white)
                        Text("Transcribing Handwriting…")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    .padding(24)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
            }
        }
        .confirmationDialog(
            "Transcribed Handwriting",
            isPresented: $showTranscribeResult,
            titleVisibility: .visible
        ) {
            Button("Insert at End of Note") {
                if let text = transcribedPreview {
                    insertText(text, mode: .append)
                }
            }
            Button("Insert at Cursor Position") {
                if let text = transcribedPreview {
                    insertText(text, mode: .cursor)
                }
            }
            Button("Replace Whole Note", role: .destructive) {
                if let text = transcribedPreview {
                    insertText(text, mode: .replace)
                }
            }
            Button("Copy to Clipboard") {
                if let text = transcribedPreview {
                    UIPasteboard.general.string = text
                    showToast("Copied text to clipboard")
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let text = transcribedPreview {
                Text("\"\(text.prefix(120))\(text.count > 120 ? "…" : "")\"")
            }
        }
    }
    
    // MARK: - Handwriting Guide Background
    @ViewBuilder
    private var handwritingBackground: some View {
        if theme == "skeuomorphic" {
            // Authentic iOS 6 yellow legal pad with blue ruling
            IOS6PaperBackground()
        } else {
            // Modern subtle lined note paper
            ZStack {
                BunnyTheme.backgroundGradient(for: theme)
                GeometryReader { proxy in
                    Canvas { context, size in
                        let lineHeight: CGFloat = 32.0
                        var y: CGFloat = 40.0
                        while y < size.height {
                            var path = Path()
                            path.move(to: CGPoint(x: 20, y: y))
                            path.addLine(to: CGPoint(x: size.width - 20, y: y))
                            context.stroke(
                                path,
                                with: .color(Color.white.opacity(0.08)),
                                lineWidth: 1.0
                            )
                            y += lineHeight
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Floating Controls Pill
    private var floatingControls: some View {
        HStack(spacing: 8) {
            // Exit handwriting mode
            Button {
                if autoTranscribeHandwriting && !drawing.bounds.isEmpty {
                    Task {
                        await transcribeAndInsert(mode: .append)
                        withAnimation { isPresented = false }
                    }
                } else {
                    withAnimation { isPresented = false }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "text.alignleft")
                    Text("Text Mode")
                }
                .font(.system(size: 13, weight: .semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
            }
            
            Divider().frame(height: 18)
            
            // Transcribe to text
            Button {
                transcribeAction()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(BunnyTheme.gold)
                    Text("Transcribe")
                }
                .font(.system(size: 13, weight: .semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
            }
            .disabled(drawing.bounds.isEmpty)
            
            Divider().frame(height: 18)
            
            // Pencil only vs finger drawing toggle
            Button {
                pencilOnlyDrawing.toggle()
                showToast(pencilOnlyDrawing ? "Apple Pencil Only (Palm Rejection Active)" : "Apple Pencil & Finger Drawing")
            } label: {
                Image(systemName: pencilOnlyDrawing ? "applepencil" : "hand.draw.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(pencilOnlyDrawing ? BunnyTheme.gold : .white)
                    .frame(width: 30, height: 28)
            }
            .help("Toggle Apple Pencil only mode")
            
            // Copy drawing as image
            Button {
                copyDrawingImage()
            } label: {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: 30, height: 28)
            }
            .disabled(drawing.bounds.isEmpty)
            
            // Clear canvas
            Button {
                withAnimation {
                    drawing = PKDrawing()
                }
                showToast("Canvas Cleared")
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.red.opacity(0.85))
                    .frame(width: 30, height: 28)
            }
            .disabled(drawing.bounds.isEmpty)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(BunnyTheme.barGradient(for: theme))
                .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 4)
                .overlay(
                    Capsule()
                        .strokeBorder(
                            theme == "skeuomorphic"
                                ? AnyShapeStyle(LinearGradient(colors: [Color(red: 0.85, green: 0.72, blue: 0.42), Color(red: 0.50, green: 0.35, blue: 0.18)], startPoint: .top, endPoint: .bottom))
                                : AnyShapeStyle(.white.opacity(0.25)),
                            lineWidth: 1
                        )
                )
        )
        .foregroundStyle(BunnyTheme.textColor(for: theme))
    }
    
    // MARK: - Actions
    private func transcribeAction() {
        guard !drawing.bounds.isEmpty else {
            showToast("Write something on the canvas first!")
            return
        }
        isTranscribing = true
        Task {
            let recognized = await HandwritingRecognizer.recognizeText(from: drawing)
            isTranscribing = false
            if recognized.isEmpty {
                showToast("No handwriting recognized")
            } else {
                transcribedPreview = recognized
                showTranscribeResult = true
            }
        }
    }
    
    private enum InsertMode {
        case append
        case cursor
        case replace
    }
    
    private func insertText(_ text: String, mode: InsertMode) {
        switch mode {
        case .append:
            var current = document.content.text
            if !current.isEmpty && !current.hasSuffix("\n") {
                current += "\n\n"
            } else if !current.isEmpty {
                current += "\n"
            }
            current += text
            document.content.text = current
            session.textView?.text = current
            showToast("Appended to Note")
        case .cursor:
            if let textView = session.textView {
                if let range = textView.selectedTextRange {
                    textView.replace(range, withText: text)
                } else {
                    textView.insertText(text)
                }
                document.content.text = textView.text
            } else {
                insertText(text, mode: .append)
            }
            showToast("Inserted at Cursor")
        case .replace:
            document.content.text = text
            session.textView?.text = text
            showToast("Note Replaced with Handwriting")
        }
    }
    
    private func transcribeAndInsert(mode: InsertMode) async {
        let recognized = await HandwritingRecognizer.recognizeText(from: drawing)
        if !recognized.isEmpty {
            insertText(recognized, mode: mode)
        }
    }
    
    private func copyDrawingImage() {
        guard let img = HandwritingRecognizer.renderImage(from: drawing, transparent: false) else { return }
        UIPasteboard.general.image = img
        showToast("Drawing Copied to Clipboard")
    }
    
    private func showToast(_ msg: String) {
        toastMessage = msg
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if self.toastMessage == msg {
                self.toastMessage = nil
            }
        }
    }
}
#endif
