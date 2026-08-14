public enum AppLogLevel: Sendable {
    case debug
    case info
    case notice
    case error
    case fault
}

public protocol AppLogging: Sendable {
    func log(_ level: AppLogLevel, message: String)
}

extension AppLogging {
    public func debug(_ message: String) {
        log(.debug, message: message)
    }

    public func info(_ message: String) {
        log(.info, message: message)
    }

    public func notice(_ message: String) {
        log(.notice, message: message)
    }

    public func error(_ message: String) {
        log(.error, message: message)
    }

    public func fault(_ message: String) {
        log(.fault, message: message)
    }
}
