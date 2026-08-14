import Foundation
import PyPasteDomain
import SQLite3

public actor SQLiteDatabaseMigrator: DatabaseMigrating {
    private let databaseURL: URL
    private let migrations: [DatabaseMigration]

    public init(
        databaseURL: URL,
        migrations: [DatabaseMigration] = DatabaseSchema.migrations
    ) {
        self.databaseURL = databaseURL
        self.migrations = migrations
    }

    public func migrate() async throws {
        try validateMigrationOrder()

        try withConnection { connection in
            let installedVersion = try readCurrentVersion(from: connection)

            for migration in migrations where migration.version > installedVersion {
                try execute("BEGIN IMMEDIATE TRANSACTION;", on: connection)

                do {
                    for statement in migration.statements {
                        try execute(statement, on: connection)
                    }

                    try execute("PRAGMA user_version = \(migration.version);", on: connection)
                    try execute("COMMIT;", on: connection)
                } catch {
                    try? execute("ROLLBACK;", on: connection)
                    throw error
                }
            }
        }
    }

    public func currentVersion() async throws -> Int {
        try withConnection { connection in
            try readCurrentVersion(from: connection)
        }
    }

    public func hasTable(named tableName: String) async throws -> Bool {
        try withConnection { connection in
            let query = "SELECT COUNT(*) FROM sqlite_master WHERE type = 'table' AND name = ?;"
            var statement: OpaquePointer?

            guard sqlite3_prepare_v2(connection, query, -1, &statement, nil) == SQLITE_OK else {
                throw SQLiteDatabaseError.queryFailed(errorMessage(from: connection))
            }
            defer { sqlite3_finalize(statement) }

            guard sqlite3_bind_text(statement, 1, tableName, -1, sqliteTransient) == SQLITE_OK
            else {
                throw SQLiteDatabaseError.queryFailed(errorMessage(from: connection))
            }

            guard sqlite3_step(statement) == SQLITE_ROW else {
                throw SQLiteDatabaseError.queryFailed(errorMessage(from: connection))
            }

            return sqlite3_column_int(statement, 0) > 0
        }
    }

    private func validateMigrationOrder() throws {
        let versions = migrations.map(\.version)
        let expectedVersions = Array(1...migrations.count)

        guard versions == expectedVersions else {
            throw SQLiteDatabaseError.invalidMigrationOrder
        }
    }

    private func withConnection<Result>(
        _ operation: (OpaquePointer) throws -> Result
    ) throws -> Result {
        do {
            try FileManager.default.createDirectory(
                at: databaseURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
        } catch {
            throw SQLiteDatabaseError.cannotCreateParentDirectory(error.localizedDescription)
        }

        var optionalConnection: OpaquePointer?
        let flags = SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX
        let openResult = sqlite3_open_v2(databaseURL.path, &optionalConnection, flags, nil)

        guard openResult == SQLITE_OK, let connection = optionalConnection else {
            let message = errorMessage(from: optionalConnection)
            sqlite3_close(optionalConnection)
            throw SQLiteDatabaseError.cannotOpenDatabase(message)
        }
        defer { sqlite3_close(connection) }

        try execute("PRAGMA foreign_keys = ON;", on: connection)
        return try operation(connection)
    }

    private func readCurrentVersion(from connection: OpaquePointer) throws -> Int {
        var statement: OpaquePointer?

        guard
            sqlite3_prepare_v2(connection, "PRAGMA user_version;", -1, &statement, nil) == SQLITE_OK
        else {
            throw SQLiteDatabaseError.queryFailed(errorMessage(from: connection))
        }
        defer { sqlite3_finalize(statement) }

        guard sqlite3_step(statement) == SQLITE_ROW else {
            throw SQLiteDatabaseError.queryFailed(errorMessage(from: connection))
        }

        return Int(sqlite3_column_int(statement, 0))
    }

    private func execute(_ statement: String, on connection: OpaquePointer) throws {
        var errorPointer: UnsafeMutablePointer<CChar>?
        let result = sqlite3_exec(connection, statement, nil, nil, &errorPointer)

        guard result == SQLITE_OK else {
            let message: String

            if let errorPointer {
                message = String(cString: errorPointer)
                sqlite3_free(errorPointer)
            } else {
                message = errorMessage(from: connection)
            }

            throw SQLiteDatabaseError.executionFailed(statement: statement, message: message)
        }
    }

    private func errorMessage(from connection: OpaquePointer?) -> String {
        guard let connection else {
            return "Unknown SQLite error"
        }

        return String(cString: sqlite3_errmsg(connection))
    }
}

private let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
