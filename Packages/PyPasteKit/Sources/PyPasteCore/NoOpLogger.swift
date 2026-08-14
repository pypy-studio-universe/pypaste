import PyPasteDomain

public struct NoOpLogger: AppLogging, Sendable {
    public init() {}

    public func log(_ level: AppLogLevel, message: String) {}
}
