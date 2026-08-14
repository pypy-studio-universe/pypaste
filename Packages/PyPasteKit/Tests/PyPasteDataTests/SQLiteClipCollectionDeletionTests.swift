import Foundation
import PyPasteDomain
import XCTest

@testable import PyPasteData

final class SQLiteClipCollectionDeletionTests: XCTestCase {
    func testDeletingCollectionKeepsClipAndItsPermanentRetentionProtection() async throws {
        let context = try await makeContext()
        defer { try? FileManager.default.removeItem(at: context.directoryURL) }
        let clip = makeClip()
        _ = try await context.repository.save(clip, duplicatePolicy: .createNew)
        let collection = try await context.repository.createCollection(
            name: "Temporary Folder",
            colorHex: "#BF5AF2",
            at: Date()
        )
        try await context.repository.addClip(id: clip.id, to: collection.id, at: Date())

        try await context.repository.deleteCollection(id: collection.id)

        let clipboardSnapshot = try await context.repository.collectionSnapshot(
            selectedCollectionID: nil,
            limit: 10
        )
        let deletedCollectionSnapshot = try await context.repository.collectionSnapshot(
            selectedCollectionID: collection.id,
            limit: 10
        )
        let storedClip = try await context.repository.clip(id: clip.id)
        XCTAssertFalse(clipboardSnapshot.collections.contains(collection))
        XCTAssertTrue(clipboardSnapshot.clips.contains(where: { $0.id == clip.id }))
        XCTAssertTrue(deletedCollectionSnapshot.clips.isEmpty)
        XCTAssertNotNil(storedClip)
        try assertRetentionProtection(for: clip.id, databaseURL: context.databaseURL)
    }

    private func makeContext() async throws -> CollectionDeletionTestContext {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let databaseURL = directoryURL.appendingPathComponent("PyPaste.sqlite")
        try await SQLiteDatabaseMigrator(databaseURL: databaseURL).migrate()
        return CollectionDeletionTestContext(
            directoryURL: directoryURL,
            databaseURL: databaseURL,
            repository: SQLiteClipRepository(databaseURL: databaseURL)
        )
    }

    private func makeClip() -> Clip {
        Clip(
            contentKind: .text,
            displayTitle: "Keep this clip",
            searchableText: "Keep this clip",
            contentHash: "delete-collection-keep-clip",
            representations: [
                ClipRepresentation(
                    itemIndex: 0,
                    order: 0,
                    typeIdentifier: "public.utf8-plain-text",
                    data: Data("Keep this clip".utf8)
                )
            ]
        )
    }

    private func assertRetentionProtection(for clipID: Clip.ID, databaseURL: URL) throws {
        let connection = try SQLiteConnection(databaseURL: databaseURL)
        let statement = try connection.prepare(
            "SELECT is_retention_protected FROM clips WHERE id = ?;"
        )
        try statement.bind(clipID.uuidString, at: 1)
        XCTAssertTrue(try statement.step())
        XCTAssertEqual(statement.integer(at: 0), 1)
    }
}

private struct CollectionDeletionTestContext {
    let directoryURL: URL
    let databaseURL: URL
    let repository: SQLiteClipRepository
}
