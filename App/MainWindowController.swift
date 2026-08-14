import AppKit
import PyPasteFeatures
import PyPasteSharedUI
import SwiftUI

@MainActor
final class MainWindowController {
    private let windowController: NSWindowController

    init(model: MainHistoryModel, localization: AppLocalization = .shared) {
        let rootView = MainHistoryView(model: model, localization: localization)
        let hostingController = NSHostingController(rootView: rootView)
        let window = NSWindow(contentViewController: hostingController)

        window.title = "PyPaste"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(NSSize(width: 920, height: 620))
        window.minSize = NSSize(width: 760, height: 500)
        window.center()
        window.isReleasedWhenClosed = false
        window.setFrameAutosaveName("PyPasteMainWindow")

        windowController = NSWindowController(window: window)
    }

    func showWindow() {
        guard let window = windowController.window else {
            return
        }

        windowController.showWindow(nil)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
