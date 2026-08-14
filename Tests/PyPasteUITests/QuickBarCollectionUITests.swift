import AppKit
import XCTest

extension PyPasteUITests {
    @MainActor
    func testQuickBarCenteredSearchAndPermanentCollectionWorkflow() throws {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("com.pypaste.ui-tests"))
        pasteboard.clearContents()
        let application = XCUIApplication()
        application.launchArguments = ["--ui-testing"]
        application.launch()

        XCTAssertTrue(application.windows["PyPaste"].waitForExistence(timeout: 5))
        Thread.sleep(forTimeInterval: 0.5)

        let text = "permanent collection \(UUID().uuidString)"
        capture(text, pasteboard: pasteboard, application: application)
        var quickBar = openQuickBarFromStatusItem(in: application)
        let searchField = quickBar.textFields["quickBarSearchField"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 2))
        XCTAssertEqual(searchField.frame.midX, quickBar.frame.midX, accuracy: 2)

        let addButton = quickBar.buttons.matching(
            NSPredicate(format: "label == %@", "Add \(text) to collection")
        ).firstMatch
        XCTAssertTrue(addButton.waitForExistence(timeout: 2))
        addButton.click()
        let usefulLinksMenuItem = application.menuItems["Useful Links"]
        XCTAssertTrue(usefulLinksMenuItem.waitForExistence(timeout: 2))
        usefulLinksMenuItem.click()
        XCTAssertTrue(
            quickBar.staticTexts["Saved permanently to collection"].waitForExistence(timeout: 3))

        let usefulLinksTab = quickBar.buttons["Open Useful Links collection"]
        XCTAssertTrue(usefulLinksTab.waitForExistence(timeout: 2))
        usefulLinksTab.click()
        XCTAssertTrue(quickBar.buttons["Paste \(text)"].waitForExistence(timeout: 3))

        application.typeKey(XCUIKeyboardKey.escape, modifierFlags: [])
        XCTAssertTrue(quickBar.waitForNonExistence(timeout: 2))
        quickBar = openQuickBarFromStatusItem(in: application)
        XCTAssertEqual(
            quickBar.buttons["Open Clipboard collection"].value as? String,
            "Selected"
        )
        quickBar.buttons["Open Useful Links collection"].click()
        XCTAssertTrue(quickBar.buttons["Paste \(text)"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testCollectionDeleteAppearsOnHoverAndRequiresConfirmation() throws {
        let application = XCUIApplication()
        application.launchArguments = ["--ui-testing"]
        application.launch()
        XCTAssertTrue(application.windows["PyPaste"].waitForExistence(timeout: 5))

        let quickBar = openQuickBarFromStatusItem(in: application)
        let collectionName = "Useful Links"
        let collectionTab = quickBar.buttons["Open \(collectionName) collection"]
        XCTAssertTrue(collectionTab.waitForExistence(timeout: 2))
        collectionTab.hover()
        let deleteButton = quickBar.buttons["Delete \(collectionName) collection"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 2))
        deleteButton.click()

        let confirmation = quickBar.otherElements["collectionDialog"]
        XCTAssertTrue(confirmation.waitForExistence(timeout: 1))
        XCTAssertTrue(
            confirmation.staticTexts[
                "Delete \"\(collectionName)\"? Its items will remain available in Clipboard."
            ].exists
        )
        confirmation.buttons["Cancel"].click()
        XCTAssertTrue(collectionTab.exists)

        collectionTab.hover()
        quickBar.buttons["Delete \(collectionName) collection"].click()
        quickBar.otherElements["collectionDialog"].buttons["Delete"].click()

        XCTAssertTrue(collectionTab.waitForNonExistence(timeout: 3))
        XCTAssertEqual(
            quickBar.buttons["Open Clipboard collection"].value as? String,
            "Selected"
        )
    }

    @MainActor
    func testEscapeClosesCollectionDialogsBeforeQuickBar() throws {
        let application = XCUIApplication()
        application.launchArguments = ["--ui-testing"]
        application.launch()
        XCTAssertTrue(application.windows["PyPaste"].waitForExistence(timeout: 5))

        var quickBar = openQuickBarFromStatusItem(in: application)
        quickBar.buttons["Create collection"].click()
        let createAlert = quickBar.otherElements["collectionDialog"]
        XCTAssertTrue(createAlert.waitForExistence(timeout: 1))
        application.typeKey(XCUIKeyboardKey.escape, modifierFlags: [])
        XCTAssertTrue(createAlert.waitForNonExistence(timeout: 2))
        XCTAssertTrue(quickBar.exists)
        application.typeKey(XCUIKeyboardKey.escape, modifierFlags: [])
        XCTAssertTrue(quickBar.waitForNonExistence(timeout: 2))

        quickBar = openQuickBarFromStatusItem(in: application)
        let collectionName = "Important Notes"
        let collectionTab = quickBar.buttons["Open \(collectionName) collection"]
        collectionTab.hover()
        quickBar.buttons["Delete \(collectionName) collection"].click()
        let deleteAlert = quickBar.otherElements["collectionDialog"]
        XCTAssertTrue(deleteAlert.waitForExistence(timeout: 1))
        application.typeKey(XCUIKeyboardKey.escape, modifierFlags: [])
        XCTAssertTrue(deleteAlert.waitForNonExistence(timeout: 2))
        XCTAssertTrue(quickBar.exists)
        application.typeKey(XCUIKeyboardKey.escape, modifierFlags: [])
        XCTAssertTrue(quickBar.waitForNonExistence(timeout: 2))
    }
}
