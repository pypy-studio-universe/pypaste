import Foundation
import SQLite3

final class SQLiteConnection {
    let handle: OpaquePointer

    init(databaseURL: URL) throws {
        do {
            try FileManager.default.createDirectory(
                at: databaseURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
        } catch {
            throw SQLiteDatabaseError.cannotCreateParentDirectory(error.localizedDescription)
        }

        var optionalHandle: OpaquePointer?
        let flags = SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX
        let openResult = sqlite3_open_v2(databaseURL.path, &optionalHandle, flags, nil)

        guard openResult == SQLITE_OK, let handle = optionalHandle else {
            let message =
                optionalHandle.map { String(cString: sqlite3_errmsg($0)) }
                ?? "Unknown SQLite error"
            sqlite3_close(optionalHandle)
            throw SQLiteDatabaseError.cannotOpenDatabase(message)
        }

        self.handle = handle
        try execute("PRAGMA foreign_keys = ON;")
    }

    deinit {
        sqlite3_close(handle)
    }

    func execute(_ sql: String) throws {
        var errorPointer: UnsafeMutablePointer<CChar>?
        let result = sqlite3_exec(handle, sql, nil, nil, &errorPointer)

        guard result == SQLITE_OK else {
            let message: String

            if let errorPointer {
                message = String(cString: errorPointer)
                sqlite3_free(errorPointer)
            } else {
                message = errorMessage
            }

            throw SQLiteDatabaseError.executionFailed(statement: sql, message: message)
        }
    }

    func prepare(_ sql: String) throws -> SQLiteStatement {
        var optionalStatement: OpaquePointer?

        guard sqlite3_prepare_v2(handle, sql, -1, &optionalStatement, nil) == SQLITE_OK,
            let statement = optionalStatement
        else {
            throw SQLiteDatabaseError.queryFailed(errorMessage)
        }

        return SQLiteStatement(handle: statement, connection: self)
    }

    var errorMessage: String {
        String(cString: sqlite3_errmsg(handle))
    }
}

final class SQLiteStatement {
    private let handle: OpaquePointer
    private let connection: SQLiteConnection

    init(handle: OpaquePointer, connection: SQLiteConnection) {
        self.handle = handle
        self.connection = connection
    }

    deinit {
        sqlite3_finalize(handle)
    }

    func bind(_ value: String?, at index: Int32) throws {
        let result: Int32

        if let value {
            result = sqlite3_bind_text(handle, index, value, -1, sqliteStatementTransient)
        } else {
            result = sqlite3_bind_null(handle, index)
        }

        try validate(result)
    }

    func bind(_ value: Int, at index: Int32) throws {
        try validate(sqlite3_bind_int64(handle, index, Int64(value)))
    }

    func bind(_ value: Double, at index: Int32) throws {
        try validate(sqlite3_bind_double(handle, index, value))
    }

    func bind(_ value: Data, at index: Int32) throws {
        let result = value.withUnsafeBytes { buffer in
            sqlite3_bind_blob(
                handle,
                index,
                buffer.baseAddress,
                Int32(buffer.count),
                sqliteStatementTransient
            )
        }
        try validate(result)
    }

    func bindNull(at index: Int32) throws {
        try validate(sqlite3_bind_null(handle, index))
    }

    func step() throws -> Bool {
        let result = sqlite3_step(handle)

        switch result {
        case SQLITE_ROW:
            return true
        case SQLITE_DONE:
            return false
        default:
            throw SQLiteDatabaseError.queryFailed(connection.errorMessage)
        }
    }

    func string(at index: Int32) -> String {
        guard let pointer = sqlite3_column_text(handle, index) else {
            return ""
        }

        return String(cString: pointer)
    }

    func optionalString(at index: Int32) -> String? {
        guard sqlite3_column_type(handle, index) != SQLITE_NULL else {
            return nil
        }

        return string(at: index)
    }

    func integer(at index: Int32) -> Int {
        Int(sqlite3_column_int64(handle, index))
    }

    func optionalInteger(at index: Int32) -> Int? {
        guard sqlite3_column_type(handle, index) != SQLITE_NULL else {
            return nil
        }

        return integer(at: index)
    }

    func double(at index: Int32) -> Double {
        sqlite3_column_double(handle, index)
    }

    func data(at index: Int32) -> Data {
        let count = Int(sqlite3_column_bytes(handle, index))

        guard count > 0, let bytes = sqlite3_column_blob(handle, index) else {
            return Data()
        }

        return Data(bytes: bytes, count: count)
    }

    private func validate(_ result: Int32) throws {
        guard result == SQLITE_OK else {
            throw SQLiteDatabaseError.queryFailed(connection.errorMessage)
        }
    }
}

private let sqliteStatementTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
