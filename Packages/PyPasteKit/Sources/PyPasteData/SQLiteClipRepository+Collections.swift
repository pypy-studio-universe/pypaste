import Foundation
import PyPasteDomain

extension SQLiteClipRepository {
    public func collectionSnapshot(
        selectedCollectionID: ClipCollection.ID?,
        limit: Int
    ) async throws -> ClipCollectionSnapshot {
        let connection = try SQLiteConnection(databaseURL: databaseURL)
        let collections = try fetchCollections(connection: connection)
        let clips = try fetchClips(
            in: selectedCollectionID,
            limit: max(limit, 1),
            connection: connection
        )
        let memberships = try fetchCollectionMemberships(
            for: clips.map(\.id),
            connection: connection
        )
        return ClipCollectionSnapshot(
            collections: collections,
            clips: clips,
            collectionIDsByClipID: memberships
        )
    }

    public func createCollection(
        name: String,
        colorHex: String,
        at date: Date
    ) async throws -> ClipCollection {
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedName.isEmpty else {
            throw SQLiteDatabaseError.queryFailed("A collection name is required")
        }

        let connection = try SQLiteConnection(databaseURL: databaseURL)
        let collection = ClipCollection(
            name: normalizedName,
            colorHex: colorHex,
            sortOrder: try nextCollectionSortOrder(connection: connection),
            createdAt: date
        )
        let statement = try connection.prepare(
            """
            INSERT INTO collections (
                id, name, color_hex, sort_order, created_at, updated_at
            ) VALUES (?, ?, ?, ?, ?, ?);
            """
        )
        try statement.bind(collection.id.uuidString, at: 1)
        try statement.bind(collection.name, at: 2)
        try statement.bind(collection.colorHex, at: 3)
        try statement.bind(collection.sortOrder, at: 4)
        try statement.bind(date.timeIntervalSince1970, at: 5)
        try statement.bind(date.timeIntervalSince1970, at: 6)
        _ = try statement.step()
        return collection
    }

    public func addClip(
        id: Clip.ID,
        to collectionID: ClipCollection.ID,
        at date: Date
    ) async throws {
        let connection = try SQLiteConnection(databaseURL: databaseURL)
        try connection.execute("BEGIN IMMEDIATE TRANSACTION;")

        do {
            try insertMembership(
                clipID: id,
                collectionID: collectionID,
                date: date,
                connection: connection
            )
            try protectFromRetention(clipID: id, date: date, connection: connection)
            try connection.execute("COMMIT;")
        } catch {
            try? connection.execute("ROLLBACK;")
            throw error
        }
    }

    public func deleteCollection(id: ClipCollection.ID) async throws {
        let connection = try SQLiteConnection(databaseURL: databaseURL)
        let statement = try connection.prepare(
            "DELETE FROM collections WHERE id = ?;"
        )
        try statement.bind(id.uuidString, at: 1)
        _ = try statement.step()
    }
}

private extension SQLiteClipRepository {
    func fetchCollections(connection: SQLiteConnection) throws -> [ClipCollection] {
        let statement = try connection.prepare(
            """
            SELECT id, name, color_hex, sort_order, created_at
            FROM collections
            ORDER BY sort_order ASC, name COLLATE NOCASE ASC, id ASC;
            """
        )
        var collections: [ClipCollection] = []

        while try statement.step() {
            guard let id = UUID(uuidString: statement.string(at: 0)) else {
                throw SQLiteDatabaseError.queryFailed("Stored collection has an invalid UUID")
            }
            collections.append(
                ClipCollection(
                    id: id,
                    name: statement.string(at: 1),
                    colorHex: statement.string(at: 2),
                    sortOrder: statement.integer(at: 3),
                    createdAt: Date(timeIntervalSince1970: statement.double(at: 4))
                )
            )
        }
        return collections
    }

    func fetchClips(
        in collectionID: ClipCollection.ID?,
        limit: Int,
        connection: SQLiteConnection
    ) throws -> [Clip] {
        let sql: String
        if collectionID == nil {
            sql =
                clipSelectSQL
                + " WHERE clips.is_deleted = 0 ORDER BY \(canonicalOrderClause) LIMIT ?;"
        } else {
            sql =
                clipSelectSQL
                + " INNER JOIN clip_collections ON clip_collections.clip_id = clips.id"
                + " WHERE clips.is_deleted = 0 AND clip_collections.collection_id = ?"
                + " ORDER BY \(canonicalOrderClause) LIMIT ?;"
        }

        let statement = try connection.prepare(sql)
        var bindIndex: Int32 = 1
        if let collectionID {
            try statement.bind(collectionID.uuidString, at: bindIndex)
            bindIndex += 1
        }
        try statement.bind(limit, at: bindIndex)
        var clips: [Clip] = []
        while try statement.step() {
            clips.append(try makeClip(from: statement, connection: connection))
        }
        return clips
    }

    func fetchCollectionMemberships(
        for clipIDs: [Clip.ID],
        connection: SQLiteConnection
    ) throws -> [Clip.ID: Set<ClipCollection.ID>] {
        guard !clipIDs.isEmpty else {
            return [:]
        }

        let placeholders = Array(repeating: "?", count: clipIDs.count).joined(separator: ", ")
        let statement = try connection.prepare(
            """
            SELECT clip_id, collection_id
            FROM clip_collections
            WHERE clip_id IN (\(placeholders));
            """
        )
        for (index, clipID) in clipIDs.enumerated() {
            try statement.bind(clipID.uuidString, at: Int32(index + 1))
        }
        var memberships: [Clip.ID: Set<ClipCollection.ID>] = [:]
        while try statement.step() {
            guard
                let clipID = UUID(uuidString: statement.string(at: 0)),
                let collectionID = UUID(uuidString: statement.string(at: 1))
            else {
                throw SQLiteDatabaseError.queryFailed("Stored collection membership is invalid")
            }
            memberships[clipID, default: []].insert(collectionID)
        }
        return memberships
    }

    func insertMembership(
        clipID: Clip.ID,
        collectionID: ClipCollection.ID,
        date: Date,
        connection: SQLiteConnection
    ) throws {
        let statement = try connection.prepare(
            """
            INSERT OR IGNORE INTO clip_collections (
                clip_id, collection_id, created_at
            ) VALUES (?, ?, ?);
            """
        )
        try statement.bind(clipID.uuidString, at: 1)
        try statement.bind(collectionID.uuidString, at: 2)
        try statement.bind(date.timeIntervalSince1970, at: 3)
        _ = try statement.step()
    }

    func protectFromRetention(
        clipID: Clip.ID,
        date: Date,
        connection: SQLiteConnection
    ) throws {
        let statement = try connection.prepare(
            """
            UPDATE clips
            SET is_retention_protected = 1, updated_at = ?
            WHERE id = ? AND is_deleted = 0;
            """
        )
        try statement.bind(date.timeIntervalSince1970, at: 1)
        try statement.bind(clipID.uuidString, at: 2)
        _ = try statement.step()
    }

    func nextCollectionSortOrder(connection: SQLiteConnection) throws -> Int {
        let statement = try connection.prepare(
            "SELECT COALESCE(MAX(sort_order), 0) + 10 FROM collections;"
        )
        guard try statement.step() else {
            throw SQLiteDatabaseError.queryFailed("The next collection order could not be read")
        }
        return statement.integer(at: 0)
    }
}
