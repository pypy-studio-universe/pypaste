import AppKit
import PyPasteCore
import PyPasteDomain
import PyPasteFeatures
import PyPasteSharedUI

@MainActor
final class AppCoordinator {
    private static let pasteEventDeliveryGracePeriod = Duration.milliseconds(120)

    let dependencies: DependencyContainer
    private let shortcutMonitor: any GlobalShortcutMonitoring
    private let pasteCoordinator: any PasteCoordinating
    private let screenshotClipboardService: (any ScreenshotClipboardCapturing)?
    let localization: AppLocalization
    private var pasteTarget: PasteTarget?
    private var isQuickBarPresented = false
    private var historyMutationRevision = 0
    private var historyMutationTask: Task<Void, Never>?
    var collectionViewRevision = 0
    var clipboardCollectionSnapshot = ClipCollectionSnapshot(
        collections: [],
        clips: [],
        collectionIDsByClipID: [:]
    )
    lazy var historyModel = MainHistoryModel(
        onCopy: { [weak self] clip in
            self?.copy(clip)
        },
        onToggleMonitoring: { [weak self] in
            self?.toggleMonitoring()
        },
        onMove: { [weak self] clipID, targetID, placement in
            self?.moveClip(clipID, relativeTo: targetID, placement: placement)
        },
        onDelete: { [weak self] clipID in
            self?.moveClipToTrash(clipID)
        }
    )
    private lazy var mainWindowController = MainWindowController(
        model: historyModel,
        localization: localization
    )
    lazy var quickBarModel = QuickBarModel(
        onPaste: { [weak self] clip in
            self?.paste(clip)
        },
        onDismiss: { [weak self] in
            self?.dismissQuickBar()
        },
        onMove: { [weak self] clipID, targetID, placement in
            self?.moveClip(clipID, relativeTo: targetID, placement: placement)
        },
        onDelete: { [weak self] clipID in
            self?.moveClipToTrash(clipID)
        },
        onSelectCollection: { [weak self] collectionID in
            self?.selectCollection(collectionID)
        },
        onAddToCollection: { [weak self] clipID, collectionID in
            self?.addClip(clipID, to: collectionID)
        },
        onCreateCollection: { [weak self] name, colorHex in
            self?.createCollection(name: name, colorHex: colorHex)
        },
        onDeleteCollection: { [weak self] collectionID in
            self?.deleteCollection(collectionID)
        },
        localization: localization
    )
    private lazy var quickBarPanelController = QuickBarPanelController(
        model: quickBarModel,
        logger: dependencies.logger,
        localization: localization
    )
    private lazy var statusItemController = StatusItemController(
        openMainWindow: { [weak self] in
            self?.showMainWindow()
        },
        showQuickBar: { [weak self] in
            self?.showQuickBar()
        },
        toggleMonitoring: { [weak self] in
            self?.toggleMonitoring()
        },
        terminateApplication: {
            NSApp.terminate(nil)
        },
        localization: localization
    )
    private lazy var captureEngine = ClipboardCaptureEngine(
        pasteboard: dependencies.pasteboard,
        processor: ClipboardContentProcessor(),
        repository: dependencies.clipRepository,
        duplicatePolicyProvider: dependencies.duplicatePolicyProvider,
        logger: dependencies.logger
    )
    private lazy var workspaceMonitor = SystemWorkspaceMonitor()
    private lazy var clipboardMonitor = ClipboardMonitor(
        pasteboard: dependencies.pasteboard,
        captureHandler: captureEngine,
        workspaceMonitor: workspaceMonitor,
        logger: dependencies.logger,
        onClipCaptured: { [weak self] _ in
            self?.refreshHistoryAfterCapture()
        }
    )

    init(
        dependencies: DependencyContainer,
        shortcutMonitor: any GlobalShortcutMonitoring = CarbonGlobalShortcutMonitor(),
        pasteCoordinator: any PasteCoordinating = SystemPasteCoordinator(),
        screenshotClipboardService: (any ScreenshotClipboardCapturing)? = nil,
        localization: AppLocalization = .shared
    ) {
        self.dependencies = dependencies
        self.shortcutMonitor = shortcutMonitor
        self.pasteCoordinator = pasteCoordinator
        self.screenshotClipboardService = screenshotClipboardService
        self.localization = localization
    }

    func start() {
        NSApp.setActivationPolicy(.accessory)
        statusItemController.start()
        registerGlobalShortcut()
        dependencies.logger.notice("Application coordinator started")
    }

    func startClipboardCapture() async {
        do {
            let snapshot = try await dependencies.clipCollectionManager.collectionSnapshot(
                selectedCollectionID: nil,
                limit: 200
            )
            clipboardCollectionSnapshot = snapshot
            historyModel.replaceClips(snapshot.clips)
            quickBarModel.prepareForPresentation(with: snapshot)
            clipboardMonitor.start()
            screenshotClipboardService?.start()
        } catch {
            dependencies.logger.error(
                "Clipboard capture startup failed: \(error.localizedDescription)"
            )
        }
    }

    func showMainWindow() {
        dismissQuickBar()
        mainWindowController.showWindow()
        dependencies.logger.info("Main window opened")
    }

    func applicationDidResignActive() {
        dismissQuickBar()
    }

    func stop() {
        historyMutationRevision &+= 1
        collectionViewRevision &+= 1
        historyMutationTask?.cancel()
        historyMutationTask = nil
        shortcutMonitor.stop()
        clipboardMonitor.stop()
        screenshotClipboardService?.stop()
        dismissQuickBar()
    }

    private func registerGlobalShortcut() {
        do {
            try shortcutMonitor.start { [weak self] in
                self?.showQuickBar()
            }
            dependencies.logger.notice(
                "Global shortcut registered: \(shortcutMonitor.displayName)"
            )
        } catch {
            dependencies.logger.error(
                "Global shortcut registration failed: \(error.localizedDescription)"
            )
        }
    }

