import AppKit
import Foundation
import PyPasteCore
import PyPasteData
import PyPasteDomain
import PyPasteFeatures
import PyPasteSharedUI
import XCTest

@testable import PyPaste

final class FoundationTests: XCTestCase {
    func testHostedUnitTestDoesNotStartProductionLifecycle() {
        let context = AppLaunchContext(
            arguments: ["PyPaste"],
            environment: [
                "XCTestBundlePath": "Contents/PlugIns/PyPasteTests.xctest",
                "XCInjectBundleInto": "unused",
            ]
        )

        XCTAssertTrue(context.isHostedUnitTest)
        XCTAssertFalse(context.isUITesting)
    }

    func testUITestLaunchTakesPrecedenceOverHostedTestEnvironment() {
        let context = AppLaunchContext(
            arguments: ["PyPaste", "--ui-testing"],
            environment: [
                "XCTestBundlePath": "Contents/PlugIns/PyPasteTests.xctest",
                "XCInjectBundleInto": "unused",
            ]
        )

        XCTAssertFalse(context.isHostedUnitTest)
        XCTAssertTrue(context.isUITesting)
    }

    func testDependencyContainerMigratesToLatestSchema() async throws {
        let databaseURL = temporaryDatabaseURL()
        defer { try? FileManager.default.removeItem(at: databaseURL.deletingLastPathComponent()) }

        let container = DependencyContainer.testing(databaseURL: databaseURL)

        try await container.databaseMigrator.migrate()
        try await container.databaseMigrator.migrate()

        let version = try await container.databaseMigrator.currentVersion()
        XCTAssertEqual(version, DatabaseSchema.currentVersion)
    }

    @MainActor
    func testStatusMenuAnchorUsesCurrentButtonScreenFrameBottomLeadingCorner() {
        let buttonFrameOnScreen = NSRect(x: 84, y: 1_058, width: 22, height: 22)

        let anchor = StatusItemController.menuAnchor(for: buttonFrameOnScreen)

        XCTAssertEqual(anchor.x, buttonFrameOnScreen.minX)
        XCTAssertEqual(anchor.y, buttonFrameOnScreen.minY)
    }

    @MainActor
    func testStatusMenuProvidesPersistentEnglishAndVietnameseSelector() throws {
        let suiteName = "StatusItemLocalizationTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        let localization = AppLocalization(defaults: defaults)
        let controller = StatusItemController(
            openMainWindow: {},
            showQuickBar: {},
            toggleMonitoring: {},
            terminateApplication: {},
            localization: localization
        )

        let menu = controller.makeMenu()
        let languageItem = try XCTUnwrap(
            menu.items.first(where: { $0.title == "Language" })
        )
        let languageMenu = try XCTUnwrap(languageItem.submenu)

        XCTAssertEqual(languageMenu.items.map(\.title), ["English", "Tiếng Việt"])
        XCTAssertEqual(languageMenu.items.map(\.state), [.on, .off])

        languageMenu.performActionForItem(at: 1)

        XCTAssertEqual(localization.language, .vietnamese)
        XCTAssertEqual(defaults.string(forKey: AppLocalization.defaultsKey), "vi")
    }

    @MainActor
    func testQuickBarArrowAutoRepeatDoesNotSkipAnItem() throws {
        let now = Date()
        let clips = (0..<3).map { index in
            Clip(
                lastUsedAt: now.addingTimeInterval(Double(index)),
                contentKind: .text,
                displayTitle: "clip-\(index)",
                searchableText: "clip-\(index)",
                contentHash: "clip-\(index)"
            )
        }
        let model = QuickBarModel(onPaste: { _ in }, onDismiss: {})
        model.prepareForPresentation(with: clips)

        let initialKeyDown = try XCTUnwrap(makeRightArrowEvent(isRepeat: false))
        let repeatedKeyDown = try XCTUnwrap(makeRightArrowEvent(isRepeat: true))

        XCTAssertTrue(QuickBarKeyboardRouter.handle(initialKeyDown, model: model))
        XCTAssertEqual(model.selectedClipID, model.clips[1].id)

        XCTAssertTrue(QuickBarKeyboardRouter.handle(repeatedKeyDown, model: model))
        XCTAssertEqual(model.selectedClipID, model.clips[1].id)
    }

    @MainActor
    func testQuickBarClaimsKeyboardFocusWhenPresented() async throws {
        let model = QuickBarModel(onPaste: { _ in }, onDismiss: {})
        let controller = QuickBarPanelController(model: model)

        XCTAssertTrue(controller.usesActivatingPanel)
        XCTAssertTrue(controller.dismissesWhenApplicationDeactivates)
        controller.show(on: NSScreen.main)
        try await Task.sleep(for: .milliseconds(200))

        XCTAssertTrue(controller.isVisible)
        XCTAssertTrue(controller.hasKeyboardFocus)
        XCTAssertTrue(controller.hasGlobalKeyboardRouting)
        controller.hide()
    }

    @MainActor
    func testQuickBarWidthIsEightyPercentOfVisibleScreen() {
        let model = QuickBarModel(onPaste: { _ in }, onDismiss: {})
        let controller = QuickBarPanelController(model: model)
        let visibleFrame = NSRect(x: 100, y: 50, width: 1_000, height: 700)

        let panelFrame = controller.makePanelFrame(in: visibleFrame)

        XCTAssertEqual(panelFrame.width, 800, accuracy: 0.001)
        XCTAssertEqual(panelFrame.midX, visibleFrame.midX, accuracy: 0.001)
    }

