import AppKit
import XCTest

extension PyPasteUITests {
    @MainActor
    func testQuickBarSearchFiltersByContentAndClearingRestoresHistory() throws {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("com.pypaste.ui-tests"))
        pasteboard.clearContents()
        let application = XCUIApplication()
        application.launchArguments = ["--ui-testing"]
        application.launch()

        XCTAssertTrue(application.windows["PyPaste"].waitForExistence(timeout: 5))
        Thread.sleep(forTimeInterval: 0.5)

        let runID = UUID().uuidString
        let matchingText = "invoice phoenix \(runID)"
        let otherText = "meeting atlas \(runID)"
        capture(matchingText, pasteboard: pasteboard, application: application)
        capture(otherText, pasteboard: pasteboard, application: application)

        let quickBar = openQuickBarFromStatusItem(in: application)
        let searchField = quickBar.textFields["quickBarSearchField"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 2))
        searchField.click()
        searchField.typeText("phoenix")

        XCTAssertTrue(quickBar.buttons["Paste \(matchingText)"].waitForExistence(timeout: 2))
        XCTAssertFalse(quickBar.buttons["Paste \(otherText)"].exists)

        searchField.typeKey("a", modifierFlags: [.command])
        searchField.typeKey(XCUIKeyboardKey.delete, modifierFlags: [])

        XCTAssertTrue(quickBar.buttons["Paste \(otherText)"].waitForExistence(timeout: 2))
    }
}
