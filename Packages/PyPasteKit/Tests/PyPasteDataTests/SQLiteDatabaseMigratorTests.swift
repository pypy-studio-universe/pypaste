import Foundation
import PyPasteDomain
import XCTest

@testable import PyPasteData

final class SQLiteDatabaseMigratorTests: XCTestCase {
    func testAppliesEveryMigrationAndRemainsIdempotent() async throws {
        let databaseURL = temporaryDatabaseURL()
        defer { try? FileManager.default.removeItem(at: databaseURL.deletingLastPathComponent()) }

        let migrator = SQLiteDatabaseMigrator(databaseURL: databaseURL)

        try await migrator.migrate()
        try await migrator.migrate()

        let currentVersion = try await migrator.currentVersion()
        let hasClipsTable = try await migrator.hasTable(named: "clips")
        let hasRepresentationsTable = try await migrator.hasTable(named: "clip_representations")
        let hasCollectionsTable = try await migrator.hasTable(named: "collections")
        let hasMembershipsTable = try await migrator.hasTable(named: "clip_collections")

        XCTAssertEqual(currentVersion, DatabaseSchema.currentVersion)
        XCTAssertTrue(hasClipsTable)
        XCTAssertTrue(hasRepresentationsTable)
        XCTAssertTrue(hasCollectionsTable)
        XCTAssertTrue(hasMembershipsTable)
    }

    func testVersionFiveSeedsDefaultCollections() async throws {
        let databaseURL = temporaryDatabaseURL()
        defer { try? FileManager.default.removeItem(at: databaseURL.deletingLastPathComponent()) }
        let versionFourMigrator = SQLiteDatabaseMigrator(
            databaseURL: databaseURL,
            migrations: Array(DatabaseSchema.migrations.prefix(4))
        )
        try await versionFourMigrator.migrate()

        let currentMigrator = SQLiteDatabaseMigrator(databaseURL: databaseURL)
        try await currentMigrator.migrate()
        let repository = SQLiteClipRepository(databaseURL: databaseURL)
        let snapshot = try await repository.collectionSnapshot(
            selectedCollectionID: nil,
            limit: 10
        )

        XCTAssertEqual(
            snapshot.collections.map(\.name),
            ["Useful Links", "Important Notes", "Email Templates", "Code Snippets"]
        )
        XCTAssertEqual(Set(snapshot.collections.map(\.colorHex)).count, 4)
        let currentVersion = try await currentMigrator.currentVersion()
        XCTAssertEqual(currentVersion, 5)
    }

    func testRejectsAMigrationListWithMissingVersions() async throws {
        let databaseURL = temporaryDatabaseURL()
        defer { try? FileManager.default.removeItem(at: databaseURL.deletingLastPathComponent()) }

        let migrator = SQLiteDatabaseMigrator(
            databaseURL: databaseURL,
            migrations: [DatabaseMigration(version: 2, statements: [])]
        )

        do {
            try await migrator.migrate()
            XCTFail("Expected an invalid migration order error")
        } catch let error as SQLiteDatabaseError {
            XCTAssertEqual(error, .invalidMigrationOrder)
        }
    }

    func testVersionFourBackfillsStableOrderFromExistingRecency() async throws {
        let databaseURL = temporaryDatabaseURL()
        defer { try? FileManager.default.removeItem(at: databaseURL.deletingLastPathComponent()) }
        let versionThreeMigrator = SQLiteDatabaseMigrator(
            databaseURL: databaseURL,
            migrations: Array(DatabaseSchema.migrations.prefix(3))
        )
        try await versionThreeMigrator.migrate()

        let oldestID = UUID()
        let middleID = UUID()
        let newestID = UUID()
        let connection = try SQLiteConnection(databaseURL: databaseURL)
        try insertLegacyClip(
            id: oldestID,
            timestamp: 100,
            connection: connection
        )
        try insertLegacyClip(
            id: middleID,
            timestamp: 200,
            connection: connection
        )
        try insertLegacyClip(
            id: newestID,
            timestamp: 300,
            connection: connection
        )

        let currentMigrator = SQLiteDatabaseMigrator(databaseURL: databaseURL)
        try await currentMigrator.migrate()
        let repository = SQLiteClipRepository(databaseURL: databaseURL)

        let initialOrder = try await repository.recentClips(limit: 10).map(\.id)
        XCTAssertEqual(initialOrder, [newestID, middleID, oldestID])

        _ = try await repository.recordUse(
            id: oldestID,
            at: Date(timeIntervalSince1970: 1_000)
        )

        let orderAfterUse = try await repository.recentClips(limit: 10).map(\.id)
        let currentVersion = try await currentMigrator.currentVersion()
        XCTAssertEqual(orderAfterUse, [newestID, middleID, oldestID])
        XCTAssertEqual(currentVersion, DatabaseSchema.currentVersion)
    }

    private func temporaryDatabaseURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("PyPaste.sqlite")
    }

    private func insertLegacyClip(
        id: UUID,
        timestamp: TimeInterval,
        connection: SQLiteConnection
    ) throws {
        let statement = try connection.prepare(
            """
            INSERT INTO clips (
                id, created_at, updated_at, last_used_at, content_kind, display_title,
                content_hash
            ) VALUES (?, ?, ?, ?, ?, ?, ?);
            """
        )
        try statement.bind(id.uuidString, at: 1)
        try statement.bind(timestamp, at: 2)
        try statement.bind(timestamp, at: 3)
        try statement.bind(timestamp, at: 4)
        try statement.bind(ClipContentKind.text.rawValue, at: 5)
        try statement.bind("Legacy clip \(id.uuidString)", at: 6)
        try statement.bind("legacy-\(id.uuidString)", at: 7)
        _ = try statement.step()
    }
}
