import AppKit
import XCTest

extension PyPasteUITests {
    @MainActor
    func testQuickBarDismissesWhenFinderIsFocused() {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("com.pypaste.ui-tests"))
        pasteboard.clearContents()
        let application = XCUIApplication()
        application.launchArguments = ["--ui-testing"]
        application.launch()
        XCTAssertTrue(application.windows["PyPaste"].waitForExistence(timeout: 5))

        let oldest = "global-key-oldest-\(UUID().uuidString)"
        let newest = "global-key-newest-\(UUID().uuidString)"
        capture(oldest, pasteboard: pasteboard, application: application)
        capture(newest, pasteboard: pasteboard, application: application)
        let quickBar = openQuickBarFromStatusItem(in: application)

        let finder = XCUIApplication(bundleIdentifier: "com.apple.finder")
        finder.activate()
        XCTAssertTrue(finder.wait(for: .runningForeground, timeout: 3))
        XCTAssertTrue(quickBar.waitForNonExistence(timeout: 2))
    }
}
