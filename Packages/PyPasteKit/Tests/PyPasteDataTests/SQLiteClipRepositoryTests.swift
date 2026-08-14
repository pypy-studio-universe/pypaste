import Foundation
import PyPasteDomain
import XCTest

@testable import PyPasteData

final class SQLiteClipRepositoryTests: XCTestCase {
    func testPersistsMultiplePasteboardItemsInTheirOriginalOrder() async throws {
        let context = try await makeContext()
        defer { try? FileManager.default.removeItem(at: context.directoryURL) }
        let clip = makeClip(hash: "ordered", itemIndexes: [0, 0, 1, 2])

        _ = try await context.repository.save(clip, duplicatePolicy: .createNew)
        let optionalStored = try await context.repository.clip(id: clip.id)
        let stored = try XCTUnwrap(optionalStored)

        XCTAssertEqual(stored.id, clip.id)
        XCTAssertEqual(stored.contentKind, clip.contentKind)
        XCTAssertEqual(stored.sourceApplication, clip.sourceApplication)
        XCTAssertEqual(stored.representations, clip.representations)
        XCTAssertEqual(stored.pasteboardItems, clip.pasteboardItems)
    }

    func testMoveToTopDuplicatePolicyReusesRecordAndIncrementsCopyCount() async throws {
        let context = try await makeContext()
        defer { try? FileManager.default.removeItem(at: context.directoryURL) }
        let first = makeClip(hash: "same", itemIndexes: [0])
        let other = makeClip(hash: "other", itemIndexes: [0])
        let duplicate = makeClip(hash: "same", itemIndexes: [0])

        _ = try await context.repository.save(first, duplicatePolicy: .moveExistingToTop)
        _ = try await context.repository.save(other, duplicatePolicy: .moveExistingToTop)
        let result = try await context.repository.save(
            duplicate,
            duplicatePolicy: .moveExistingToTop
        )
        let recent = try await context.repository.recentClips(limit: 10)

        XCTAssertEqual(result.outcome, .movedExisting)
        XCTAssertEqual(result.clip.id, first.id)
        XCTAssertEqual(result.clip.copyCount, 2)
        XCTAssertEqual(recent.map(\.id), [first.id, other.id])
    }

    func testCreateNewDuplicatePolicyInsertsSeparateRecord() async throws {
        let context = try await makeContext()
        defer { try? FileManager.default.removeItem(at: context.directoryURL) }
        let first = makeClip(hash: "same", itemIndexes: [0])
        let duplicate = makeClip(hash: "same", itemIndexes: [0])

        _ = try await context.repository.save(first, duplicatePolicy: .createNew)
        let result = try await context.repository.save(duplicate, duplicatePolicy: .createNew)
        let recent = try await context.repository.recentClips(limit: 10)

        XCTAssertEqual(result.outcome, .inserted)
        XCTAssertEqual(result.clip.id, duplicate.id)
        XCTAssertEqual(recent.map(\.id), [duplicate.id, first.id])
    }

    func testMovePersistsCanonicalOrderAndPreservesEveryOtherClip() async throws {
        let context = try await makeContext()
        defer { try? FileManager.default.removeItem(at: context.directoryURL) }
        let clips = (0..<6).map { index in
            makeClip(hash: "move-\(index)", itemIndexes: [0])
        }

        for clip in clips {
            _ = try await context.repository.save(clip, duplicatePolicy: .createNew)
        }

        let initialOrder = try await context.repository.recentClips(limit: 20).map(\.id)
        XCTAssertEqual(initialOrder, clips.reversed().map(\.id))

        try await context.repository.move(
            id: initialOrder[0],
            relativeTo: initialOrder[3],
            placement: .after
        )
        var expectedOrder = [
            initialOrder[1], initialOrder[2], initialOrder[3], initialOrder[0], initialOrder[4],
            initialOrder[5],
        ]
        let orderAfterMovingDown = try await context.repository.recentClips(limit: 20).map(\.id)
        XCTAssertEqual(orderAfterMovingDown, expectedOrder)

        try await context.repository.move(
            id: expectedOrder[5],
            relativeTo: expectedOrder[0],
            placement: .before
        )
        expectedOrder = [
            expectedOrder[5], expectedOrder[0], expectedOrder[1], expectedOrder[2],
            expectedOrder[3], expectedOrder[4],
        ]

        let reloadedRepository = SQLiteClipRepository(databaseURL: context.databaseURL)
        let reloadedOrder = try await reloadedRepository.recentClips(limit: 20).map(\.id)
        XCTAssertEqual(reloadedOrder, expectedOrder)
    }

