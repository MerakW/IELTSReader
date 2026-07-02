import SwiftUI
import PDFKit
import UniformTypeIdentifiers
import ImageIO

enum AppConstants {
    static let projectURL = URL(string: "https://github.com/MerakW/IELTSReader")!
}

@main
struct IELTSReaderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            PracticeView()
                .frame(minWidth: 1180, minHeight: 760)
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About IELTSReader") {
                    AppInfoPresenter.showAbout()
                }
            }
            CommandGroup(after: .newItem) {
                Button("Import PDF...") {
                    NotificationCenter.default.post(name: .importPDFRequested, object: nil)
                }
                .keyboardShortcut("o")
                Button("Save Session...") {
                    NotificationCenter.default.post(name: .saveSessionRequested, object: nil)
                }
                .keyboardShortcut("s")
                Button("Load Session...") {
                    NotificationCenter.default.post(name: .loadSessionRequested, object: nil)
                }
                .keyboardShortcut("l")
            }
            CommandGroup(replacing: .help) {
                Button("IELTSReader Help") {
                    AppInfoPresenter.showHelp()
                }
                Button("GitHub Repository") {
                    NSWorkspace.shared.open(AppConstants.projectURL)
                }
            }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        StrictModeController.shared.applicationShouldTerminate()
    }

    func applicationDidResignActive(_ notification: Notification) {
        StrictModeController.shared.refocusIfNeeded()
    }
}

enum AppInfoPresenter {
    static func showAbout() {
        let alert = NSAlert()
        alert.messageText = "IELTSReader"
        alert.informativeText = """
        A native macOS reader for IELTS practice PDFs.

        Copyright © 2026 Merak

        GitHub:
        \(AppConstants.projectURL.absoluteString)
        """
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Open GitHub")
        if alert.runModal() == .alertSecondButtonReturn {
            NSWorkspace.shared.open(AppConstants.projectURL)
        }
    }

    static func showHelp() {
        let alert = NSAlert()
        alert.messageText = "IELTSReader Help"
        alert.informativeText = """
        Import PDF:
        Click Import to choose a practice PDF, then enter page ranges for Passage and Questions.

        Answering:
        The answer panel supports text answers, multiple choice, and TFNG. Edit any question number and the following rows update automatically.

        Markup:
        Select text in the PDF, then use Highlight, Underline, or Strikeout. The eraser clears markup from the selected text or the current page.

        Strict Mode:
        Strict Mode enters full screen and keeps the app focused. Unlocking, closing the window, or quitting asks for confirmation.

        Export and sessions:
        Export answers as text or image, or save a session to continue later.
        """
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Open GitHub")
        if alert.runModal() == .alertSecondButtonReturn {
            NSWorkspace.shared.open(AppConstants.projectURL)
        }
    }
}

extension Notification.Name {
    static let importPDFRequested = Notification.Name("importPDFRequested")
    static let saveSessionRequested = Notification.Name("saveSessionRequested")
    static let loadSessionRequested = Notification.Name("loadSessionRequested")
    static let markupRequested = Notification.Name("markupRequested")
}

struct PracticeView: View {
    @State private var pdfURL: URL?
    @State private var document: PDFDocument?
    @State private var passageStart = 1
    @State private var passageEnd = 1
    @State private var questionStart = 1
    @State private var questionEnd = 1
    @State private var selectedTool: MarkupTool = .select
    @State private var practiceTitle = "IELTS Answers"
    @State private var answers: [AnswerRow] = AnswerRow.defaultRows()
    @State private var elapsedSeconds = 0
    @State private var isTimerRunning = false
    @State private var isStrictModeEnabled = false
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var pageCount: Int {
        document?.pageCount ?? 1
    }

