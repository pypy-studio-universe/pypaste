import AppKit
import PyPasteCore
import PyPasteDomain
import PyPasteFeatures
import PyPasteSharedUI
import QuartzCore
import SwiftUI

@MainActor
final class QuickBarPanelController {
    private weak var model: QuickBarModel?
    private let panel: QuickBarPanel
    private let hostingView: FirstMouseHostingView<QuickBarView>
    private let keyboardMonitor: any QuickBarKeyboardMonitoring
    private let logger: any AppLogging
    private var keyboardFocusTask: Task<Void, Never>?
    private var isDismissing = false

    var isVisible: Bool {
        panel.isVisible
    }

    init(
        model: QuickBarModel,
        keyboardMonitor: any QuickBarKeyboardMonitoring = CarbonQuickBarKeyboardMonitor(),
        logger: any AppLogging = NoOpLogger(),
        localization: AppLocalization = .shared
    ) {
        self.model = model
        hostingView = FirstMouseHostingView(
            rootView: QuickBarView(model: model, localization: localization)
        )
        self.keyboardMonitor = keyboardMonitor
        self.logger = logger
        panel = QuickBarPanel(
            contentRect: .zero,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.keyEventHandler = { [weak model] event in
            guard let model else {
                return false
            }

            return QuickBarKeyboardRouter.handle(event, model: model)
        }

        configurePanel()
        installContentView()
    }

    func show(on screen: NSScreen? = nil) {
        let targetScreen = screen ?? screenUnderPointer() ?? .main

        guard let targetScreen else {
            return
        }

        let finalFrame = makePanelFrame(in: targetScreen.visibleFrame)
        var initialFrame = finalFrame
        initialFrame.origin.y -= 10

        panel.setFrame(initialFrame, display: false)
        panel.alphaValue = 0
        isDismissing = false
        startGlobalKeyboardRouting()
        claimKeyboardFocus()
        reaffirmKeyboardFocusAfterPresentation()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.16
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().setFrame(finalFrame, display: true)
            panel.animator().alphaValue = 1
        }
    }

    func hide() {
        keyboardMonitor.stop()

        guard panel.isVisible else {
            return
        }

        isDismissing = true
        keyboardFocusTask?.cancel()
        keyboardFocusTask = nil
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().alphaValue = 0
        } completionHandler: { [weak panel] in
            Task { @MainActor in
                panel?.orderOut(nil)
                panel?.alphaValue = 1
            }
        }
    }

    func bringToFrontWhileVisible() {
        guard panel.isVisible, !isDismissing else {
            return
        }

        panel.orderFrontRegardless()
    }

    private func configurePanel() {
        panel.title = "PyPaste Quick Bar"
        panel.setAccessibilityLabel("PyPaste Quick Bar")
        panel.identifier = NSUserInterfaceItemIdentifier("PyPasteQuickBar")
        panel.level = .popUpMenu
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = true
        panel.becomesKeyOnlyIfNeeded = false
        panel.worksWhenModal = true
        panel.isMovable = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .ignoresCycle,
        ]
        panel.initialFirstResponder = hostingView
    }

    private func claimKeyboardFocus() {
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        panel.makeFirstResponder(hostingView)
    }

    private func startGlobalKeyboardRouting() {
        do {
            try keyboardMonitor.start { [weak self] command in
                guard let model = self?.model else {
                    return
                }

                _ = QuickBarKeyboardRouter.handle(command, model: model)
            }
        } catch {
            logger.error(
                "Quick Bar global keyboard routing failed: \(error.localizedDescription)"
            )
        }
    }

    private func reaffirmKeyboardFocusAfterPresentation() {
        keyboardFocusTask?.cancel()
        keyboardFocusTask = Task { @MainActor [weak self] in
            for delay in [Duration.zero, .milliseconds(40), .milliseconds(120)] {
                if delay != .zero {
                    try? await Task.sleep(for: delay)
                } else {
                    await Task.yield()
                }

                guard let self, !Task.isCancelled, panel.isVisible else {
                    return
                }

                claimKeyboardFocus()
                if panel.isKeyWindow {
                    return
                }
            }
        }
    }

    var hasKeyboardFocus: Bool {
        panel.isKeyWindow
    }

    var usesActivatingPanel: Bool {
        !panel.styleMask.contains(.nonactivatingPanel)
    }

    var dismissesWhenApplicationDeactivates: Bool {
        panel.hidesOnDeactivate
    }

    var hasGlobalKeyboardRouting: Bool {
        keyboardMonitor.isRegistered
    }

    private func installContentView() {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = .popover
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        visualEffectView.wantsLayer = true
        visualEffectView.layer?.cornerRadius = 18
        visualEffectView.layer?.cornerCurve = .continuous
        visualEffectView.layer?.masksToBounds = true

        let hostedView = hostingView
        hostedView.translatesAutoresizingMaskIntoConstraints = false
        hostedView.wantsLayer = true
        hostedView.layer?.backgroundColor = NSColor.clear.cgColor
        visualEffectView.addSubview(hostedView)

        NSLayoutConstraint.activate([
            hostedView.leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor),
            hostedView.trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor),
            hostedView.topAnchor.constraint(equalTo: visualEffectView.topAnchor),
            hostedView.bottomAnchor.constraint(equalTo: visualEffectView.bottomAnchor),
        ])

        panel.contentView = visualEffectView
    }

    func makePanelFrame(in visibleFrame: NSRect) -> NSRect {
        let width = visibleFrame.width * 0.8
        let height: CGFloat = 276
        let originX = visibleFrame.midX - width / 2
        let originY = visibleFrame.minY + 16

        return NSRect(x: originX, y: originY, width: width, height: height)
    }

    private func screenUnderPointer() -> NSScreen? {
        let pointerLocation = NSEvent.mouseLocation
        return NSScreen.screens.first { NSMouseInRect(pointerLocation, $0.frame, false) }
    }
}

