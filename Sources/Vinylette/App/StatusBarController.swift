import AppKit

/// Menu bar item (♫) with show/hide and quit actions.
final class StatusBarController: NSObject {
    private let statusItem: NSStatusItem
    private let onToggle: () -> Void
    private let onQuit: () -> Void

    init(onToggle: @escaping () -> Void, onQuit: @escaping () -> Void) {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.onToggle = onToggle
        self.onQuit = onQuit
        super.init()

        statusItem.button?.title = "♫"
        let menu = NSMenu()
        menu.addItem(withTitle: "Vinylette anzeigen/verstecken",
                     action: #selector(toggle), keyEquivalent: "v")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Beenden", action: #selector(quit), keyEquivalent: "q")
        menu.items.forEach { $0.target = self }
        statusItem.menu = menu
    }

    @objc private func toggle() { onToggle() }
    @objc private func quit() { onQuit() }
}