    @MainActor
    func testQuickBarStopsGlobalKeyboardRoutingWhenDismissed() async throws {
        let keyboardMonitor = FakeQuickBarKeyboardMonitor()
        var controller: QuickBarPanelController?
        let model = QuickBarModel(
            onPaste: { _ in },
            onDismiss: { controller?.hide() }
        )
        controller = QuickBarPanelController(
            model: model,
            keyboardMonitor: keyboardMonitor
        )

        controller?.show(on: NSScreen.main)
        try await Task.sleep(for: .milliseconds(200))

        XCTAssertTrue(controller?.isVisible == true)
        XCTAssertTrue(keyboardMonitor.isRegistered)
        keyboardMonitor.send(.dismiss)
        try await Task.sleep(for: .milliseconds(200))
        XCTAssertFalse(controller?.isVisible == true)
        XCTAssertFalse(keyboardMonitor.isRegistered)
    }

    @MainActor
    func testOnlyEscapeDismissesWhileReturnPastes() throws {
        var pasteCount = 0
        var dismissCount = 0
        let clip = Clip(
            contentKind: .text,
            displayTitle: "Pinned Quick Bar",
            searchableText: "Pinned Quick Bar",
            contentHash: "pinned-quick-bar"
        )
        let model = QuickBarModel(
            onPaste: { _ in pasteCount += 1 },
            onDismiss: { dismissCount += 1 }
        )
        model.prepareForPresentation(with: [clip])

        let returnEvent = try XCTUnwrap(makeKeyEvent(keyCode: QuickBarKeyCode.returnKey))
        XCTAssertTrue(QuickBarKeyboardRouter.handle(returnEvent, model: model))
        XCTAssertEqual(pasteCount, 1)
        XCTAssertEqual(dismissCount, 0)

        model.completePaste()
        let escapeEvent = try XCTUnwrap(makeKeyEvent(keyCode: QuickBarKeyCode.escape))
        XCTAssertTrue(QuickBarKeyboardRouter.handle(escapeEvent, model: model))
        XCTAssertEqual(dismissCount, 1)
    }

    @MainActor
    func testEscapeDismissesCollectionDialogBeforeQuickBar() throws {
        var dismissCount = 0
        var pasteCount = 0
        let model = QuickBarModel(
            onPaste: { _ in pasteCount += 1 },
            onDismiss: { dismissCount += 1 }
        )
        model.prepareForPresentation(
            with: [
                Clip(
                    contentKind: .text,
                    displayTitle: "Modal routing",
                    searchableText: "Modal routing",
                    contentHash: "modal-routing"
                )
            ]
        )
        model.presentCreateCollectionDialog()

        let returnEvent = try XCTUnwrap(makeKeyEvent(keyCode: QuickBarKeyCode.returnKey))
        XCTAssertFalse(QuickBarKeyboardRouter.handle(returnEvent, model: model))
        XCTAssertEqual(pasteCount, 0)

        let escapeEvent = try XCTUnwrap(makeKeyEvent(keyCode: QuickBarKeyCode.escape))
        XCTAssertTrue(QuickBarKeyboardRouter.handle(escapeEvent, model: model))
        XCTAssertFalse(model.isPresentingCollectionDialog)
        XCTAssertEqual(dismissCount, 0)

        XCTAssertTrue(QuickBarKeyboardRouter.handle(escapeEvent, model: model))
        XCTAssertEqual(dismissCount, 1)
    }

    @MainActor
    func testGlobalEscapeDismissesDeleteDialogBeforeQuickBar() {
        var dismissCount = 0
        let collection = ClipCollection(
            name: "Useful Links",
            colorHex: "#FF453A",
            sortOrder: 10
        )
        let model = QuickBarModel(
            onPaste: { _ in },
            onDismiss: { dismissCount += 1 }
        )
        model.presentDeleteCollectionDialog(for: collection)

        XCTAssertTrue(QuickBarKeyboardRouter.handle(.pasteSelected, model: model))
        XCTAssertTrue(model.isPresentingCollectionDialog)
        XCTAssertEqual(dismissCount, 0)

        XCTAssertTrue(QuickBarKeyboardRouter.handle(.dismiss, model: model))
        XCTAssertFalse(model.isPresentingCollectionDialog)
        XCTAssertEqual(dismissCount, 0)

        XCTAssertTrue(QuickBarKeyboardRouter.handle(.dismiss, model: model))
        XCTAssertEqual(dismissCount, 1)
    }

    private func temporaryDatabaseURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("PyPaste.sqlite")
    }

    private func makeRightArrowEvent(isRepeat: Bool) -> NSEvent? {
        makeKeyEvent(keyCode: QuickBarKeyCode.rightArrow, isRepeat: isRepeat)
    }

    private func makeKeyEvent(keyCode: UInt16, isRepeat: Bool = false) -> NSEvent? {
        NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: "",
            charactersIgnoringModifiers: "",
            isARepeat: isRepeat,
            keyCode: keyCode
        )
    }
}

@MainActor
private final class FakeQuickBarKeyboardMonitor: QuickBarKeyboardMonitoring {
    private(set) var isRegistered = false
    private var onCommand: (@MainActor (QuickBarKeyboardCommand) -> Void)?

    func start(
        onCommand: @escaping @MainActor (QuickBarKeyboardCommand) -> Void
    ) throws {
        self.onCommand = onCommand
        isRegistered = true
    }

    func stop() {
        onCommand = nil
        isRegistered = false
    }

    func send(_ command: QuickBarKeyboardCommand) {
        onCommand?(command)
    }
}
