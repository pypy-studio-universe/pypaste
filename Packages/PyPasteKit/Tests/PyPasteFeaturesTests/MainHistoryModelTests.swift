import Foundation
import PyPasteDomain
import XCTest

@testable import PyPasteFeatures

final class MainHistoryModelTests: XCTestCase {
    @MainActor
    func testReplaceAndMetadataUpdatePreserveRepositoryOrder() {
        let clips = [makeClip("first"), makeClip("second"), makeClip("third")]
        let model = makeModel()

        model.replaceClips(clips)
        model.update(makeClip("second updated", id: clips[1].id, copyCount: 2))

        XCTAssertEqual(model.clips.map(\.id), clips.map(\.id))
        XCTAssertEqual(model.clips[1].displayTitle, "second updated")
        XCTAssertEqual(model.clips[1].copyCount, 2)
    }

    @MainActor
    func testCapturedUpsertPlacesNewAndExistingClipAtFront() {
        let clips = [makeClip("first"), makeClip("second"), makeClip("third")]
        let model = makeModel()
        model.replaceClips(clips)

        let newClip = makeClip("new")
        model.upsert(newClip)
        model.upsert(makeClip("second captured again", id: clips[1].id))

        XCTAssertEqual(
            model.clips.map(\.id),
            [clips[1].id, newClip.id, clips[0].id, clips[2].id]
        )
    }

    @MainActor
    func testMoveAndDeleteUpdateLocalHistoryAndRequestPersistence() {
        let clips = [makeClip("first"), makeClip("second"), makeClip("third")]
        var moveRequest: ClipMoveRequest?
        var deletedIDs: [Clip.ID] = []
        let model = MainHistoryModel(
            onCopy: { _ in },
            onToggleMonitoring: {},
            onMove: {
                moveRequest = ClipMoveRequest(clipID: $0, targetID: $1, placement: $2)
            },
            onDelete: { deletedIDs.append($0) }
        )
        model.replaceClips(clips)

        model.move(clips[2].id, relativeTo: clips[0].id, placement: .before)
        model.moveToTrash(clips[1].id)

        XCTAssertEqual(model.clips.map(\.id), [clips[2].id, clips[0].id])
        XCTAssertEqual(
            moveRequest,
            ClipMoveRequest(clipID: clips[2].id, targetID: clips[0].id, placement: .before)
        )
        XCTAssertEqual(deletedIDs, [clips[1].id])
    }

    @MainActor
    func testInvalidAndNoOpEditsDoNotRequestPersistence() {
        let clips = [makeClip("first"), makeClip("second")]
        var moveCount = 0
        var deleteCount = 0
        let model = MainHistoryModel(
            onCopy: { _ in },
            onToggleMonitoring: {},
            onMove: { _, _, _ in moveCount += 1 },
            onDelete: { _ in deleteCount += 1 }
        )
        model.replaceClips(clips)

        model.move(clips[0].id, relativeTo: clips[1].id, placement: .before)
        model.move(UUID(), relativeTo: clips[0].id, placement: .after)
        model.moveToTrash(UUID())

        XCTAssertEqual(model.clips.map(\.id), clips.map(\.id))
        XCTAssertEqual(moveCount, 0)
        XCTAssertEqual(deleteCount, 0)
    }

    @MainActor
    func testSearchStaysAppliedWhenHistoryChangesAndClearRestoresCanonicalOrder() {
        let clips = [makeClip("Invoice"), makeClip("Meeting"), makeClip("Invoice archive")]
        let model = makeModel()
        model.replaceClips(clips)

        model.updateSearchQuery("invoice")
        model.upsert(makeClip("Unrelated capture"))

        XCTAssertEqual(model.clips.map(\.id), [clips[0].id, clips[2].id])
        XCTAssertEqual(model.totalClipCount, 4)

        model.updateSearchQuery("")

        XCTAssertEqual(model.clips.count, 4)
        XCTAssertEqual(model.clips.dropFirst().map(\.id), clips.map(\.id))
    }

    @MainActor
    private func makeModel() -> MainHistoryModel {
        MainHistoryModel(onCopy: { _ in }, onToggleMonitoring: {})
    }

    private func makeClip(
        _ title: String,
        id: UUID = UUID(),
        copyCount: Int = 1
    ) -> Clip {
        Clip(
            id: id,
            contentKind: .text,
            displayTitle: title,
            searchableText: title,
            contentHash: title,
            copyCount: copyCount
        )
    }
}

private struct ClipMoveRequest: Equatable {
    let clipID: Clip.ID
    let targetID: Clip.ID
    let placement: ClipPlacement
}