    var body: some View {
        VStack(spacing: 0) {
            toolbar

            ZStack(alignment: .bottomLeading) {
                if let document {
                    HSplitView {
                        PDFPane(
                            title: "Passage",
                            document: document,
                            startPage: $passageStart,
                            endPage: $passageEnd,
                            selectedTool: $selectedTool
                        )
                        .frame(minWidth: 420)

                        PDFPane(
                            title: "Questions",
                            document: document,
                            startPage: $questionStart,
                            endPage: $questionEnd,
                            selectedTool: $selectedTool
                        )
                        .frame(minWidth: 360)

                        AnswerPanel(answers: $answers)
                            .environment(\.practiceTitle, practiceTitle)
                            .frame(minWidth: 300, idealWidth: 340, maxWidth: 420)
                    }
                } else {
                    EmptyStateView(importAction: importPDF)
                }

                CreditView()
            }
        }
        .background(WindowBinder(title: windowTitle))
        .onReceive(NotificationCenter.default.publisher(for: .importPDFRequested)) { _ in
            importPDF()
        }
        .onReceive(NotificationCenter.default.publisher(for: .saveSessionRequested)) { _ in
            saveSession()
        }
        .onReceive(NotificationCenter.default.publisher(for: .loadSessionRequested)) { _ in
            loadSession()
        }
        .onReceive(timer) { _ in
            if isTimerRunning {
                elapsedSeconds += 1
            }
        }
    }

    private var toolbar: some View {
        HStack(spacing: 10) {
            Button(action: importPDF) {
                Label("Import", systemImage: "doc.badge.plus")
            }
            Button(action: saveSession) {
                Label("Save", systemImage: "square.and.arrow.down")
            }
            .disabled(document == nil)
            Button(action: loadSession) {
                Label("Load", systemImage: "square.and.arrow.up")
            }

            Divider()
                .frame(height: 22)

            TextField("Title", text: $practiceTitle)
                .textFieldStyle(.roundedBorder)
                .frame(width: 180)
                .help("Practice title")

            Divider()
                .frame(height: 22)

            ToolButton(tool: .select, selectedTool: $selectedTool)
            ToolButton(tool: .highlight, selectedTool: $selectedTool)
            ToolButton(tool: .underline, selectedTool: $selectedTool)
            ToolButton(tool: .strikeout, selectedTool: $selectedTool)
            ToolButton(tool: .erase, selectedTool: $selectedTool)

            Divider()
                .frame(height: 22)

            StrictModeButton(isEnabled: isStrictModeEnabled, action: toggleStrictMode)

            Divider()
                .frame(height: 22)

            Button(action: { isTimerRunning.toggle() }) {
                Label(isTimerRunning ? "Pause" : "Start", systemImage: isTimerRunning ? "pause.fill" : "play.fill")
            }
            Button(action: {
                elapsedSeconds = 0
                isTimerRunning = false
            }) {
                Image(systemName: "arrow.counterclockwise")
            }
            .help("Reset timer")

            Text(formattedTime)
                .monospacedDigit()
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 72, alignment: .leading)

            Spacer()

            if let pdfURL {
                Text(pdfURL.lastPathComponent)
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(.bar)
    }

    private var formattedTime: String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var windowTitle: String {
        practiceTitle.isEmpty ? "IELTSReader" : "IELTSReader - \(practiceTitle)"
    }

    private func importPDF() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url, let loaded = PDFDocument(url: url) {
            pdfURL = url
            document = loaded
            practiceTitle = url.deletingPathExtension().lastPathComponent
            passageStart = 1
            passageEnd = min(2, loaded.pageCount)
            questionStart = min(3, max(1, loaded.pageCount))
            questionEnd = loaded.pageCount
            answers = AnswerRow.defaultRows()
            elapsedSeconds = 0
            isTimerRunning = false
        }
    }

    private func saveSession() {
        guard let pdfURL else { return }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "\(practiceTitle.safeFilename).ielts-session.json"
        if panel.runModal() == .OK, let url = panel.url {
            let session = PracticeSession(
                title: practiceTitle,
                pdfPath: pdfURL.path,
                passageStart: passageStart,
                passageEnd: passageEnd,
                questionStart: questionStart,
                questionEnd: questionEnd,
                elapsedSeconds: elapsedSeconds,
                answers: answers
            )
            do {
                let data = try JSONEncoder.pretty.encode(session)
                try data.write(to: url, options: .atomic)
            } catch {
                showAlert(title: "Could not save session", message: error.localizedDescription)
            }
        }
    }

