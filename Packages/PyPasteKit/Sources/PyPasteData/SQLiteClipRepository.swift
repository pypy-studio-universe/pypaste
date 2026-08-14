import Foundation
import PyPasteDomain

public actor SQLiteClipRepository: ClipCollectionManaging, ClipHistoryEditing, ClipRepository {
    let databaseURL: URL

    public init(databaseURL: URL) {
        self.databaseURL = databaseURL
    }

    public func save(
        _ clip: Clip,
        duplicatePolicy: DuplicatePolicy
    ) async throws -> ClipStoreResult {
        let connection = try SQLiteConnection(databaseURL: databaseURL)
        try connection.execute("BEGIN IMMEDIATE TRANSACTION;")

        do {
            let result: ClipStoreResult

            if duplicatePolicy == .moveExistingToTop,
                let existingID = try findExistingID(
                    contentHash: clip.contentHash, connection: connection)
            {
                try moveExistingClip(id: existingID, using: clip, connection: connection)

                guard let storedClip = try fetchClip(id: existingID, connection: connection) else {
                    throw SQLiteDatabaseError.queryFailed("Updated clip could not be reloaded")
                }

                result = ClipStoreResult(clip: storedClip, outcome: .movedExisting)
            } else {
                try insert(clip, connection: connection)

                guard let storedClip = try fetchClip(id: clip.id, connection: connection) else {
                    throw SQLiteDatabaseError.queryFailed("Inserted clip could not be reloaded")
                }

                result = ClipStoreResult(clip: storedClip, outcome: .inserted)
            }

            try connection.execute("COMMIT;")
            return result
        } catch {
            try? connection.execute("ROLLBACK;")
            throw error
        }
    }

    public func recentClips(limit: Int) async throws -> [Clip] {
        let connection = try SQLiteConnection(databaseURL: databaseURL)
        let statement = try connection.prepare(
            clipSelectSQL
                + " WHERE is_deleted = 0 ORDER BY \(canonicalOrderClause) LIMIT ?;"
        )
        try statement.bind(max(limit, 1), at: 1)
        var clips: [Clip] = []

        while try statement.step() {
            clips.append(try makeClip(from: statement, connection: connection))
        }

        return clips
    }

    public func clip(id: UUID) async throws -> Clip? {
        let connection = try SQLiteConnection(databaseURL: databaseURL)
        return try fetchClip(id: id, connection: connection)
    }

    public func recordUse(id: UUID, at date: Date) async throws -> Clip? {
        let connection = try SQLiteConnection(databaseURL: databaseURL)
        let statement = try connection.prepare(
            """
            UPDATE clips
            SET updated_at = ?, last_used_at = ?, copy_count = copy_count + 1
            WHERE id = ?;
            """
        )
        try statement.bind(date.timeIntervalSince1970, at: 1)
        try statement.bind(date.timeIntervalSince1970, at: 2)
        try statement.bind(id.uuidString, at: 3)
        _ = try statement.step()
        return try fetchClip(id: id, connection: connection)
    }

    public func move(
        id: UUID,
        relativeTo targetID: UUID,
        placement: ClipPlacement
    ) async throws {
        guard id != targetID else {
            return
        }

        let connection = try SQLiteConnection(databaseURL: databaseURL)
        try connection.execute("BEGIN IMMEDIATE TRANSACTION;")

        do {
            var orderedIDs = try fetchActiveClipIDs(connection: connection)

            guard
                let sourceIndex = orderedIDs.firstIndex(of: id),
                orderedIDs.contains(targetID)
            else {
                try connection.execute("COMMIT;")
                return
            }

            orderedIDs.remove(at: sourceIndex)

            guard let targetIndex = orderedIDs.firstIndex(of: targetID) else {
                try connection.execute("COMMIT;")
                return
            }

            let insertionIndex =
                switch placement {
                case .before:
                    targetIndex
                case .after:
                    orderedIDs.index(after: targetIndex)
                }
            orderedIDs.insert(id, at: insertionIndex)
            try persistSortRanks(for: orderedIDs, connection: connection)
            try connection.execute("COMMIT;")
        } catch {
            try? connection.execute("ROLLBACK;")
            throw error
        }
    }

    public func moveToTrash(id: UUID, at date: Date) async throws {
        let connection = try SQLiteConnection(databaseURL: databaseURL)
        let statement = try connection.prepare(
            """
            UPDATE clips
            SET updated_at = ?, is_deleted = 1, deleted_at = ?
            WHERE id = ? AND is_deleted = 0;
            """
        )
        try statement.bind(date.timeIntervalSince1970, at: 1)
        try statement.bind(date.timeIntervalSince1970, at: 2)
        try statement.bind(id.uuidString, at: 3)
        _ = try statement.step()
    }

}

