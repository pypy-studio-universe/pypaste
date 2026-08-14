public protocol DatabaseMigrating: Sendable {
    func migrate() async throws
    func currentVersion() async throws -> Int
}
