import AppKit
import PyPasteCore
import PyPasteDomain
import PyPasteSharedUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var appCoordinator: AppCoordinator?
    private var migrationTask: Task<Void, Never>?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let launchContext = AppLaunchContext()

        guard !launchContext.isHostedUnitTest else {
            return
        }

        do {
            let dependencies = try DependencyContainer.live()
            let pasteCoordinator: any PasteCoordinating =
                launchContext.isUITesting ? UITestPasteCoordinator() : SystemPasteCoordinator()
            let screenshotClipboardService: (any ScreenshotClipboardCapturing)? =
                launchContext.isUITesting
                ? nil : ScreenshotClipboardService(logger: dependencies.logger)
            let coordinator = AppCoordinator(
                dependencies: dependencies,
                pasteCoordinator: pasteCoordinator,
                screenshotClipboardService: screenshotClipboardService
            )

            appCoordinator = coordinator
            coordinator.start()

            if launchContext.isUITesting {
                coordinator.showMainWindow()
            }

            migrationTask = Task {
                do {
                    try await dependencies.databaseMigrator.migrate()
                    let version = try await dependencies.databaseMigrator.currentVersion()
                    dependencies.logger.notice("Database migration completed at version \(version)")
                    await coordinator.startClipboardCapture()
                } catch {
                    dependencies.logger.fault(
                        "Database migration failed: \(error.localizedDescription)")
                }
            }
        } catch {
            presentStartupError(error)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationDidResignActive(_ notification: Notification) {
        appCoordinator?.applicationDidResignActive()
    }

    func applicationWillTerminate(_ notification: Notification) {
        migrationTask?.cancel()
        appCoordinator?.stop()
    }

    private func presentStartupError(_ error: Error) {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = AppLocalization.shared.text(.startFailure)
        alert.informativeText = error.localizedDescription
        alert.runModal()
        NSApp.terminate(nil)
    }
}

struct AppLaunchContext: Equatable {
    let isUITesting: Bool
    let isHostedUnitTest: Bool

    init(
        arguments: [String] = CommandLine.arguments,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) {
        isUITesting = arguments.contains("--ui-testing")
        isHostedUnitTest =
            !isUITesting
            && environment["XCTestBundlePath"] != nil
            && environment["XCInjectBundleInto"] != nil
    }
}

@MainActor
private final class UITestPasteCoordinator: PasteCoordinating {
    func paste(to _: PasteTarget?) async -> PasteResult {
        .targetUnavailable
    }
}
