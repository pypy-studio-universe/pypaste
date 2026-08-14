import AppKit
import XCTest

final class PyPasteUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testMainWindowOpensForUITesting() throws {
        let application = XCUIApplication()
        application.launchArguments = ["--ui-testing"]
        application.launch()

        let mainWindow = application.windows["PyPaste"]
        XCTAssertTrue(mainWindow.waitForExistence(timeout: 5))
        XCTAssertTrue(application.staticTexts["Clipboard History"].exists)
    }

    @MainActor
    func testMenuBarItemOpensMainWindow() throws {
        let application = XCUIApplication()
        application.launchArguments = ["--ui-testing"]
        application.launch()

        let mainWindow = application.windows["PyPaste"]
        XCTAssertTrue(mainWindow.waitForExistence(timeout: 5))
        application.typeKey("w", modifierFlags: [.command])
        XCTAssertTrue(mainWindow.waitForNonExistence(timeout: 2))

        let statusItem = application.statusItems["PyPaste menu"]
        XCTAssertTrue(statusItem.waitForExistence(timeout: 5))
        statusItem.click()

        let openMenuItem = application.menuItems["Open PyPaste"]
        XCTAssertTrue(openMenuItem.waitForExistence(timeout: 2))
        openMenuItem.click()

        XCTAssertTrue(mainWindow.waitForExistence(timeout: 5))
    }

    @MainActor
    func testClipboardCaptureAppearsAndRecopyDoesNotDuplicate() throws {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("com.pypaste.ui-tests"))
        pasteboard.clearContents()
        let application = XCUIApplication()
        application.launchArguments = ["--ui-testing"]
        application.launch()

        XCTAssertTrue(application.windows["PyPaste"].waitForExistence(timeout: 5))
        Thread.sleep(forTimeInterval: 0.5)

        let text = "Epic 2 UI capture"
        pasteboard.clearContents()
        XCTAssertTrue(pasteboard.setString(text, forType: .string))
        XCTAssertTrue(application.staticTexts[text].waitForExistence(timeout: 2))
        XCTAssertTrue(application.staticTexts["All Clips (1)"].exists)

        let copyButton = application.buttons["Copy \(text)"]
        XCTAssertTrue(copyButton.waitForExistence(timeout: 2))
        copyButton.click()
        Thread.sleep(forTimeInterval: 0.75)

        XCTAssertTrue(application.staticTexts["All Clips (1)"].exists)
    }

    @MainActor
    func testCommandShiftVShowsBottomQuickBarWithCapturedClip() throws {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("com.pypaste.ui-tests"))
        pasteboard.clearContents()
        let application = XCUIApplication()
        application.launchArguments = ["--ui-testing"]
        application.launch()

        XCTAssertTrue(application.windows["PyPaste"].waitForExistence(timeout: 5))
        Thread.sleep(forTimeInterval: 0.5)

        let text = "Quick Bar UI capture"
        pasteboard.clearContents()
        XCTAssertTrue(pasteboard.setString(text, forType: .string))
        XCTAssertTrue(application.staticTexts[text].waitForExistence(timeout: 2))

        application.typeKey("v", modifierFlags: [.command, .shift])

        let quickBar = application.dialogs["PyPaste Quick Bar"]
        XCTAssertTrue(quickBar.waitForExistence(timeout: 3))
        XCTAssertTrue(quickBar.staticTexts["Clipboard"].exists)
        XCTAssertTrue(quickBar.staticTexts["⌘⇧V"].exists)
        let pasteButton = quickBar.buttons["Paste \(text)"]
        XCTAssertTrue(pasteButton.waitForExistence(timeout: 2))

        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "Command-Shift-V Quick Bar"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        let changeCountBeforeClick = pasteboard.changeCount
        pasteButton.click()

        let clipboardContainsSelectedClip = NSPredicate { _, _ in
            pasteboard.changeCount > changeCountBeforeClick
                && pasteboard.string(forType: .string) == text
        }
        expectation(for: clipboardContainsSelectedClip, evaluatedWith: pasteboard)
        waitForExpectations(timeout: 2)

        XCTAssertEqual(pasteboard.string(forType: .string), text)
    }

    @MainActor
    func testQuickBarSmartPreviewsKeyboardNavigationAndEscape() throws {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("com.pypaste.ui-tests"))
        pasteboard.clearContents()
        let application = XCUIApplication()
        application.launchArguments = ["--ui-testing"]
        application.launch()

        XCTAssertTrue(application.windows["PyPaste"].waitForExistence(timeout: 5))
        Thread.sleep(forTimeInterval: 0.5)

        let runID = UUID().uuidString
        let layoutFillers = (0..<4).map { "layout-\(runID)-filler-\($0)" }
        for filler in layoutFillers {
            capture(filler, pasteboard: pasteboard, application: application)
        }

        let colorCode = "#\(runID.prefix(6))"
        let canonicalColorCode = colorCode.uppercased()
        capture(
            colorCode,
            displayedAs: canonicalColorCode,
            pasteboard: pasteboard,
            application: application
        )

        let oneStepTarget = "one-step navigation target \(runID)"
        capture(oneStepTarget, pasteboard: pasteboard, application: application)

        let link = "https://www.example.com/docs/start?run=\(runID)"
        capture(link, displayedAs: "example.com", pasteboard: pasteboard, application: application)

        let quickBar = openQuickBarFromStatusItem(in: application)
        assertCardsFitInsideQuickBar(
            quickBar,
            firstTitle: "example.com",
            lastTitle: layoutFillers[1]
        )

        application.typeKey(XCUIKeyboardKey.rightArrow, modifierFlags: [])
        XCTAssertEqual(
            quickBar.buttons["Paste \(oneStepTarget)"].value as? String,
            "Selected"
        )

        let changeCountBeforePaste = pasteboard.changeCount
        application.typeKey(XCUIKeyboardKey.return, modifierFlags: [])
        let selectedClipWasWritten = NSPredicate { _, _ in
            pasteboard.changeCount > changeCountBeforePaste
        }
        expectation(for: selectedClipWasWritten, evaluatedWith: pasteboard)
        waitForExpectations(timeout: 2)
        XCTAssertEqual(pasteboard.string(forType: .string), oneStepTarget)

        assertKeyboardFocusRemainsAfterPaste(
            in: quickBar,
            nextClipTitle: canonicalColorCode,
            application: application
        )

        application.typeKey(XCUIKeyboardKey.escape, modifierFlags: [])
        XCTAssertTrue(quickBar.waitForNonExistence(timeout: 2))
    }

    @MainActor
    func testPinnedQuickBarCloseButtonDismissesPopup() {
        let application = XCUIApplication()
        application.launchArguments = ["--ui-testing"]
        application.launch()

        XCTAssertTrue(application.windows["PyPaste"].waitForExistence(timeout: 5))
        let quickBar = openQuickBarFromStatusItem(in: application)
        let closeButton = quickBar.buttons["Close Quick Bar"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 2))
        closeButton.click()

        XCTAssertTrue(quickBar.waitForNonExistence(timeout: 2))
    }

    @MainActor
    func testQuickBarPastePreservesOrderAfterReopen() throws {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("com.pypaste.ui-tests"))
        pasteboard.clearContents()
        let application = XCUIApplication()
        application.launchArguments = ["--ui-testing"]
        application.launch()

        XCTAssertTrue(application.windows["PyPaste"].waitForExistence(timeout: 5))
        Thread.sleep(forTimeInterval: 0.5)

        let runID = UUID().uuidString
        let olderText = "older order item \(runID)"
        let newerText = "newer order item \(runID)"
        capture(olderText, pasteboard: pasteboard, application: application)
        capture(newerText, pasteboard: pasteboard, application: application)

        var quickBar = openQuickBarFromStatusItem(in: application)
        let olderButton = quickBar.buttons["Paste \(olderText)"]
        let newerButton = quickBar.buttons["Paste \(newerText)"]
        XCTAssertTrue(olderButton.waitForExistence(timeout: 2))
        XCTAssertTrue(newerButton.waitForExistence(timeout: 2))
        XCTAssertLessThan(newerButton.frame.minX, olderButton.frame.minX)

        let changeCountBeforePaste = pasteboard.changeCount
        olderButton.click()
        let selectedClipWasWritten = NSPredicate { _, _ in
            pasteboard.changeCount > changeCountBeforePaste
        }
        expectation(for: selectedClipWasWritten, evaluatedWith: pasteboard)
        waitForExpectations(timeout: 2)
        Thread.sleep(forTimeInterval: 0.25)
        XCTAssertLessThan(newerButton.frame.minX, olderButton.frame.minX)

        application.typeKey(XCUIKeyboardKey.escape, modifierFlags: [])
        XCTAssertTrue(quickBar.waitForNonExistence(timeout: 2))

        quickBar = openQuickBarFromStatusItem(in: application)
        let reloadedOlderButton = quickBar.buttons["Paste \(olderText)"]
        let reloadedNewerButton = quickBar.buttons["Paste \(newerText)"]
        XCTAssertTrue(reloadedOlderButton.waitForExistence(timeout: 2))
        XCTAssertTrue(reloadedNewerButton.waitForExistence(timeout: 2))
        XCTAssertLessThan(reloadedNewerButton.frame.minX, reloadedOlderButton.frame.minX)
    }

    @MainActor
    func testQuickBarDeleteDoesNotPasteAndPersistsAfterReopen() throws {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("com.pypaste.ui-tests"))
        pasteboard.clearContents()
        let application = XCUIApplication()
        application.launchArguments = ["--ui-testing"]
        application.launch()

        XCTAssertTrue(application.windows["PyPaste"].waitForExistence(timeout: 5))
        Thread.sleep(forTimeInterval: 0.5)

        let runID = UUID().uuidString
        let retainedText = "retained item \(runID)"
        let deletedText = "deleted item \(runID)"
        capture(retainedText, pasteboard: pasteboard, application: application)
        capture(deletedText, pasteboard: pasteboard, application: application)

        var quickBar = openQuickBarFromStatusItem(in: application)
        let deleteButton = quickBar.buttons["Delete \(deletedText)"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 2))
        let changeCountBeforeDelete = pasteboard.changeCount

        deleteButton.click()

        XCTAssertTrue(
            quickBar.buttons["Paste \(deletedText)"].waitForNonExistence(timeout: 2)
        )
        XCTAssertTrue(quickBar.buttons["Paste \(retainedText)"].exists)
        XCTAssertEqual(pasteboard.changeCount, changeCountBeforeDelete)

        application.typeKey(XCUIKeyboardKey.escape, modifierFlags: [])
        XCTAssertTrue(quickBar.waitForNonExistence(timeout: 2))

        quickBar = openQuickBarFromStatusItem(in: application)
        XCTAssertFalse(quickBar.buttons["Paste \(deletedText)"].exists)
        XCTAssertTrue(quickBar.buttons["Paste \(retainedText)"].exists)
    }
}