private final class FirstMouseHostingView<Content: View>: NSHostingView<Content> {
    override var acceptsFirstResponder: Bool {
        true
    }

    override func acceptsFirstMouse(for _: NSEvent?) -> Bool {
        true
    }
}

enum QuickBarKeyCode {
    static let returnKey: UInt16 = 36
    static let keypadEnter: UInt16 = 76
    static let escape: UInt16 = 53
    static let leftArrow: UInt16 = 123
    static let rightArrow: UInt16 = 124
}

enum QuickBarKeyboardRouter {
    @MainActor
    static func handle(_ event: NSEvent, model: QuickBarModel) -> Bool {
        if model.isPresentingCollectionDialog {
            guard event.keyCode == QuickBarKeyCode.escape else {
                return false
            }

            return model.dismissCollectionDialog()
        }

        if event.isARepeat,
            event.keyCode == QuickBarKeyCode.leftArrow
                || event.keyCode == QuickBarKeyCode.rightArrow
        {
            return true
        }

        let command: QuickBarKeyboardCommand
        switch event.keyCode {
        case QuickBarKeyCode.leftArrow:
            command = .selectPrevious
        case QuickBarKeyCode.rightArrow:
            command = .selectNext
        case QuickBarKeyCode.returnKey, QuickBarKeyCode.keypadEnter:
            command = .pasteSelected
        case QuickBarKeyCode.escape:
            command = .dismiss
        default:
            return false
        }

        return handle(command, model: model)
    }

    @MainActor
    static func handle(_ command: QuickBarKeyboardCommand, model: QuickBarModel) -> Bool {
        if model.isPresentingCollectionDialog {
            if command == .dismiss {
                model.dismissCollectionDialog()
            }
            return true
        }

        switch command {
        case .selectPrevious:
            model.selectPrevious()
        case .selectNext:
            model.selectNext()
        case .pasteSelected:
            model.pasteSelected()
        case .dismiss:
            model.dismiss()
        }

        return true
    }
}

private final class QuickBarPanel: NSPanel {
    var keyEventHandler: ((NSEvent) -> Bool)?

    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        false
    }

    override func sendEvent(_ event: NSEvent) {
        if event.type == .keyDown, keyEventHandler?(event) == true {
            return
        }

        super.sendEvent(event)
    }
}