    private func loadSession() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            do {
                let data = try Data(contentsOf: url)
                let session = try JSONDecoder().decode(PracticeSession.self, from: data)
                let pdfFileURL = URL(fileURLWithPath: session.pdfPath)
                guard let loaded = PDFDocument(url: pdfFileURL) else {
                    showAlert(title: "Could not open PDF", message: session.pdfPath)
                    return
                }

                pdfURL = pdfFileURL
                document = loaded
                practiceTitle = session.title ?? pdfFileURL.deletingPathExtension().lastPathComponent
                passageStart = session.passageStart
                passageEnd = session.passageEnd
                questionStart = session.questionStart
                questionEnd = session.questionEnd
                elapsedSeconds = session.elapsedSeconds
                answers = session.answers
                isTimerRunning = false
            } catch {
                showAlert(title: "Could not load session", message: error.localizedDescription)
            }
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.runModal()
    }

    private func toggleStrictMode() {
        if isStrictModeEnabled {
            guard StrictModeController.shared.confirmDisableStrictMode() else { return }
            isStrictModeEnabled = false
            StrictModeController.shared.setEnabled(false)
        } else {
            isStrictModeEnabled = true
            StrictModeController.shared.setEnabled(true)
        }
    }
}

struct WindowBinder: NSViewRepresentable {
    let title: String

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            if let window = view.window {
                StrictModeController.shared.attach(window)
                window.title = title
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if let window = nsView.window {
                StrictModeController.shared.attach(window)
                window.title = title
            }
        }
    }
}

struct CreditView: View {
    var body: some View {
        Text("© Merak")
        .font(.system(size: 10))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(VisualEffectBackground(material: .hudWindow, blendingMode: .withinWindow))
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color.white.opacity(0.18), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
        .padding(8)
        .allowsHitTesting(false)
    }
}

struct VisualEffectBackground: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        view.isEmphasized = false
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = .active
    }
}

struct StrictModeButton: View {
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 6) {
                    Image(systemName: isEnabled ? "lock.fill" : "lock.open")
                        .foregroundStyle(isEnabled ? Color.red : Color.secondary)
                    Text(isEnabled ? "Strict On" : "Strict Off")
                        .foregroundStyle(Color.primary)
                }

                Image(systemName: isEnabled ? "lock.fill" : "lock.open")
                    .foregroundStyle(isEnabled ? Color.red : Color.secondary)
            }
            .font(.system(size: 12, weight: .semibold))
            .frame(height: 24)
            .padding(.horizontal, 8)
            .background(isEnabled ? Color.red.opacity(0.12) : Color(nsColor: .controlBackgroundColor))
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(isEnabled ? Color.red.opacity(0.45) : Color.secondary.opacity(0.25), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
        .help("Strict mode: full screen, refocus app, confirm before exit")
    }
}

final class StrictModeController: NSObject, NSWindowDelegate {
    static let shared = StrictModeController()

    private weak var window: NSWindow?
    private var isEnabled = false
    private var focusTimer: Timer?
    private var isConfirmingExit = false

    func attach(_ window: NSWindow) {
        self.window = window
        window.delegate = self
        if isEnabled {
            enterStrictMode()
        }
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        enabled ? enterStrictMode() : leaveStrictMode()
    }

    func confirmDisableStrictMode() -> Bool {
        confirmStrictModeExit(
            title: "Disable strict mode?",
            message: "This will unlock the practice window and exit full screen."
        )
    }

    func refocusIfNeeded() {
        guard isEnabled else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.refocus()
        }
    }

    func applicationShouldTerminate() -> NSApplication.TerminateReply {
        guard isEnabled, !isConfirmingExit else { return .terminateNow }
        return confirmStrictModeExit(
            title: "Exit strict mode?",
            message: "Strict mode is active. Are you sure you want to leave the practice window?"
        ) ? .terminateNow : .terminateCancel
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        guard isEnabled, !isConfirmingExit else { return true }
        return confirmStrictModeExit(
            title: "Exit strict mode?",
            message: "Strict mode is active. Are you sure you want to close the practice window?"
        )
    }

    private func enterStrictMode() {
        guard let window else { return }
        window.collectionBehavior.insert(.fullScreenPrimary)
        if !window.styleMask.contains(.fullScreen) {
            window.toggleFullScreen(nil)
        }
        refocus()
        focusTimer?.invalidate()
        focusTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.refocus()
        }
    }

    private func leaveStrictMode() {
        focusTimer?.invalidate()
        focusTimer = nil
        if let window, window.styleMask.contains(.fullScreen) {
            window.toggleFullScreen(nil)
        }
    }

    private func refocus() {
        guard isEnabled, let window else { return }
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    private func confirmStrictModeExit(title: String, message: String) -> Bool {
        isConfirmingExit = true
        defer { isConfirmingExit = false }

        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Stay")
        alert.addButton(withTitle: "Confirm")
        return alert.runModal() == .alertSecondButtonReturn
    }
}

