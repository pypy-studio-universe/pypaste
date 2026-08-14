import PyPasteDomain
import XCTest

@testable import PyPasteCore

final class SystemWorkspaceMonitorTests: XCTestCase {
    func testPyPasteActivationPreservesMostRecentExternalApplication() {
        var tracker = FrontmostApplicationTracker(ignoredProcessIdentifier: 42)
        let externalApplication = WorkspaceApplicationSnapshot(
            processIdentifier: 100,
            bundleIdentifier: "com.apple.TextEdit",
            localizedName: "TextEdit"
        )
        let pyPaste = WorkspaceApplicationSnapshot(
            processIdentifier: 42,
            bundleIdentifier: "com.pypaste.app",
            localizedName: "PyPaste"
        )

        tracker.record(externalApplication)
        tracker.record(pyPaste)

        XCTAssertEqual(tracker.frontmostApplication, externalApplication.sourceApplication)
    }

    func testExternalActivationReplacesPreviousSourceApplication() {
        var tracker = FrontmostApplicationTracker(ignoredProcessIdentifier: 42)
        let textEdit = WorkspaceApplicationSnapshot(
            processIdentifier: 100,
            bundleIdentifier: "com.apple.TextEdit",
            localizedName: "TextEdit"
        )
        let safari = WorkspaceApplicationSnapshot(
            processIdentifier: 101,
            bundleIdentifier: "com.apple.Safari",
            localizedName: "Safari"
        )

        tracker.record(textEdit)
        tracker.record(safari)

        XCTAssertEqual(tracker.frontmostApplication, safari.sourceApplication)
    }

    func testMissingFrontmostApplicationClearsTrackedSource() {
        var tracker = FrontmostApplicationTracker(ignoredProcessIdentifier: 42)
        let externalApplication = WorkspaceApplicationSnapshot(
            processIdentifier: 100,
            bundleIdentifier: "com.apple.TextEdit",
            localizedName: "TextEdit"
        )

        tracker.record(externalApplication)
        tracker.record(nil)

        XCTAssertNil(tracker.frontmostApplication)
    }
}
