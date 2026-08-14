import AppKit
import PyPasteSharedUI

@MainActor
final class StatusItemController: NSObject {
    private let openMainWindow: () -> Void
    private let showQuickBar: () -> Void
    private let toggleMonitoring: () -> Void
    private let terminateApplication: () -> Void
    private let localization: AppLocalization
    private var statusItem: NSStatusItem?
    private var statusMenu: NSMenu?
    private var monitoringItem: NSMenuItem?
    private var languageItems: [AppLanguage: NSMenuItem] = [:]
    private var isMonitoringPaused = false
    private var isPresentingStatusMenu = false

    init(
        openMainWindow: @escaping () -> Void,
        showQuickBar: @escaping () -> Void,
        toggleMonitoring: @escaping () -> Void,
        terminateApplication: @escaping () -> Void,
        localization: AppLocalization = .shared
    ) {
        self.openMainWindow = openMainWindow
        self.showQuickBar = showQuickBar
        self.toggleMonitoring = toggleMonitoring
        self.terminateApplication = terminateApplication
        self.localization = localization
    }

    func start() {
        guard statusItem == nil else {
            return
        }

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            button.image = makeMenuBarIcon()
            button.imageScaling = .scaleProportionallyUpOrDown
            button.toolTip = "PyPaste"
            button.setAccessibilityLabel(localization.text(.pyPasteMenu))
            button.target = self
            button.action = #selector(showStatusMenu(_:))
        }
        statusMenu = makeMenu()
        item.isVisible = true
        statusItem = item
    }

    func setMonitoringPaused(_ isPaused: Bool) {
        isMonitoringPaused = isPaused
        monitoringItem?.title = localization.text(
            isPaused ? .resumeMonitoring : .pauseMonitoring
        )
        monitoringItem?.image = NSImage(
            systemSymbolName: isPaused ? "play.fill" : "pause.fill",
            accessibilityDescription: nil
        )
    }

    func makeMenu() -> NSMenu {
        let menu = NSMenu(title: "PyPaste")

        let openItem = NSMenuItem(
            title: localization.text(.openPyPaste),
            action: #selector(openMainWindowAction),
            keyEquivalent: "o"
        )
        openItem.keyEquivalentModifierMask = [.command]
        openItem.target = self
        menu.addItem(openItem)

        let quickBarItem = NSMenuItem(
            title: localization.text(.showQuickBar),
            action: #selector(showQuickBarAction),
            keyEquivalent: ""
        )
        quickBarItem.target = self
        menu.addItem(quickBarItem)

        let monitoringItem = NSMenuItem(
            title: localization.text(.pauseMonitoring),
            action: #selector(toggleMonitoringAction),
            keyEquivalent: ""
        )
        monitoringItem.image = NSImage(
            systemSymbolName: "pause.fill",
            accessibilityDescription: nil
        )
        monitoringItem.target = self
        menu.addItem(monitoringItem)
        self.monitoringItem = monitoringItem

        menu.addItem(makeLanguageItem())

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: localization.text(.quitPyPaste),
            action: #selector(terminateApplicationAction),
            keyEquivalent: "q"
        )
        quitItem.keyEquivalentModifierMask = [.command]
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    private func makeLanguageItem() -> NSMenuItem {
        let languageItem = NSMenuItem(
            title: localization.text(.language),
            action: nil,
            keyEquivalent: ""
        )
        languageItem.image = NSImage(
            systemSymbolName: "globe",
            accessibilityDescription: nil
        )
        let languageMenu = NSMenu(title: localization.text(.language))
        for language in AppLanguage.allCases {
            let item = NSMenuItem(
                title: language.displayName,
                action: #selector(selectLanguage(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = language.rawValue
            item.state = localization.language == language ? .on : .off
            languageMenu.addItem(item)
            languageItems[language] = item
        }
        languageItem.submenu = languageMenu
        return languageItem
    }

    private func makeMenuBarIcon() -> NSImage? {
        let image =
            NSImage(named: "MenuBarIcon")
            ?? NSImage(
                systemSymbolName: "doc.on.clipboard",
                accessibilityDescription: "PyPaste"
            )
        image?.isTemplate = true
        image?.size = NSSize(width: 18, height: 18)
        image?.accessibilityDescription = "PyPaste"
        return image
    }

    static func menuAnchor(for buttonFrameOnScreen: NSRect) -> NSPoint {
        NSPoint(x: buttonFrameOnScreen.minX, y: buttonFrameOnScreen.minY)
    }

    @objc
    private func showStatusMenu(_ sender: NSStatusBarButton) {
        guard
            let statusMenu,
            let buttonWindow = sender.window,
            !isPresentingStatusMenu
        else {
            return
        }

        let buttonFrameInWindow = sender.convert(sender.bounds, to: nil)
        let buttonFrameOnScreen = buttonWindow.convertToScreen(buttonFrameInWindow)
        isPresentingStatusMenu = true
        sender.highlight(true)
        defer {
            sender.highlight(false)
            isPresentingStatusMenu = false
        }

        statusMenu.popUp(
            positioning: nil,
            at: Self.menuAnchor(for: buttonFrameOnScreen),
            in: nil
        )
    }

    @objc
    private func openMainWindowAction() {
        openMainWindow()
    }

    @objc
    private func showQuickBarAction() {
        showQuickBar()
    }

    @objc
    private func toggleMonitoringAction() {
        toggleMonitoring()
    }

    @objc
    private func selectLanguage(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
            let language = AppLanguage(rawValue: rawValue)
        else {
            return
        }

        localization.select(language)
        languageItems.forEach { itemLanguage, item in
            item.state = itemLanguage == language ? .on : .off
        }
        statusMenu = makeMenu()
        setMonitoringPaused(isMonitoringPaused)
        statusItem?.button?.setAccessibilityLabel(localization.text(.pyPasteMenu))
    }

    @objc
    private func terminateApplicationAction() {
        terminateApplication()
    }
}
