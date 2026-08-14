import Foundation
import PyPasteDomain
import XCTest

@testable import PyPasteFeatures

final class QuickBarModelTests: XCTestCase {
    @MainActor
    func testPresentationPreservesRepositoryOrderAndLimitsRecentClips() {
        let now = Date()
        let clips = [
            makeClip(title: "first", lastUsedAt: now),
            makeClip(title: "second", lastUsedAt: now.addingTimeInterval(30)),
            makeClip(title: "third", lastUsedAt: now.addingTimeInterval(20)),
        ]
        let model = QuickBarModel(maximumClipCount: 2, onPaste: { _ in }, onDismiss: {})

        model.prepareForPresentation(with: clips)

        XCTAssertEqual(model.clips.map(\.displayTitle), ["first", "second"])
        XCTAssertEqual(model.selectedClipID, model.clips.first?.id)
        XCTAssertNil(model.feedbackMessage)
    }

    @MainActor
    func testCapturedUpsertMovesClipToFrontButMetadataUpdateKeepsItsPosition() throws {
        let now = Date()
        let first = makeClip(title: "first", lastUsedAt: now)
        let second = makeClip(title: "second", lastUsedAt: now)
        let third = makeClip(title: "third", lastUsedAt: now)
        let model = QuickBarModel(onPaste: { _ in }, onDismiss: {})
        model.replaceClips([first, second, third])

        let updatedSecond = makeClip(
            id: second.id,
            title: "second updated",
            lastUsedAt: now.addingTimeInterval(60),
            copyCount: 2
        )
        model.update(updatedSecond)

        XCTAssertEqual(model.clips.map(\.id), [first.id, second.id, third.id])
        XCTAssertEqual(model.clips[1].displayTitle, "second updated")
        XCTAssertEqual(model.clips[1].copyCount, 2)

        model.upsert(updatedSecond)

        XCTAssertEqual(model.clips.map(\.id), [second.id, first.id, third.id])
    }

    @MainActor
    func testMoveChangesLocalOrderAndRequestsPersistence() throws {
        let clips = (0..<3).map { index in
            makeClip(title: "clip-\(index)", lastUsedAt: Date())
        }
        var moveRequests: [ClipMoveRequest] = []
        let model = QuickBarModel(
            onPaste: { _ in },
            onDismiss: {},
            onMove: {
                moveRequests.append(
                    ClipMoveRequest(clipID: $0, targetID: $1, placement: $2)
                )
            }
        )
        model.prepareForPresentation(with: clips)

        model.move(clips[2].id, relativeTo: clips[0].id, placement: .before)

        XCTAssertEqual(model.clips.map(\.id), [clips[2].id, clips[0].id, clips[1].id])
        XCTAssertEqual(model.selectedClipID, clips[0].id)
        XCTAssertEqual(moveRequests.count, 1)
        XCTAssertEqual(moveRequests[0].clipID, clips[2].id)
        XCTAssertEqual(moveRequests[0].targetID, clips[0].id)
        XCTAssertEqual(moveRequests[0].placement, .before)

        model.move(clips[2].id, relativeTo: clips[1].id, placement: .after)

        XCTAssertEqual(model.clips.map(\.id), clips.map(\.id))
        XCTAssertEqual(moveRequests.count, 2)
        XCTAssertEqual(moveRequests[1].placement, .after)

        model.move(clips[2].id, relativeTo: clips[1].id, placement: .after)
        model.move(UUID(), relativeTo: clips[0].id, placement: .after)

        XCTAssertEqual(moveRequests.count, 2)
    }

    @MainActor
    func testDeletingSelectedClipSelectsAdjacentClipAndRequestsPersistence() {
        let clips = (0..<3).map { index in
            makeClip(title: "clip-\(index)", lastUsedAt: Date())
        }
        var pastedIDs: [Clip.ID] = []
        var deletedIDs: [Clip.ID] = []
        let model = QuickBarModel(
            onPaste: { pastedIDs.append($0.id) },
            onDismiss: {},
            onDelete: { deletedIDs.append($0) }
        )
        model.prepareForPresentation(with: clips)
        model.selectNext()

        model.moveToTrash(clips[1].id)

        XCTAssertEqual(model.clips.map(\.id), [clips[0].id, clips[2].id])
        XCTAssertEqual(model.selectedClipID, clips[2].id)

        model.moveToTrash(clips[2].id)

        XCTAssertEqual(model.selectedClipID, clips[0].id)

        model.moveToTrash(clips[0].id)

        XCTAssertTrue(model.clips.isEmpty)
        XCTAssertNil(model.selectedClipID)
        XCTAssertTrue(pastedIDs.isEmpty)
        XCTAssertEqual(deletedIDs, [clips[1].id, clips[2].id, clips[0].id])
    }

