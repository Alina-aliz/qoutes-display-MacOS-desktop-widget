import Cocoa

final class OverlayPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: OverlayPanel!
    var textField: NSTextField!

    var reloadTimer: Timer?
    var rotateTimer: Timer?

    var messages: [String] = ["hello"]
    var currentIndex = 0

    let messagesPath = "some_path/desktop_messages.txt"

    // Shared text styling
    lazy var textAttributes: [NSAttributedString.Key: Any] = {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left

        return [
            .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .light),
            .foregroundColor: NSColor.black.withAlphaComponent(0.7),
            .kern: 1.8,
            .paragraphStyle: paragraphStyle
        ]
    }()

    func applicationDidFinishLaunching(_ notification: Notification) {
        loadMessages()

        let windowWidth: CGFloat = 800
        let windowHeight: CGFloat = 60

        let x: CGFloat = 33
        let y: CGFloat = 33

        window = OverlayPanel(
            contentRect: NSRect(x: x, y: y, width: windowWidth, height: windowHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .normal
        window.ignoresMouseEvents = true
        window.collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .ignoresCycle
        ]

        let contentView = NSView(frame: window.contentRect(forFrameRect: window.frame))
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.clear.cgColor

        textField = NSTextField(labelWithString: "")
        textField.frame = NSRect(
            x: 20,               // padding from left
            y: contentView.bounds.height - 25, // near top
            width: contentView.bounds.width - 40,
            height: 25
        )
        textField.backgroundColor = .clear
        textField.isBordered = false
        textField.isEditable = false
        textField.isSelectable = false
        textField.lineBreakMode = .byTruncatingTail
        textField.usesSingleLineMode = true
        textField.autoresizingMask = [.width, .minYMargin]

        contentView.addSubview(textField)
        window.contentView = contentView
        window.orderFrontRegardless()

        updateDisplayedText()

        // Reload file every minute so you can edit the txt file without recompiling
        reloadTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.reloadMessagesPreservingCurrentText()
        }

        // Rotate message every hour
        rotateTimer = Timer.scheduledTimer(withTimeInterval: 3600.0, repeats: true) { [weak self] _ in
            self?.advanceMessage()
        }
    }

    func loadMessages() {
        guard let contents = try? String(contentsOfFile: messagesPath, encoding: .utf8) else {
            messages = ["hello"]
            currentIndex = 0
            return
        }

        let splitMessages = contents
            .components(separatedBy: "#")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        messages = splitMessages.isEmpty ? ["hello"] : splitMessages

        if currentIndex >= messages.count {
            currentIndex = 0
        }
    }

    func reloadMessagesPreservingCurrentText() {
        let oldCurrentMessage = messages.indices.contains(currentIndex) ? messages[currentIndex] : nil
        loadMessages()

        if let oldCurrentMessage,
           let newIndex = messages.firstIndex(of: oldCurrentMessage) {
            currentIndex = newIndex
        } else if currentIndex >= messages.count {
            currentIndex = 0
        }

        updateDisplayedText()
    }

    func updateDisplayedText() {
        guard !messages.isEmpty else {
            textField.attributedStringValue = NSAttributedString(string: "", attributes: textAttributes)
            return
        }

        textField.attributedStringValue = NSAttributedString(
            string: messages[currentIndex],
            attributes: textAttributes
        )
    }

    func advanceMessage() {
        loadMessages()

        guard !messages.isEmpty else {
            messages = ["hello"]
            currentIndex = 0
            updateDisplayedText()
            return
        }

        currentIndex = (currentIndex + 1) % messages.count
        updateDisplayedText()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
