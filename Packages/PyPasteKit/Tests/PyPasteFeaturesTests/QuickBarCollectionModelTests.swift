import Foundation
import PyPasteDomain
import XCTest

@testable import PyPasteFeatures

final class QuickBarCollectionModelTests: XCTestCase {
    @MainActor
    func testPresentationDefaultsToClipboardAndCollectionSelectionRequestsReload() {
        let collection = makeCollection(name: "Useful Links")
        let clip = makeClip(title: "Link")
        var selectedCollectionIDs: [ClipCollection.ID?] = []
        let model = QuickBarModel(
            onPaste: { _ in },
            onDismiss: {},
            onSelectCollection: { selectedCollectionIDs.append($0) }
        )
        model.prepareForPresentation(
            with: ClipCollectionSnapshot(
                collections: [collection],
                clips: [clip],
                collectionIDsByClipID: [:]
            )
        )

        XCTAssertNil(model.selectedCollectionID)
        XCTAssertEqual(model.selectedCollectionName, "Clipboard")

        model.selectCollection(collection.id)

        XCTAssertEqual(model.selectedCollectionID, collection.id)
        XCTAssertEqual(model.selectedCollectionName, collection.name)
        XCTAssertTrue(model.isLoadingCollection)
        XCTAssertTrue(model.clips.isEmpty)
        XCTAssertEqual(selectedCollectionIDs.count, 1)
        XCTAssertEqual(selectedCollectionIDs[0], collection.id)
    }

    @MainActor
    func testAddingToCollectionIsRequestedOnlyUntilSnapshotConfirmsMembership() {
        let collection = makeCollection(name: "Important Notes")
        let clip = makeClip(title: "Note")
        var addRequests: [(Clip.ID, ClipCollection.ID)] = []
        let model = QuickBarModel(
            onPaste: { _ in },
            onDismiss: {},
            onAddToCollection: { addRequests.append(($0, $1)) }
        )
        model.prepareForPresentation(
            with: ClipCollectionSnapshot(
                collections: [collection],
                clips: [clip],
                collectionIDsByClipID: [:]
            )
        )

        model.addToCollection(clipID: clip.id, collectionID: collection.id)
        XCTAssertEqual(addRequests.count, 1)

        model.applyCollectionSnapshot(
            ClipCollectionSnapshot(
                collections: [collection],
                clips: [clip],
                collectionIDsByClipID: [clip.id: [collection.id]]
            ),
            for: nil
        )
        model.addToCollection(clipID: clip.id, collectionID: collection.id)

        XCTAssertEqual(addRequests.count, 1)
        XCTAssertEqual(model.collectionIDs(for: clip.id), [collection.id])
    }

    @MainActor
    func testCreateCollectionTrimsNameAndAssignsPaletteColor() {
        var requests: [(String, String)] = []
        let model = QuickBarModel(
            onPaste: { _ in },
            onDismiss: {},
            onCreateCollection: { requests.append(($0, $1)) }
        )

        model.createCollection(named: "  Research  ")
        model.createCollection(named: "   ")

        XCTAssertEqual(requests.count, 1)
        XCTAssertEqual(requests[0].0, "Research")
        XCTAssertTrue(requests[0].1.hasPrefix("#"))
        XCTAssertEqual(model.feedbackMessage, "Enter a collection name.")
    }

    @MainActor
    func testDeletingSelectedCollectionRequiresRequestThenReturnsModelToClipboard() {
        let collection = makeCollection(name: "Project Alpha")
        let clip = makeClip(title: "Saved note")
        var deleteRequests: [ClipCollection.ID] = []
        let model = QuickBarModel(
            onPaste: { _ in },
            onDismiss: {},
            onDeleteCollection: { deleteRequests.append($0) }
        )
        model.prepareForPresentation(
            with: ClipCollectionSnapshot(
                collections: [collection],
                clips: [clip],
                collectionIDsByClipID: [clip.id: [collection.id]]
            )
        )
        model.selectCollection(collection.id)

        model.deleteCollection(collection.id)

        XCTAssertEqual(deleteRequests, [collection.id])
        XCTAssertEqual(model.selectedCollectionID, collection.id)

        model.applyDeletedCollection(collection.id)

        XCTAssertFalse(model.collections.contains(collection))
        XCTAssertNil(model.selectedCollectionID)
        XCTAssertEqual(model.selectedCollectionName, "Clipboard")
        XCTAssertTrue(model.isLoadingCollection)
        XCTAssertTrue(model.clips.isEmpty)
    }

    @MainActor
    func testCollectionDialogsAreMutuallyExclusiveAndDismissTopmostState() {
        let collection = makeCollection(name: "Important Notes")
        let model = QuickBarModel(onPaste: { _ in }, onDismiss: {})

        model.presentCreateCollectionDialog()
        XCTAssertEqual(model.collectionDialog, .create)
        XCTAssertTrue(model.isPresentingCollectionDialog)
        XCTAssertNil(model.collectionPendingDeletion)

        model.presentDeleteCollectionDialog(for: collection)
        XCTAssertEqual(model.collectionDialog, .delete(collection))
        XCTAssertEqual(model.collectionPendingDeletion, collection)
        XCTAssertTrue(model.dismissCollectionDialog())
        XCTAssertNil(model.collectionDialog)
        XCTAssertFalse(model.dismissCollectionDialog())
    }

    private func makeCollection(name: String) -> ClipCollection {
        ClipCollection(name: name, colorHex: "#FF453A", sortOrder: 10)
    }

    private func makeClip(title: String) -> Clip {
        Clip(
            contentKind: .text,
            displayTitle: title,
            searchableText: title,
            contentHash: title
        )
    }
}