    @MainActor
    func testMoveAndDeleteAreIgnoredWhilePasteIsProcessing() {
        let clips = (0..<3).map { index in
            makeClip(title: "clip-\(index)", lastUsedAt: Date())
        }
        var moveCount = 0
        var deleteCount = 0
        let model = QuickBarModel(
            onPaste: { _ in },
            onDismiss: {},
            onMove: { _, _, _ in moveCount += 1 },
            onDelete: { _ in deleteCount += 1 }
        )
        model.prepareForPresentation(with: clips)
        model.paste(clips[0])

        model.move(clips[2].id, relativeTo: clips[0].id, placement: .before)
        model.moveToTrash(clips[1].id)

        XCTAssertEqual(model.clips.map(\.id), clips.map(\.id))
        XCTAssertEqual(moveCount, 0)
        XCTAssertEqual(deleteCount, 0)
    }

    @MainActor
    func testKeyboardSelectionMovesAndPastesSelectedClip() {
        let now = Date()
        let clips = (0..<3).map { index in
            makeClip(title: "clip-\(index)", lastUsedAt: now.addingTimeInterval(Double(index)))
        }
        var pastedClipID: Clip.ID?
        let model = QuickBarModel(onPaste: { pastedClipID = $0.id }, onDismiss: {})

        model.prepareForPresentation(with: clips)
        model.selectNext()

        XCTAssertEqual(model.selectedClipID, model.clips[1].id)

        model.selectNext()
        model.selectNext()

        XCTAssertEqual(model.selectedClipID, model.clips[2].id)

        model.selectPrevious()
        model.pasteSelected()

        XCTAssertEqual(model.selectedClipID, model.clips[1].id)
        XCTAssertEqual(pastedClipID, model.clips[1].id)
    }

    @MainActor
    func testPastePreventsDoubleSubmissionUntilCompletion() throws {
        let clip = makeClip(title: "selected", lastUsedAt: Date())
        var pastedClipIDs: [Clip.ID] = []
        let model = QuickBarModel(
            onPaste: { pastedClipIDs.append($0.id) },
            onDismiss: {}
        )

        model.paste(clip)
        model.paste(clip)

        XCTAssertEqual(pastedClipIDs, [clip.id])
        XCTAssertEqual(model.processingClipID, clip.id)

        model.completePaste(feedbackMessage: "Copied")

        XCTAssertNil(model.processingClipID)
        XCTAssertEqual(model.feedbackMessage, "Copied")
    }

    @MainActor
    func testSearchFiltersAllFieldsAndKeepsKeyboardSelectionValid() {
        let safariClip = Clip(
            contentKind: .url,
            displayTitle: "Floral Design Studio",
            searchableText: "https://example.com/design",
            sourceApplication: SourceApplication(
                bundleIdentifier: "com.apple.Safari",
                localizedName: "Safari"
            ),
            contentHash: "safari"
        )
        let notesClip = makeClip(title: "Meeting notes", lastUsedAt: Date())
        let model = QuickBarModel(onPaste: { _ in }, onDismiss: {})
        model.prepareForPresentation(with: [notesClip, safariClip])

        model.updateSearchQuery("safari floral")

        XCTAssertEqual(model.clips, [safariClip])
        XCTAssertEqual(model.totalClipCount, 2)
        XCTAssertEqual(model.selectedClipID, safariClip.id)

        model.updateSearchQuery("")

        XCTAssertEqual(model.clips.map(\.id), [notesClip.id, safariClip.id])
        XCTAssertEqual(model.selectedClipID, safariClip.id)
    }

    func testLayoutFitsSixCardsInsideScrollerIncludingInsetsAndSpacing() {
        let containerWidth: CGFloat = 1_296
        let layout = QuickBarLayoutMetrics(containerWidth: containerWidth, itemCount: 13)

        let occupiedWidth =
            layout.edgeInset * 2
            + layout.cardWidth * CGFloat(layout.visibleCardCount)
            + layout.cardSpacing * CGFloat(layout.visibleCardCount - 1)

        XCTAssertEqual(layout.visibleCardCount, 6)
        XCTAssertEqual(occupiedWidth, containerWidth, accuracy: 0.001)
    }

    func testLayoutKeepsPreferredCardWidthWhenEveryItemAlreadyFits() {
        let layout = QuickBarLayoutMetrics(containerWidth: 1_296, itemCount: 3)

        XCTAssertEqual(layout.visibleCardCount, 3)
        XCTAssertEqual(layout.cardWidth, QuickBarLayoutMetrics.preferredCardWidth)
    }

    private func makeClip(
        id: UUID = UUID(),
        title: String,
        lastUsedAt: Date,
        copyCount: Int = 1
    ) -> Clip {
        Clip(
            id: id,
            lastUsedAt: lastUsedAt,
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