    func testRecordUseUpdatesMetadataWithoutChangingManualOrder() async throws {
        let context = try await makeContext()
        defer { try? FileManager.default.removeItem(at: context.directoryURL) }
        let clips = (0..<3).map { index in
            makeClip(hash: "record-use-\(index)", itemIndexes: [0])
        }

        for clip in clips {
            _ = try await context.repository.save(clip, duplicatePolicy: .createNew)
        }

        try await context.repository.move(
            id: clips[0].id,
            relativeTo: clips[2].id,
            placement: .before
        )
        let orderBeforeUse = try await context.repository.recentClips(limit: 10).map(\.id)
        let usedAt = Date().addingTimeInterval(3_600)
        let updated = try await context.repository.recordUse(id: clips[1].id, at: usedAt)
        let orderAfterUse = try await context.repository.recentClips(limit: 10).map(\.id)

        XCTAssertEqual(orderAfterUse, orderBeforeUse)
        XCTAssertEqual(updated?.copyCount, clips[1].copyCount + 1)
        XCTAssertEqual(
            try XCTUnwrap(updated?.lastUsedAt).timeIntervalSince1970,
            usedAt.timeIntervalSince1970,
            accuracy: 0.000_001
        )
    }

    func testMoveToTrashIsIdempotentAndKeepsStoredPayload() async throws {
        let context = try await makeContext()
        defer { try? FileManager.default.removeItem(at: context.directoryURL) }
        let first = makeClip(hash: "trash-first", itemIndexes: [0, 1])
        let second = makeClip(hash: "trash-second", itemIndexes: [0])

        _ = try await context.repository.save(first, duplicatePolicy: .createNew)
        _ = try await context.repository.save(second, duplicatePolicy: .createNew)

        let deletedAt = Date()
        try await context.repository.moveToTrash(id: first.id, at: deletedAt)
        try await context.repository.moveToTrash(id: first.id, at: deletedAt)

        let activeIDs = try await context.repository.recentClips(limit: 10).map(\.id)
        let storedTrashedClip = try await context.repository.clip(id: first.id)
        let trashedClip = try XCTUnwrap(storedTrashedClip)
        XCTAssertEqual(activeIDs, [second.id])
        XCTAssertEqual(trashedClip.id, first.id)
        XCTAssertEqual(trashedClip.representations, first.representations)
        XCTAssertEqual(trashedClip.pasteboardItems, first.pasteboardItems)
    }

