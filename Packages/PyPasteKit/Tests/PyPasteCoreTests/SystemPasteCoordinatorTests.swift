import XCTest

@testable import PyPasteCore

final class SystemPasteCoordinatorTests: XCTestCase {
    @MainActor
    func testTrustedPasteActivatesTargetAndPostsCommandV() async {
        let target = PasteTarget(processIdentifier: 42)
        var didActivate = false
        var didPostKeyStroke = false
        let coordinator = SystemPasteCoordinator(
            activationDelay: .zero,
            isAccessibilityTrusted: { true },
            requestAccessibilityAccess: {},
            activateApplication: { receivedTarget in
                didActivate = receivedTarget == target
                return true
            },
            postPasteKeyStroke: {
                didPostKeyStroke = true
                return true
            }
        )

        let result = await coordinator.paste(to: target)

        XCTAssertEqual(result, .pasted)
        XCTAssertTrue(didActivate)
        XCTAssertTrue(didPostKeyStroke)
    }

    @MainActor
    func testDeniedAccessibilityRequestsPermissionAndDoesNotPost() async {
        let target = PasteTarget(processIdentifier: 42)
        var didRequestAccess = false
        var didActivate = false
        var didPostKeyStroke = false
        let coordinator = SystemPasteCoordinator(
            activationDelay: .zero,
            isAccessibilityTrusted: { false },
            requestAccessibilityAccess: { didRequestAccess = true },
            activateApplication: { _ in
                didActivate = true
                return true
            },
            postPasteKeyStroke: {
                didPostKeyStroke = true
                return true
            }
        )

        let result = await coordinator.paste(to: target)

        XCTAssertEqual(result, .copiedOnlyAccessibilityDenied)
        XCTAssertTrue(didRequestAccess)
        XCTAssertFalse(didActivate)
        XCTAssertFalse(didPostKeyStroke)
    }

    @MainActor
    func testDeniedAccessibilityRequestsPermissionOnlyOncePerSession() async {
        let target = PasteTarget(processIdentifier: 42)
        var requestCount = 0
        let coordinator = SystemPasteCoordinator(
            activationDelay: .zero,
            isAccessibilityTrusted: { false },
            requestAccessibilityAccess: { requestCount += 1 },
            activateApplication: { _ in true },
            postPasteKeyStroke: { true }
        )

        let firstResult = await coordinator.paste(to: target)
        let secondResult = await coordinator.paste(to: target)

        XCTAssertEqual(firstResult, .copiedOnlyAccessibilityDenied)
        XCTAssertEqual(secondResult, .copiedOnlyAccessibilityDenied)
        XCTAssertEqual(requestCount, 1)
    }

    @MainActor
    func testMissingTargetUsesCopyOnlyFallbackWithoutPermissionPrompt() async {
        var didRequestAccess = false
        let coordinator = SystemPasteCoordinator(
            activationDelay: .zero,
            isAccessibilityTrusted: { false },
            requestAccessibilityAccess: { didRequestAccess = true },
            activateApplication: { _ in true },
            postPasteKeyStroke: { true }
        )

        let result = await coordinator.paste(to: nil)

        XCTAssertEqual(result, .targetUnavailable)
        XCTAssertFalse(didRequestAccess)
    }
}