extension SQLiteClipRepository {
    func findExistingID(
        contentHash: String,
        connection: SQLiteConnection
    ) throws -> UUID? {
        let statement = try connection.prepare(
            """
            SELECT id FROM clips
            WHERE content_hash = ? AND is_deleted = 0
            ORDER BY \(canonicalOrderClause) LIMIT 1;
            """
        )
        try statement.bind(contentHash, at: 1)

        guard try statement.step() else {
            return nil
        }

        return UUID(uuidString: statement.string(at: 0))
    }

    func moveExistingClip(
        id: UUID,
        using clip: Clip,
        connection: SQLiteConnection
    ) throws {
        let sortRank = try nextSortRank(connection: connection)
        let statement = try connection.prepare(
            """
            UPDATE clips
            SET updated_at = ?, last_used_at = ?, copy_count = copy_count + 1,
                source_bundle_id = ?, source_application_name = ?, sort_rank = ?
            WHERE id = ?;
            """
        )
        try statement.bind(clip.updatedAt.timeIntervalSince1970, at: 1)
        try statement.bind(clip.lastUsedAt.timeIntervalSince1970, at: 2)
        try statement.bind(clip.sourceApplication?.bundleIdentifier, at: 3)
        try statement.bind(clip.sourceApplication?.localizedName, at: 4)
        try statement.bind(sortRank, at: 5)
        try statement.bind(id.uuidString, at: 6)
        _ = try statement.step()
    }

    func insert(_ clip: Clip, connection: SQLiteConnection) throws {
        let sortRank = try nextSortRank(connection: connection)
        let statement = try connection.prepare(
            """
            INSERT INTO clips (
                id, created_at, updated_at, last_used_at, content_kind, display_title,
                searchable_text, source_bundle_id, source_application_name, content_hash,
                character_count, line_count, is_favorite, is_sensitive, is_deleted, copy_count,
                sort_rank
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, 0, 0, ?, ?);
            """
        )
        try statement.bind(clip.id.uuidString, at: 1)
        try statement.bind(clip.createdAt.timeIntervalSince1970, at: 2)
        try statement.bind(clip.updatedAt.timeIntervalSince1970, at: 3)
        try statement.bind(clip.lastUsedAt.timeIntervalSince1970, at: 4)
        try statement.bind(clip.contentKind.rawValue, at: 5)
        try statement.bind(clip.displayTitle, at: 6)
        try statement.bind(clip.searchableText, at: 7)
        try statement.bind(clip.sourceApplication?.bundleIdentifier, at: 8)
        try statement.bind(clip.sourceApplication?.localizedName, at: 9)
        try statement.bind(clip.contentHash, at: 10)
        try bindOptionalInteger(clip.characterCount, to: statement, at: 11)
        try bindOptionalInteger(clip.lineCount, to: statement, at: 12)
        try statement.bind(clip.copyCount, at: 13)
        try statement.bind(sortRank, at: 14)
        _ = try statement.step()

        for representation in clip.representations {
            try insert(representation, clipID: clip.id, connection: connection)
        }
    }

    func insert(
        _ representation: ClipRepresentation,
        clipID: UUID,
        connection: SQLiteConnection
    ) throws {
        let statement = try connection.prepare(
            """
            INSERT INTO clip_representations (
                id, clip_id, uti, storage_type, inline_data, byte_count,
                item_index, representation_index
            ) VALUES (?, ?, ?, 'inline', ?, ?, ?, ?);
            """
        )
        try statement.bind(UUID().uuidString, at: 1)
        try statement.bind(clipID.uuidString, at: 2)
        try statement.bind(representation.typeIdentifier, at: 3)
        try statement.bind(representation.data, at: 4)
        try statement.bind(representation.data.count, at: 5)
        try statement.bind(representation.itemIndex, at: 6)
        try statement.bind(representation.order, at: 7)
        _ = try statement.step()
    }

    func fetchClip(id: UUID, connection: SQLiteConnection) throws -> Clip? {
        let statement = try connection.prepare(clipSelectSQL + " WHERE id = ? LIMIT 1;")
        try statement.bind(id.uuidString, at: 1)

        guard try statement.step() else {
            return nil
        }

        return try makeClip(from: statement, connection: connection)
    }

