import Carbon.HIToolbox
import XCTest

@testable import PyPasteCore

final class QuickBarKeyboardMonitorTests: XCTestCase {
    @MainActor
    func testRegistersAndUnregistersAllPinnedQuickBarCommands() throws {
        let monitor = CarbonQuickBarKeyboardMonitor()

        try monitor.start { _ in }
        XCTAssertTrue(monitor.isRegistered)

        monitor.stop()
        XCTAssertFalse(monitor.isRegistered)
    }

    @MainActor
    func testRoutesKnownCommandAndIgnoresUnknownIdentifier() throws {
        let monitor = CarbonQuickBarKeyboardMonitor()
        var receivedCommands: [QuickBarKeyboardCommand] = []
        try monitor.start { receivedCommands.append($0) }
        defer { monitor.stop() }

        monitor.handle(commandID: QuickBarKeyboardCommand.selectNext.rawValue)
        monitor.handle(commandID: UInt32.max)

        XCTAssertEqual(receivedCommands, [.selectNext])
    }
}