struct EmptyStateView: View {
    let importAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("Import an IELTS reading PDF")
                .font(.title2)
            Button(action: importAction) {
                Label("Choose PDF", systemImage: "folder")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PDFPane: View {
    let title: String
    let document: PDFDocument
    @Binding var startPage: Int
    @Binding var endPage: Int
    @Binding var selectedTool: MarkupTool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                PageRangeFields(
                    startPage: $startPage,
                    endPage: $endPage,
                    pageCount: max(1, document.pageCount)
                )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(nsColor: .windowBackgroundColor))

            PDFKitView(document: document, startPage: startPage, endPage: endPage, selectedTool: selectedTool)
        }
        .onChange(of: startPage) { newValue in
            if newValue > endPage {
                endPage = newValue
            }
        }
        .onChange(of: endPage) { newValue in
            if newValue < startPage {
                startPage = newValue
            }
        }
    }
}

struct PageRangeFields: View {
    @Binding var startPage: Int
    @Binding var endPage: Int
    let pageCount: Int

    @State private var startDraft = ""
    @State private var endDraft = ""
    @FocusState private var focusedField: PageField?

    var body: some View {
        HStack(spacing: 6) {
            Text("From")
                .foregroundStyle(.secondary)
            TextField("1", text: $startDraft)
                .textFieldStyle(.roundedBorder)
                .frame(width: 54)
                .multilineTextAlignment(.center)
                .focused($focusedField, equals: .start)
                .onSubmit(commitDrafts)

            Text("to")
                .foregroundStyle(.secondary)
            TextField("\(pageCount)", text: $endDraft)
                .textFieldStyle(.roundedBorder)
                .frame(width: 54)
                .multilineTextAlignment(.center)
                .focused($focusedField, equals: .end)
                .onSubmit(commitDrafts)

            Text("/ \(pageCount)")
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .font(.system(size: 12))
        .onAppear(perform: syncDrafts)
        .onChange(of: focusedField) { newValue in
            if newValue == nil {
                commitDrafts()
            }
        }
        .onChange(of: pageCount) { _ in
            commitDrafts()
        }
        .onChange(of: startPage) { _ in
            if focusedField != .start {
                syncDrafts()
            }
        }
        .onChange(of: endPage) { _ in
            if focusedField != .end {
                syncDrafts()
            }
        }
    }

    private func commitDrafts() {
        let parsedStart = Int(startDraft.filter(\.isNumber)) ?? startPage
        let parsedEnd = Int(endDraft.filter(\.isNumber)) ?? endPage
        let nextStart = parsedStart.clamped(to: 1...pageCount)
        var nextEnd = parsedEnd.clamped(to: 1...pageCount)
        if nextStart > nextEnd {
            nextEnd = nextStart
        }
        startPage = nextStart
        endPage = nextEnd
        syncDrafts()
    }

    private func syncDrafts() {
        startDraft = "\(startPage)"
        endDraft = "\(endPage)"
    }

    private enum PageField {
        case start
        case end
    }
}

extension NumberFormatter {
    static var wholeNumber: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.allowsFloats = false
        formatter.minimum = 1
        formatter.numberStyle = .none
        return formatter
    }
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}

struct PDFKitView: NSViewRepresentable {
    let document: PDFDocument
    let startPage: Int
    let endPage: Int
    let selectedTool: MarkupTool

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> PDFView {
        let pdfView = PracticePDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = .textBackgroundColor
        context.coordinator.pdfView = pdfView
        context.coordinator.startObservingMarkupRequests()
        return pdfView
    }

    func updateNSView(_ pdfView: PDFView, context: Context) {
        context.coordinator.selectedTool = selectedTool
        let pageRange = PageRange(start: startPage, end: endPage)
        guard context.coordinator.sourceDocument !== document || context.coordinator.pageRange != pageRange else {
            return
        }

        context.coordinator.sourceDocument = document
        context.coordinator.pageRange = pageRange
        let clipped = document.pageSubset(from: startPage, through: endPage)
        context.coordinator.displayDocument = clipped
        pdfView.document = clipped
        pdfView.goToFirstPage(nil)
    }