    func makeClip(
        from statement: SQLiteStatement,
        connection: SQLiteConnection
    ) throws -> Clip {
        guard let id = UUID(uuidString: statement.string(at: 0)) else {
            throw SQLiteDatabaseError.queryFailed("Stored clip has an invalid UUID")
        }

        let sourceBundleID = statement.optionalString(at: 7)
        let sourceName = statement.optionalString(at: 8)
        let sourceApplication: SourceApplication? =
            if sourceBundleID != nil || sourceName != nil {
                SourceApplication(bundleIdentifier: sourceBundleID, localizedName: sourceName)
            } else {
                nil
            }

        return Clip(
            id: id,
            createdAt: Date(timeIntervalSince1970: statement.double(at: 1)),
            updatedAt: Date(timeIntervalSince1970: statement.double(at: 2)),
            lastUsedAt: Date(timeIntervalSince1970: statement.double(at: 3)),
            contentKind: ClipContentKind(rawValue: statement.string(at: 4)) ?? .unknown,
            displayTitle: statement.string(at: 5),
            searchableText: statement.optionalString(at: 6),
            sourceApplication: sourceApplication,
            contentHash: statement.string(at: 9),
            characterCount: statement.optionalInteger(at: 10),
            lineCount: statement.optionalInteger(at: 11),
            copyCount: statement.integer(at: 12),
            representations: try fetchRepresentations(clipID: id, connection: connection)
        )
    }

    func fetchRepresentations(
        clipID: UUID,
        connection: SQLiteConnection
    ) throws -> [ClipRepresentation] {
        let statement = try connection.prepare(
            """
            SELECT item_index, representation_index, uti, inline_data
            FROM clip_representations
            WHERE clip_id = ?
            ORDER BY item_index ASC, representation_index ASC;
            """
        )
        try statement.bind(clipID.uuidString, at: 1)
        var representations: [ClipRepresentation] = []

        while try statement.step() {
            representations.append(
                ClipRepresentation(
                    itemIndex: statement.integer(at: 0),
                    order: statement.integer(at: 1),
                    typeIdentifier: statement.string(at: 2),
                    data: statement.data(at: 3)
                ))
        }

        return representations
    }

    func fetchActiveClipIDs(connection: SQLiteConnection) throws -> [UUID] {
        let statement = try connection.prepare(
            """
            SELECT id
            FROM clips
            WHERE is_deleted = 0
            ORDER BY \(canonicalOrderClause);
            """
        )
        var ids: [UUID] = []

        while try statement.step() {
            guard let id = UUID(uuidString: statement.string(at: 0)) else {
                throw SQLiteDatabaseError.queryFailed("Stored clip has an invalid UUID")
            }

            ids.append(id)
        }

        return ids
    }

    func persistSortRanks(
        for orderedIDs: [UUID],
        connection: SQLiteConnection
    ) throws {
        for (index, id) in orderedIDs.enumerated() {
            let statement = try connection.prepare(
                "UPDATE clips SET sort_rank = ? WHERE id = ? AND is_deleted = 0;"
            )
            try statement.bind(orderedIDs.count - index, at: 1)
            try statement.bind(id.uuidString, at: 2)
            _ = try statement.step()
        }
    }

    func nextSortRank(connection: SQLiteConnection) throws -> Int {
        let statement = try connection.prepare(
            "SELECT COALESCE(MAX(sort_rank), 0) + 1 FROM clips WHERE is_deleted = 0;"
        )

        guard try statement.step() else {
            throw SQLiteDatabaseError.queryFailed("The next clip sort rank could not be read")
        }

        return statement.integer(at: 0)
    }

    func bindOptionalInteger(
        _ value: Int?,
        to statement: SQLiteStatement,
        at index: Int32
    ) throws {
        if let value {
            try statement.bind(value, at: index)
        } else {
            try statement.bindNull(at: index)
        }
    }

    var clipSelectSQL: String {
        """
        SELECT clips.id, clips.created_at, clips.updated_at,
               COALESCE(clips.last_used_at, clips.updated_at), clips.content_kind,
               clips.display_title, clips.searchable_text, clips.source_bundle_id,
               clips.source_application_name, clips.content_hash, clips.character_count,
               clips.line_count, clips.copy_count
        FROM clips
        """
    }

    var canonicalOrderClause: String {
        "clips.sort_rank DESC, COALESCE(clips.last_used_at, clips.updated_at) DESC, "
            + "clips.created_at DESC, clips.id ASC"
    }
}
