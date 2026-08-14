import Foundation
import PyPasteDomain
import XCTest

@testable import PyPasteFeatures

final class QuickBarDragSessionTests: XCTestCase {
    func testBeginningNewDragClearsPreviousPreview() {
        let firstClipID = UUID()
        let secondClipID = UUID()
        let targetClipID = UUID()
        var session = QuickBarDragSession()

        session.beginDragging(firstClipID)
        XCTAssertTrue(
            session.updatePreview(
                relativeTo: targetClipID,
                locationX: 20,
                targetWidth: 100
            ))

        session.beginDragging(secondClipID)

        XCTAssertEqual(session.draggedClipID, secondClipID)
        XCTAssertNil(session.preview)
    }

    func testInitialPreviewUsesLeftAndRightHalvesWithMidpointAfter() throws {
        let draggedClipID = UUID()
        let targetClipID = UUID()
        var session = QuickBarDragSession()

        session.beginDragging(draggedClipID)
        XCTAssertTrue(
            session.updatePreview(
                relativeTo: targetClipID,
                locationX: 49.9,
                targetWidth: 100
            ))
        XCTAssertEqual(session.preview?.placement, .before)

        session.beginDragging(draggedClipID)
        XCTAssertTrue(
            session.updatePreview(
                relativeTo: targetClipID,
                locationX: 50,
                targetWidth: 100
            ))
        XCTAssertEqual(session.preview?.placement, .after)
    }

    func testPreviewUsesHysteresisAroundMidpoint() {
        let draggedClipID = UUID()
        let targetClipID = UUID()
        var session = QuickBarDragSession()
        session.beginDragging(draggedClipID)

        XCTAssertTrue(
            session.updatePreview(
                relativeTo: targetClipID,
                locationX: 30,
                targetWidth: 100
            ))
        XCTAssertEqual(session.preview?.placement, .before)

        XCTAssertTrue(
            session.updatePreview(
                relativeTo: targetClipID,
                locationX: 55,
                targetWidth: 100
            ))
        XCTAssertEqual(session.preview?.placement, .before)

        XCTAssertTrue(
            session.updatePreview(
                relativeTo: targetClipID,
                locationX: 60,
                targetWidth: 100
            ))
        XCTAssertEqual(session.preview?.placement, .after)

        XCTAssertTrue(
            session.updatePreview(
                relativeTo: targetClipID,
                locationX: 45,
                targetWidth: 100
            ))
        XCTAssertEqual(session.preview?.placement, .after)

        XCTAssertTrue(
            session.updatePreview(
                relativeTo: targetClipID,
                locationX: 40,
                targetWidth: 100
            ))
        XCTAssertEqual(session.preview?.placement, .before)
    }

    func testInactiveAndSelfDropAreRejected() {
        let draggedClipID = UUID()
        let targetClipID = UUID()
        var session = QuickBarDragSession()

        XCTAssertFalse(
            session.updatePreview(
                relativeTo: targetClipID,
                locationX: 20,
                targetWidth: 100
            ))

        session.beginDragging(draggedClipID)
        XCTAssertTrue(
            session.updatePreview(
                relativeTo: targetClipID,
                locationX: 20,
                targetWidth: 100
            ))
        XCTAssertFalse(
            session.updatePreview(
                relativeTo: draggedClipID,
                locationX: 20,
                targetWidth: 100
            ))
        XCTAssertNil(session.preview)
    }

    func testInvalidGeometryClearsPreviewAndInvalidCommitCancelsSession() {
        let draggedClipID = UUID()
        let targetClipID = UUID()
        var session = QuickBarDragSession()
        session.beginDragging(draggedClipID)

        assertInvalidGeometryClearsPreview(
            session: &session,
            targetClipID: targetClipID,
            locationX: .nan,
            targetWidth: 100
        )
        assertInvalidGeometryClearsPreview(
            session: &session,
            targetClipID: targetClipID,
            locationX: 20,
            targetWidth: 0
        )
        assertInvalidGeometryClearsPreview(
            session: &session,
            targetClipID: targetClipID,
            locationX: 20,
            targetWidth: .infinity
        )

        XCTAssertTrue(
            session.updatePreview(
                relativeTo: targetClipID,
                locationX: 20,
                targetWidth: 100
            ))
        XCTAssertNil(
            session.commit(
                relativeTo: targetClipID,
                locationX: .nan,
                targetWidth: 100
            )
        )
        XCTAssertNil(session.draggedClipID)
        XCTAssertNil(session.preview)
    }

    private func assertInvalidGeometryClearsPreview(
        session: inout QuickBarDragSession,
        targetClipID: Clip.ID,
        locationX: CGFloat,
        targetWidth: CGFloat
    ) {
        XCTAssertTrue(
            session.updatePreview(
                relativeTo: targetClipID,
                locationX: 20,
                targetWidth: 100
            ))
        XCTAssertFalse(
            session.updatePreview(
                relativeTo: targetClipID,
                locationX: locationX,
                targetWidth: targetWidth
            ))
        XCTAssertNil(session.preview)
    }

    func testLeavingOldTargetDoesNotClearCurrentTargetPreview() {
        let draggedClipID = UUID()
        let firstTargetID = UUID()
        let secondTargetID = UUID()
        var session = QuickBarDragSession()
        session.beginDragging(draggedClipID)

        XCTAssertTrue(
            session.updatePreview(
                relativeTo: firstTargetID,
                locationX: 20,
                targetWidth: 100
            ))
        XCTAssertTrue(
            session.updatePreview(
                relativeTo: secondTargetID,
                locationX: 80,
                targetWidth: 100
            ))

        session.leave(firstTargetID)

        XCTAssertEqual(
            session.preview,
            QuickBarDropPreview(targetClipID: secondTargetID, placement: .after)
        )

        session.leave(secondTargetID)
        XCTAssertNil(session.preview)
    }

    func testCommitUsesReleaseLocationOnceAndClearsSession() throws {
        let draggedClipID = UUID()
        let targetClipID = UUID()
        var session = QuickBarDragSession()
        session.beginDragging(draggedClipID)
        XCTAssertTrue(
            session.updatePreview(
                relativeTo: targetClipID,
                locationX: 80,
                targetWidth: 100
            ))

        let request = try XCTUnwrap(
            session.commit(
                relativeTo: targetClipID,
                locationX: 20,
                targetWidth: 100
            )
        )

        XCTAssertEqual(
            request,
            QuickBarDropRequest(
                draggedClipID: draggedClipID,
                targetClipID: targetClipID,
                placement: .before
            )
        )
        XCTAssertNil(session.draggedClipID)
        XCTAssertNil(session.preview)
        XCTAssertNil(
            session.commit(
                relativeTo: targetClipID,
                locationX: 20,
                targetWidth: 100
            )
        )
    }

    func testCancelClearsEntireSession() {
        let draggedClipID = UUID()
        let targetClipID = UUID()
        var session = QuickBarDragSession()
        session.beginDragging(draggedClipID)
        XCTAssertTrue(
            session.updatePreview(
                relativeTo: targetClipID,
                locationX: 20,
                targetWidth: 100
            ))

        session.cancel()

        XCTAssertNil(session.draggedClipID)
        XCTAssertNil(session.preview)
    }
}
