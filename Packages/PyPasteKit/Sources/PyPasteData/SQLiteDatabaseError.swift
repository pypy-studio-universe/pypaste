public enum SQLiteDatabaseError: Error, Equatable, Sendable {
    case cannotCreateParentDirectory(String)
    case cannotOpenDatabase(String)
    case executionFailed(statement: String, message: String)
    case queryFailed(String)
    case invalidMigrationOrder
}
