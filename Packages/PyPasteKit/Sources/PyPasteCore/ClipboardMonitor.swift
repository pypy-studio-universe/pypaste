import Foundation
import PyPasteDomain

@MainActor
public final class ClipboardMonitor {
    public struct Configuration: Equatable, Sendable {
        public let pollingInterval: Duration

        public init(pollingInterval: Duration = .milliseconds(350)) {
            self.pollingInterval = pollingInterval
        }

        public static let production = Configuration()
    }

    public private(set) var isPaused = false
    public private(set) var isSystemSleeping = false

    private let pasteboard: any PasteboardProviding
    private let captureHandler: any ClipboardCaptureHandling
    private let workspaceMonitor: any WorkspaceMonitoring
    private let logger: any AppLogging
    private let configuration: Configuration
    private let onClipCaptured: (ClipStoreResult) -> Void
    private var lastChangeCount: Int?
    private var pollingTask: Task<Void, Never>?
    private var isStarted = false

    public init(
        pasteboard: any PasteboardProviding,
        captureHandler: any ClipboardCaptureHandling,
        workspaceMonitor: any WorkspaceMonitoring,
        logger: any AppLogging,
        configuration: Configuration = .production,
        onClipCaptured: @escaping (ClipStoreResult) -> Void
    ) {
        self.pasteboard = pasteboard
        self.captureHandler = captureHandler
        self.workspaceMonitor = workspaceMonitor
        self.logger = logger
        self.configuration = configuration
        self.onClipCaptured = onClipCaptured
    }

    public func start() {
        guard !isStarted else {
            return
        }

        isStarted = true
        workspaceMonitor.onSleepStateChange = { [weak self] isSleeping in
            self?.setSystemSleeping(isSleeping)
        }
        workspaceMonitor.start()
        startPollingFromCurrentChangeCount()
        logger.notice("Clipboard monitoring started")
    }

    public func stop() {
        guard isStarted else {
            return
        }

        pollingTask?.cancel()
        pollingTask = nil
        workspaceMonitor.stop()
        isStarted = false
        logger.notice("Clipboard monitoring stopped")
    }

    public func pause() {
        guard !isPaused else {
            return
        }

        isPaused = true
        pollingTask?.cancel()
        pollingTask = nil
        logger.notice("Clipboard monitoring paused")
    }

    public func resume() {
        guard isPaused else {
            return
        }

        isPaused = false
        startPollingFromCurrentChangeCount()
        logger.notice("Clipboard monitoring resumed")
    }

    func pollOnce() async {
        guard isStarted, !isPaused, !isSystemSleeping else {
            return
        }

        let changeCount = await pasteboard.currentChangeCount()

        guard let lastChangeCount else {
            self.lastChangeCount = changeCount
            return
        }

        guard changeCount != lastChangeCount else {
            return
        }

        self.lastChangeCount = changeCount

        do {
            if let result = try await captureHandler.capture(
                observedChangeCount: changeCount,
                sourceApplication: workspaceMonitor.frontmostApplication
            ) {
                onClipCaptured(result)
            }
        } catch {
            logger.error("Clipboard capture failed: \(error.localizedDescription)")
        }
    }

    private func setSystemSleeping(_ isSleeping: Bool) {
        guard isSystemSleeping != isSleeping else {
            return
        }

        isSystemSleeping = isSleeping
        pollingTask?.cancel()
        pollingTask = nil

        if isSleeping {
            logger.notice("Clipboard monitoring suspended for system sleep")
        } else {
            startPollingFromCurrentChangeCount()
            logger.notice("Clipboard monitoring resumed after wake")
        }
    }

    private func startPollingFromCurrentChangeCount() {
        guard isStarted, !isPaused, !isSystemSleeping else {
            return
        }

        pollingTask?.cancel()
        pollingTask = Task { [weak self] in
            guard let self else {
                return
            }

            lastChangeCount = await pasteboard.currentChangeCount()

            while !Task.isCancelled {
                try? await Task.sleep(for: configuration.pollingInterval)

                if Task.isCancelled {
                    return
                }

                await pollOnce()
            }
        }
    }
}