    func testCollectionMembershipAndCustomCollectionPersistAcrossRepositoryInstances() async throws
    {
        let context = try await makeContext()
        defer { try? FileManager.default.removeItem(at: context.directoryURL) }
        let clip = makeClip(hash: "permanent-collection", itemIndexes: [0])
        _ = try await context.repository.save(clip, duplicatePolicy: .createNew)
        let initialSnapshot = try await context.repository.collectionSnapshot(
            selectedCollectionID: nil,
            limit: 20
        )
        let usefulLinks = try XCTUnwrap(
            initialSnapshot.collections.first(where: { $0.name == "Useful Links" })
        )
        let createdAt = Date(timeIntervalSince1970: 1_000)
        let customCollection = try await context.repository.createCollection(
            name: "Project Alpha",
            colorHex: "#BF5AF2",
            at: createdAt
        )

        try await context.repository.addClip(id: clip.id, to: usefulLinks.id, at: createdAt)
        try await context.repository.addClip(id: clip.id, to: customCollection.id, at: createdAt)

        let reloadedRepository = SQLiteClipRepository(databaseURL: context.databaseURL)
        let customSnapshot = try await reloadedRepository.collectionSnapshot(
            selectedCollectionID: customCollection.id,
            limit: 20
        )
        let clipboardSnapshot = try await reloadedRepository.collectionSnapshot(
            selectedCollectionID: nil,
            limit: 20
        )

        XCTAssertEqual(customSnapshot.clips.map(\.id), [clip.id])
        XCTAssertEqual(
            customSnapshot.collectionIDsByClipID[clip.id],
            Set([usefulLinks.id, customCollection.id])
        )
        XCTAssertTrue(clipboardSnapshot.collections.contains(customCollection))

        let connection = try SQLiteConnection(databaseURL: context.databaseURL)
        let statement = try connection.prepare(
            "SELECT is_retention_protected FROM clips WHERE id = ?;"
        )
        try statement.bind(clip.id.uuidString, at: 1)
        XCTAssertTrue(try statement.step())
        XCTAssertEqual(statement.integer(at: 0), 1)
    }

    func testDeletingPermanentCollectionItemStillRequiresExplicitTrashAction() async throws {
        let context = try await makeContext()
        defer { try? FileManager.default.removeItem(at: context.directoryURL) }
        let clip = makeClip(hash: "explicit-delete", itemIndexes: [0])
        _ = try await context.repository.save(clip, duplicatePolicy: .createNew)
        let initialSnapshot = try await context.repository.collectionSnapshot(
            selectedCollectionID: nil,
            limit: 10
        )
        let collection = try XCTUnwrap(initialSnapshot.collections.first)
        try await context.repository.addClip(id: clip.id, to: collection.id, at: Date())

        let populatedSnapshot = try await context.repository.collectionSnapshot(
            selectedCollectionID: collection.id,
            limit: 10
        )
        XCTAssertEqual(populatedSnapshot.clips.map(\.id), [clip.id])

        try await context.repository.moveToTrash(id: clip.id, at: Date())

        let deletedSnapshot = try await context.repository.collectionSnapshot(
            selectedCollectionID: collection.id,
            limit: 10
        )
        let storedClip = try await context.repository.clip(id: clip.id)
        XCTAssertTrue(deletedSnapshot.clips.isEmpty)
        XCTAssertNotNil(storedClip)
    }

    private func makeContext() async throws -> RepositoryTestContext {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let databaseURL = directoryURL.appendingPathComponent("PyPaste.sqlite")
        let migrator = SQLiteDatabaseMigrator(databaseURL: databaseURL)
        try await migrator.migrate()
        return RepositoryTestContext(
            directoryURL: directoryURL,
            databaseURL: databaseURL,
            repository: SQLiteClipRepository(databaseURL: databaseURL)
        )
    }

    private func makeClip(hash: String, itemIndexes: [Int]) -> Clip {
        let now = Date()
        let representations = itemIndexes.enumerated().map { order, itemIndex in
            ClipRepresentation(
                itemIndex: itemIndex,
                order: order,
                typeIdentifier: "public.utf8-plain-text",
                data: Data("item-\(itemIndex)-\(order)".utf8)
            )
        }

        return Clip(
            createdAt: now,
            contentKind: .text,
            displayTitle: "Repository test",
            searchableText: "Repository test",
            sourceApplication: SourceApplication(
                bundleIdentifier: "com.example.source",
                localizedName: "Source"
            ),
            contentHash: hash,
            characterCount: 15,
            lineCount: 1,
            representations: representations
        )
    }
}

private struct RepositoryTestContext {
    let directoryURL: URL
    let databaseURL: URL
    let repository: SQLiteClipRepository
}