extension PyPasteUITests {
    @MainActor
    // swiftlint:disable:next function_body_length
    func testQuickBarDragReordersAtPreviewedEdgeAndPersistsAfterReopen() throws {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("com.pypaste.ui-tests"))
        pasteboard.clearContents()
        let application = XCUIApplication()
        application.launchArguments = ["--ui-testing"]
        application.launch()

        XCTAssertTrue(application.windows["PyPaste"].waitForExistence(timeout: 5))
        Thread.sleep(forTimeInterval: 0.5)

        let runID = UUID().uuidString
        let oldestText = "drag oldest \(runID)"
        let middleText = "drag middle \(runID)"
        let newestText = "drag newest \(runID)"
        capture(oldestText, pasteboard: pasteboard, application: application)
        capture(middleText, pasteboard: pasteboard, application: application)
        capture(newestText, pasteboard: pasteboard, application: application)

        var quickBar = openQuickBarFromStatusItem(in: application)
        var sourceCard = quickBar.buttons["Paste \(oldestText)"]
        var targetCard = quickBar.buttons["Paste \(newestText)"]
        var middleCard = quickBar.buttons["Paste \(middleText)"]
        XCTAssertTrue(sourceCard.waitForExistence(timeout: 2))
        XCTAssertTrue(targetCard.waitForExistence(timeout: 2))
        XCTAssertTrue(middleCard.waitForExistence(timeout: 2))
        XCTAssertGreaterThan(sourceCard.frame.minX, targetCard.frame.minX)
        let changeCountBeforeDrag = pasteboard.changeCount