    private func toggleMonitoring() {
        if clipboardMonitor.isPaused {
            clipboardMonitor.resume()
            screenshotClipboardService?.start()
        } else {
            clipboardMonitor.pause()
            screenshotClipboardService?.stop()
        }

        let isPaused = clipboardMonitor.isPaused
        historyModel.setMonitoringPaused(isPaused)
        statusItemController.setMonitoringPaused(isPaused)
    }

    private func showQuickBar() {
        if isQuickBarPresented {
            quickBarPanelController.bringToFrontWhileVisible()
            return
        }

        pasteTarget = currentPasteTarget()
        quickBarModel.prepareForPresentation(with: clipboardCollectionSnapshot)
        quickBarPanelController.show()
        isQuickBarPresented = true
        dependencies.logger.info("Bottom Quick Bar opened")
    }

    private func dismissQuickBar() {
        guard isQuickBarPresented else {
            return
        }

        isQuickBarPresented = false
        quickBarPanelController.hide()
        quickBarModel.completePaste()
        pasteTarget = nil
    }

    private func copy(_ clip: Clip) {
        Task { [weak self] in
            guard let self else {
                return
            }

            do {
                if let updatedClip = try await captureEngine.copy(clip) {
                    historyModel.update(updatedClip)
                    quickBarModel.update(updatedClip)
                }
            } catch {
                dependencies.logger.error(
                    "Copying a stored clip failed: \(error.localizedDescription)")
            }
        }
    }

    private func paste(_ clip: Clip) {
        let target = currentPasteTarget() ?? pasteTarget
        pasteTarget = target

        Task { [weak self] in
            guard let self else {
                return
            }

            do {
                if let updatedClip = try await captureEngine.copy(clip) {
                    historyModel.update(updatedClip)
                    quickBarModel.update(updatedClip)
                }

                let result = await pasteCoordinator.paste(to: target)
                if result == .pasted {
                    try? await Task.sleep(for: Self.pasteEventDeliveryGracePeriod)
                }
                handlePasteResult(result)
            } catch {
                quickBarModel.completePaste(
                    feedbackMessage: localization.text(.copyFailed)
                )
                dependencies.logger.error(
                    "Quick Bar paste failed while writing clipboard: \(error.localizedDescription)"
                )
            }
        }
    }

}

private extension AppCoordinator {
    func refreshHistoryAfterCapture() {
        let revision = beginHistoryMutation()
        let precedingTask = historyMutationTask
        historyMutationTask = Task { [weak self] in
            await precedingTask?.value
            guard let self, !Task.isCancelled else {
                return
            }

            do {
                try await reloadHistory(ifCurrent: revision)
            } catch {
                let message = error.localizedDescription
                dependencies.logger.error(
                    "Reloading clipboard history after capture failed: \(message)"
                )
            }
        }
    }

    func moveClip(
        _ clipID: Clip.ID,
        relativeTo targetID: Clip.ID,
        placement: ClipPlacement
    ) {
        let revision = beginHistoryMutation()
        let precedingTask = historyMutationTask
        historyMutationTask = Task { [weak self] in
            await precedingTask?.value
            guard let self, !Task.isCancelled else {
                return
            }

            do {
                try await dependencies.clipHistoryEditor.move(
                    id: clipID,
                    relativeTo: targetID,
                    placement: placement
                )
                try await reloadHistory(ifCurrent: revision)
                dependencies.logger.info("Updated clipboard history display order")
            } catch {
                await reloadHistoryAfterEditingFailure(
                    message: "Reordering clipboard history failed",
                    error: error,
                    revision: revision
                )
            }
        }
    }

    func moveClipToTrash(_ clipID: Clip.ID) {
        let revision = beginHistoryMutation()
        let precedingTask = historyMutationTask
        historyMutationTask = Task { [weak self] in
            await precedingTask?.value
            guard let self, !Task.isCancelled else {
                return
            }

            do {
                try await dependencies.clipHistoryEditor.moveToTrash(id: clipID, at: Date())
                try await reloadHistory(ifCurrent: revision)
                dependencies.logger.info("Moved a clipboard history item to Trash")
            } catch {
                await reloadHistoryAfterEditingFailure(
                    message: "Deleting a clipboard history item failed",
                    error: error,
                    revision: revision
                )
            }
        }
    }

    func beginHistoryMutation() -> Int {
        historyMutationRevision &+= 1
        return historyMutationRevision
    }

    func reloadHistory(ifCurrent revision: Int) async throws {
        guard revision == historyMutationRevision else {
            return
        }

        let clipboardSnapshot = try await dependencies.clipCollectionManager.collectionSnapshot(
            selectedCollectionID: nil,
            limit: 200
        )

        guard revision == historyMutationRevision else {
            return
        }

        clipboardCollectionSnapshot = clipboardSnapshot
        historyModel.replaceClips(clipboardSnapshot.clips)

        if quickBarModel.selectedCollectionID == nil {
            quickBarModel.applyCollectionSnapshot(clipboardSnapshot, for: nil)
        } else {
            refreshSelectedCollection()
        }
    }

    func reloadHistoryAfterEditingFailure(
        message: String,
        error: Error,
        revision: Int
    ) async {
        do {
            try await reloadHistory(ifCurrent: revision)
        } catch {
            dependencies.logger.error(
                "Reloading clipboard history after an edit failed: \(error.localizedDescription)"
            )
        }

        guard revision == historyMutationRevision else {
            return
        }

        quickBarModel.completePaste(feedbackMessage: localization.text(.historyUpdateFailed))
        dependencies.logger.error("\(message): \(error.localizedDescription)")
    }
}
