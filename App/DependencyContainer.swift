import Foundation
import PyPasteCore
import PyPasteData
import PyPasteDomain

struct DependencyContainer {
    let logger: any AppLogging
    let databaseMigrator: any DatabaseMigrating
    let clipRepository: any ClipRepository
    let clipHistoryEditor: any ClipHistoryEditing
    let clipCollectionManager: any ClipCollectionManaging
    let pasteboard: any PasteboardProviding
    let duplicatePolicyProvider: any DuplicatePolicyProviding

    static func live(fileManager: FileManager = .default) throws -> DependencyContainer {
        let isUITesting = CommandLine.arguments.contains("--ui-testing")
        let databaseURL = try makeDatabaseURL(fileManager: fileManager, isUITesting: isUITesting)
        let logger = OSAppLogger(subsystem: "com.pypaste.app", category: "Application")
        let clipRepository = SQLiteClipRepository(databaseURL: databaseURL)

        return DependencyContainer(
            logger: logger,
            databaseMigrator: SQLiteDatabaseMigrator(databaseURL: databaseURL),
            clipRepository: clipRepository,
            clipHistoryEditor: clipRepository,
            clipCollectionManager: clipRepository,
            pasteboard: SystemPasteboard(
                name: isUITesting ? "com.pypaste.ui-tests" : nil
            ),
            duplicatePolicyProvider: UserDefaultsDuplicatePolicyProvider()
        )
    }

    static func testing(databaseURL: URL) -> DependencyContainer {
        let clipRepository = SQLiteClipRepository(databaseURL: databaseURL)

        return DependencyContainer(
            logger: NoOpLogger(),
            databaseMigrator: SQLiteDatabaseMigrator(databaseURL: databaseURL),
            clipRepository: clipRepository,
            clipHistoryEditor: clipRepository,
            clipCollectionManager: clipRepository,
            pasteboard: SystemPasteboard(),
            duplicatePolicyProvider: UserDefaultsDuplicatePolicyProvider(
                suiteName: "PyPasteTests.\(UUID().uuidString)"
            )
        )
    }

    private static func makeDatabaseURL(
        fileManager: FileManager,
        isUITesting: Bool
    ) throws -> URL {
        if isUITesting {
            return fileManager.temporaryDirectory
                .appendingPathComponent("PyPasteUITests", isDirectory: true)
                .appendingPathComponent(String(ProcessInfo.processInfo.processIdentifier))
                .appendingPathComponent("PyPaste.sqlite")
        }

        guard
            let applicationSupportURL = fileManager.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first
        else {
            throw DependencyContainerError.applicationSupportDirectoryUnavailable
        }

        return
            applicationSupportURL
            .appendingPathComponent("PyPaste", isDirectory: true)
            .appendingPathComponent("PyPaste.sqlite")
    }
}

enum DependencyContainerError: LocalizedError {
    case applicationSupportDirectoryUnavailable

    var errorDescription: String? {
        switch self {
        case .applicationSupportDirectoryUnavailable:
            "The Application Support directory is unavailable."
        }
    }
}
