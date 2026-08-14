import OSLog
import PyPasteDomain

public struct OSAppLogger: AppLogging, Sendable {
    private let logger: Logger

    public init(subsystem: String, category: String) {
        logger = Logger(subsystem: subsystem, category: category)
    }

    public func log(_ level: AppLogLevel, message: String) {
        switch level {
        case .debug:
            logger.debug("\(message, privacy: .public)")
        case .info:
            logger.info("\(message, privacy: .public)")
        case .notice:
            logger.notice("\(message, privacy: .public)")
        case .error:
            logger.error("\(message, privacy: .public)")
        case .fault:
            logger.fault("\(message, privacy: .public)")
        }
    }
}