    final class Coordinator: NSObject {
        weak var pdfView: PDFView?
        weak var sourceDocument: PDFDocument?
        var displayDocument: PDFDocument?
        var pageRange: PageRange?
        var selectedTool: MarkupTool = .select
        private var isObservingMarkupRequests = false

        func startObservingMarkupRequests() {
            guard !isObservingMarkupRequests else { return }
            isObservingMarkupRequests = true
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleMarkupRequest(_:)),
                name: .markupRequested,
                object: nil
            )
        }

        @objc private func handleMarkupRequest(_ notification: Notification) {
            guard let tool = notification.object as? MarkupTool,
                  let pdfView,
                  ActivePDFViewStore.current === pdfView || pdfView.currentSelection?.string?.isEmpty == false
            else { return }

            if tool == .erase {
                eraseMarkup(in: pdfView)
            } else {
                applyMarkup(tool, in: pdfView)
            }
        }

        private func applyMarkup(_ tool: MarkupTool, in pdfView: PDFView) {
            guard let selection = pdfView.currentSelection,
                  selection.string?.isEmpty == false,
                  tool.annotationType != nil
            else { return }

            for lineSelection in selection.selectionsByLine() {
                for page in lineSelection.pages {
                    let bounds = lineSelection.bounds(for: page)
                    guard !bounds.isEmpty,
                          let annotationType = tool.annotationType
                    else { continue }

                    let annotation = PDFAnnotation(bounds: bounds.insetBy(dx: -1, dy: -1), forType: annotationType, withProperties: nil)
                    annotation.color = tool.color
                    page.addAnnotation(annotation)
                }
            }
            pdfView.setCurrentSelection(nil, animate: true)
        }

        private func eraseMarkup(in pdfView: PDFView) {
            if let selection = pdfView.currentSelection, selection.string?.isEmpty == false {
                eraseMarkupTouching(selection)
                pdfView.setCurrentSelection(nil, animate: true)
            } else if let page = pdfView.currentPage {
                eraseAllMarkup(on: page)
            }
        }

        private func eraseMarkupTouching(_ selection: PDFSelection) {
            for lineSelection in selection.selectionsByLine() {
                for page in lineSelection.pages {
                    let bounds = lineSelection.bounds(for: page).insetBy(dx: -2, dy: -2)
                    for annotation in page.annotations where annotation.isTextMarkup && annotation.bounds.intersects(bounds) {
                        page.removeAnnotation(annotation)
                    }
                }
            }
        }

        private func eraseAllMarkup(on page: PDFPage) {
            for annotation in page.annotations.reversed() where annotation.isTextMarkup {
                page.removeAnnotation(annotation)
            }
        }
    }
}

final class PracticePDFView: PDFView {
    override func mouseDown(with event: NSEvent) {
        ActivePDFViewStore.current = self
        super.mouseDown(with: event)
    }

    override func mouseDragged(with event: NSEvent) {
        ActivePDFViewStore.current = self
        super.mouseDragged(with: event)
    }

    override func mouseMoved(with event: NSEvent) {
        ActivePDFViewStore.current = self
        super.mouseMoved(with: event)
    }
}

enum ActivePDFViewStore {
    weak static var current: PDFView?
}

struct PageRange: Equatable {
    var start: Int
    var end: Int
}

extension PDFDocument {
    func pageSubset(from startPage: Int, through endPage: Int) -> PDFDocument {
        let subset = PDFDocument()
        guard pageCount > 0 else { return subset }

        let lower = max(0, min(startPage - 1, pageCount - 1))
        let upper = max(lower, min(endPage - 1, pageCount - 1))
        for index in lower...upper {
            if let page = page(at: index),
               let copiedPage = page.copyForDisplay() {
                subset.insert(copiedPage, at: subset.pageCount)
            }
        }
        return subset
    }
}

extension PDFPage {
    func copyForDisplay() -> PDFPage? {
        guard let data = dataRepresentation else {
            return copy() as? PDFPage
        }
        return PDFDocument(data: data)?.page(at: 0)
    }
}

enum MarkupTool: String, CaseIterable {
    case select
    case highlight
    case underline
    case strikeout
    case erase

