public struct DatabaseMigration: Sendable {
    public let version: Int
    public let statements: [String]

    public init(version: Int, statements: [String]) {
        self.version = version
        self.statements = statements
    }
}