        let sourceCoordinate = sourceCard.coordinate(
            withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)
        )
        let targetLeadingCoordinate = targetCard.coordinate(
            withNormalizedOffset: CGVector(dx: 0.2, dy: 0.5)
        )
        sourceCoordinate.press(
            forDuration: 0.5,
            thenDragTo: targetLeadingCoordinate
        )

        let cardsWereReordered = NSPredicate { _, _ in
            sourceCard.frame.minX < targetCard.frame.minX
                && targetCard.frame.minX < middleCard.frame.minX
        }
        expectation(for: cardsWereReordered, evaluatedWith: quickBar)
        waitForExpectations(timeout: 3)
        XCTAssertEqual(pasteboard.changeCount, changeCountBeforeDrag)
        attachScreenshot(named: "Quick Bar Drag Reorder Result")

        application.typeKey(XCUIKeyboardKey.escape, modifierFlags: [])
        XCTAssertTrue(quickBar.waitForNonExistence(timeout: 2))
        Thread.sleep(forTimeInterval: 0.5)

        quickBar = openQuickBarFromStatusItem(in: application)
        sourceCard = quickBar.buttons["Paste \(oldestText)"]
        targetCard = quickBar.buttons["Paste \(newestText)"]
        middleCard = quickBar.buttons["Paste \(middleText)"]
        XCTAssertTrue(sourceCard.waitForExistence(timeout: 2))
        XCTAssertTrue(targetCard.waitForExistence(timeout: 2))
        XCTAssertTrue(middleCard.waitForExistence(timeout: 2))
        XCTAssertLessThan(sourceCard.frame.minX, targetCard.frame.minX)
        XCTAssertLessThan(targetCard.frame.minX, middleCard.frame.minX)
    }
}