    var icon: String {
        switch self {
        case .select: return "cursorarrow"
        case .highlight: return "highlighter"
        case .underline: return "underline"
        case .strikeout: return "strikethrough"
        case .erase: return "eraser"
        }
    }

    var label: String {
        switch self {
        case .select: return "Select"
        case .highlight: return "Highlight"
        case .underline: return "Underline"
        case .strikeout: return "Strikeout"
        case .erase: return "Clear markup"
        }
    }

    var annotationType: PDFAnnotationSubtype? {
        switch self {
        case .select, .erase: return nil
        case .highlight: return .highlight
        case .underline: return .underline
        case .strikeout: return .strikeOut
        }
    }

    var color: NSColor {
        switch self {
        case .select, .erase: return .clear
        case .highlight: return NSColor.systemYellow.withAlphaComponent(0.45)
        case .underline: return .systemBlue
        case .strikeout: return .systemRed
        }
    }
}

struct ToolButton: View {
    let tool: MarkupTool
    @Binding var selectedTool: MarkupTool

    var body: some View {
        Button(action: useTool) {
            Image(systemName: tool.icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(selectedTool == tool ? Color.accentColor : Color.primary)
                .frame(width: 28, height: 24)
                .background(selectedTool == tool ? Color.accentColor.opacity(0.14) : Color(nsColor: .controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(selectedTool == tool ? Color.accentColor.opacity(0.45) : Color.secondary.opacity(0.22), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .frame(width: 30, height: 26)
        .help(tool.label)
    }

    private func useTool() {
        selectedTool = tool == .erase ? .select : tool
        guard tool != .select else { return }
        NotificationCenter.default.post(name: .markupRequested, object: tool)
    }
}

extension PDFAnnotation {
    var isTextMarkup: Bool {
        let normalizedType = (type ?? "").lowercased()
            .replacingOccurrences(of: "/", with: "")
            .replacingOccurrences(of: " ", with: "")
        return ["highlight", "underline", "strikeout"].contains(normalizedType)
    }
}

struct AnswerPanel: View {
    @Binding var answers: [AnswerRow]
    @Environment(\.practiceTitle) private var practiceTitle
    @State private var showsCopyToast = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                HStack {
                    Text("Answers")
                        .font(.headline)
                    Spacer()
                    Button(action: copyText) {
                        Image(systemName: "doc.on.clipboard")
                    }
                    .help("Copy answers as text")
                    Button(action: exportImage) {
                        Image(systemName: "photo")
                    }
                    .help("Export answers as image")
                    Button(action: addRow) {
                        Image(systemName: "plus")
                    }
                    .help("Add question")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(nsColor: .windowBackgroundColor))

                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(answers.indices, id: \.self) { index in
                            AnswerRowView(
                                answer: $answers[index],
                                numberChanged: { newNumber in
                                    renumber(from: index, firstNumber: newNumber)
                                }
                            )
                        }
                    }
                    .padding(12)
                }
            }

            if showsCopyToast {
                Label("Copied to clipboard", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(VisualEffectBackground(material: .hudWindow, blendingMode: .withinWindow))
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                    .shadow(color: Color.black.opacity(0.14), radius: 8, x: 0, y: 3)
                    .padding(.top, 48)
                    .padding(.trailing, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private func addRow() {
        let next = (answers.map(\.number).max() ?? 0) + 1
        answers.append(AnswerRow(number: next, kind: .text, value: "", isFlagged: false))
    }

    private func renumber(from index: Int, firstNumber: Int) {
        guard answers.indices.contains(index) else { return }
        for offset in index..<answers.count {
            answers[offset].number = firstNumber + offset - index
        }
    }

    private func copyText() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(answers.exportText(title: practiceTitle), forType: .string)

        withAnimation(.easeOut(duration: 0.16)) {
            showsCopyToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(.easeIn(duration: 0.18)) {
                showsCopyToast = false
            }
        }
    }

    private func exportImage() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "\(practiceTitle.safeFilename)-answers.png"
        if panel.runModal() == .OK, let url = panel.url {
            do {
                guard let data = AnswerImageRenderer.pngData(title: practiceTitle, answers: answers) else {
                    throw ExportError.couldNotCreatePNG
                }
                try data.write(to: url, options: .atomic)
            } catch {
                showExportAlert(error)
            }
        }
    }

    private func showExportAlert(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "Could not export answers"
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.runModal()
    }
}

struct AnswerRowView: View {
    @Binding var answer: AnswerRow
    let numberChanged: (Int) -> Void
    @State private var numberDraft = ""
    @FocusState private var isNumberFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                TextField("", text: $numberDraft)
                    .textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 28, height: 24)
                    .focused($isNumberFocused)
                    .onSubmit(commitNumber)
                    .help("Edit question number")

                HStack(spacing: 4) {
                    ForEach(AnswerKind.allCases) { kind in
                        Button {
                            if answer.kind != kind {
                                answer.kind = kind
                                answer.value = ""
                            }
                        } label: {
                            Text(kind.shortLabel)
                                .font(.system(size: 11, weight: .semibold))
                                .frame(width: 54, height: 22)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(answer.kind == kind ? Color.white : Color.primary)
                        .background(answer.kind == kind ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(answer.kind == kind ? Color.accentColor : Color.secondary.opacity(0.25), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                        .help(kind.label)
                    }
                }

                Spacer()

                Toggle(isOn: $answer.isFlagged) {
                    Image(systemName: answer.isFlagged ? "flag.fill" : "flag")
                }
                .toggleStyle(.button)
                .labelsHidden()
                .help("Mark for review")
            }

            answerInput
        }
        .padding(9)
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onAppear(perform: syncNumberDraft)
        .onChange(of: isNumberFocused) { focused in
            if !focused {
                commitNumber()
            }
        }
        .onChange(of: answer.number) { _ in
            if !isNumberFocused {
                syncNumberDraft()
            }
        }
    }

    @ViewBuilder
    private var answerInput: some View {
        switch answer.kind {
        case .text:
            TextField("Type answer", text: $answer.value)
                .textFieldStyle(.roundedBorder)
        case .choice:
            Picker("Choice", selection: $answer.value) {
                ForEach(["", "A", "B", "C", "D", "E", "F"], id: \.self) { option in
                    Text(option.isEmpty ? "-" : option).tag(option)
                }
            }
            .pickerStyle(.segmented)
        case .tfng:
            Picker("TFNG", selection: $answer.value) {
                ForEach(["", "True", "False", "Not Given"], id: \.self) { option in
                    Text(option.isEmpty ? "-" : option).tag(option)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private func commitNumber() {
        let parsed = Int(numberDraft.filter(\.isNumber)) ?? answer.number
        let next = max(1, parsed)
        if next != answer.number {
            numberChanged(next)
        }
        numberDraft = "\(next)"
    }

    private func syncNumberDraft() {
        numberDraft = "\(answer.number)"
    }
}

struct AnswerRow: Identifiable, Codable {
    let id: UUID
    var number: Int
    var kind: AnswerKind
    var value: String
    var isFlagged: Bool

    init(id: UUID = UUID(), number: Int, kind: AnswerKind, value: String, isFlagged: Bool) {
        self.id = id
        self.number = number
        self.kind = kind
        self.value = value
        self.isFlagged = isFlagged
    }

    static func defaultRows() -> [AnswerRow] {
        (1...13).map { AnswerRow(number: $0, kind: .text, value: "", isFlagged: false) }
    }
}

struct PracticeSession: Codable {
    var title: String?
    var pdfPath: String
    var passageStart: Int
    var passageEnd: Int
    var questionStart: Int
    var questionEnd: Int
    var elapsedSeconds: Int
    var answers: [AnswerRow]
}

extension Array where Element == AnswerRow {
    func exportText(title: String) -> String {
        let lines = map { row in
            let marker = row.isFlagged ? " *" : ""
            let value = row.value.isEmpty ? "-" : row.value
            return "\(row.number). \(value) [\(row.kind.label)]\(marker)"
        }
        return ([title, ""] + lines).joined(separator: "\n")
    }
}

enum ExportError: LocalizedError {
    case couldNotCreatePNG

    var errorDescription: String? {
        switch self {
        case .couldNotCreatePNG:
            return "The answer image could not be created."
        }
    }
}

struct AnswerImageRenderer {
    private static let inkColor = NSColor(calibratedWhite: 0.12, alpha: 1)
    private static let mutedInkColor = NSColor(calibratedWhite: 0.42, alpha: 1)
    private static let faintInkColor = NSColor(calibratedWhite: 0.74, alpha: 1)
    private static let ruleColor = NSColor(calibratedWhite: 0.88, alpha: 1)

    static func pngData(title: String, answers: [AnswerRow]) -> Data? {
        let rowHeight: CGFloat = 32
        let headerHeight: CGFloat = 44
        let footerHeight: CGFloat = 28
        let width: CGFloat = 720
        let height = headerHeight + CGFloat(max(answers.count, 1)) * rowHeight + footerHeight + 24
        let pixelSize = CGSize(width: width, height: height)
        let bytesPerRow = Int(width) * 4
        guard let context = CGContext(
            data: nil,
            width: Int(width),
            height: Int(height),
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
        defer {
            NSGraphicsContext.restoreGraphicsState()
        }

        NSColor.white.setFill()
        NSBezierPath(rect: CGRect(origin: .zero, size: pixelSize)).fill()

        drawText(title.isEmpty ? "IELTS Answers" : title, in: CGRect(x: 24, y: height - 34, width: width - 48, height: 22), font: .boldSystemFont(ofSize: 18), color: inkColor)
        drawText("Question", in: CGRect(x: 24, y: height - 66, width: 90, height: 18), font: .boldSystemFont(ofSize: 12), color: mutedInkColor)
        drawText("Answer", in: CGRect(x: 128, y: height - 66, width: 360, height: 18), font: .boldSystemFont(ofSize: 12), color: mutedInkColor)
        drawText("Type", in: CGRect(x: 510, y: height - 66, width: 120, height: 18), font: .boldSystemFont(ofSize: 12), color: mutedInkColor)

        ruleColor.setStroke()
        NSBezierPath.strokeLine(from: CGPoint(x: 24, y: height - 72), to: CGPoint(x: width - 24, y: height - 72))

        for (index, answer) in answers.sorted(by: { $0.number < $1.number }).enumerated() {
            let y = height - 96 - CGFloat(index) * rowHeight
            let value = answer.value.isEmpty ? "-" : answer.value
            let flag = answer.isFlagged ? "  *" : ""
            drawText("\(answer.number)", in: CGRect(x: 24, y: y, width: 80, height: 18), font: .monospacedDigitSystemFont(ofSize: 13, weight: .medium), color: inkColor)
            drawText(value + flag, in: CGRect(x: 128, y: y, width: 360, height: 18), font: .systemFont(ofSize: 13), color: inkColor)
            drawText(answer.kind.label, in: CGRect(x: 510, y: y, width: 140, height: 18), font: .systemFont(ofSize: 13), color: mutedInkColor)
        }

        drawText("IELTSReader · 2026 · Merak", in: CGRect(x: 24, y: 12, width: width - 48, height: 16), font: .systemFont(ofSize: 10), color: faintInkColor)

        guard let cgImage = context.makeImage() else { return nil }
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil) else {
            return nil
        }
        CGImageDestinationAddImage(destination, cgImage, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return data as Data
    }

    private static func drawText(_ text: String, in rect: CGRect, font: NSFont, color: NSColor = inkColor) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byTruncatingTail
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ]
        text.draw(in: rect, withAttributes: attributes)
    }
}

extension NSImage {
    var pngData: Data? {
        guard let tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffRepresentation)
        else { return nil }
        return bitmap.representation(using: .png, properties: [:])
    }
}

private struct PracticeTitleKey: EnvironmentKey {
    static let defaultValue = "IELTS Answers"
}

extension EnvironmentValues {
    var practiceTitle: String {
        get { self[PracticeTitleKey.self] }
        set { self[PracticeTitleKey.self] = newValue }
    }
}

extension String {
    var safeFilename: String {
        let invalid = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        let cleaned = components(separatedBy: invalid).joined(separator: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? "ielts-practice" : cleaned
    }
}

extension JSONEncoder {
    static var pretty: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

enum AnswerKind: String, CaseIterable, Codable, Identifiable {
    case text
    case choice
    case tfng

    var id: String { rawValue }

    var label: String {
        switch self {
        case .text: return "Text"
        case .choice: return "Choice"
        case .tfng: return "TFNG"
        }
    }

    var shortLabel: String {
        switch self {
        case .text: return "Text"
        case .choice: return "Choices"
        case .tfng: return "TFNG"
        }
    }
}