extension PyPasteUITests {
    @MainActor
    func capture(
        _ text: String,
        displayedAs displayText: String? = nil,
        pasteboard: NSPasteboard,
        application: XCUIApplication
    ) {
        pasteboard.clearContents()
        XCTAssertTrue(pasteboard.setString(text, forType: .string))
        XCTAssertTrue(application.staticTexts[displayText ?? text].waitForExistence(timeout: 2))
    }

    @MainActor
    func openQuickBarFromStatusItem(in application: XCUIApplication) -> XCUIElement {
        let statusItem = application.statusItems["PyPaste menu"]
        XCTAssertTrue(statusItem.waitForExistence(timeout: 2))
        statusItem.click()

        let showQuickBarItem = application.menuItems["Show Quick Bar (⌘⇧V)"]
        XCTAssertTrue(showQuickBarItem.waitForExistence(timeout: 2))
        showQuickBarItem.click()

        let quickBar = application.dialogs["PyPaste Quick Bar"]
        XCTAssertTrue(quickBar.waitForExistence(timeout: 3))
        return quickBar
    }

    @MainActor
    private func assertKeyboardFocusRemainsAfterPaste(
        in quickBar: XCUIElement,
        nextClipTitle: String,
        application: XCUIApplication
    ) {
        XCTAssertTrue(quickBar.exists)
        application.typeKey(XCUIKeyboardKey.rightArrow, modifierFlags: [])
        XCTAssertEqual(quickBar.buttons["Paste \(nextClipTitle)"].value as? String, "Selected")
    }

    @MainActor
    private func assertCardsFitInsideQuickBar(
        _ quickBar: XCUIElement,
        firstTitle: String,
        lastTitle: String
    ) {
        let firstCard = quickBar.buttons["Paste \(firstTitle)"]
        let lastCard = quickBar.buttons["Paste \(lastTitle)"]
        XCTAssertTrue(lastCard.exists)
        XCTAssertGreaterThanOrEqual(firstCard.frame.minX, quickBar.frame.minX + 12)
        XCTAssertLessThanOrEqual(lastCard.frame.maxX, quickBar.frame.maxX - 12)
        XCTAssertEqual(firstCard.frame.width, lastCard.frame.width, accuracy: 1)
    }

    @MainActor
    func attachScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
