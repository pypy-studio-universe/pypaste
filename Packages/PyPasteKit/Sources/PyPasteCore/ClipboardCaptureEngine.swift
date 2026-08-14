import Foundation
import PyPasteDomain

public actor ClipboardCaptureEngine: ClipboardCaptureHandling {
    private let pasteboard: any PasteboardProviding
    private let processor: any ClipboardContentProcessing
    private let repository: any ClipRepository
    private let duplicatePolicyProvider: any DuplicatePolicyProviding
    private let logger: any AppLogging
    private var suppressedChangeCounts: Set<Int> = []

    public init(
        pasteboard: any PasteboardProviding,
        processor: any ClipboardContentProcessing,
        repository: any ClipRepository,
        duplicatePolicyProvider: any DuplicatePolicyProviding,
        logger: any AppLogging
    ) {
        self.pasteboard = pasteboard
        self.processor = processor
        self.repository = repository
        self.duplicatePolicyProvider = duplicatePolicyProvider
        self.logger = logger
    }

    public func capture(
        observedChangeCount: Int,
        sourceApplication: SourceApplication?
    ) async throws -> ClipStoreResult? {
        if suppressedChangeCounts.remove(observedChangeCount) != nil {
            logger.debug("Ignored an expected PyPaste pasteboard write")
            return nil
        }

        let snapshot = try await pasteboard.snapshot()

        guard snapshot.changeCount == observedChangeCount else {
            logger.debug("Clipboard changed again before capture completed; retrying next poll")
            return nil
        }

        if snapshot.containsInternalMarker {
            suppressedChangeCounts.remove(snapshot.changeCount)
            logger.debug("Ignored a pasteboard item carrying the PyPaste marker")
            return nil
        }

        guard
            let clip = await processor.makeClip(
                from: snapshot,
                sourceApplication: sourceApplication
            )
        else {
            logger.debug("Ignored an empty clipboard snapshot")
            return nil
        }

        let duplicatePolicy = await duplicatePolicyProvider.duplicatePolicy()
        let result = try await repository.save(clip, duplicatePolicy: duplicatePolicy)
        logger.info(
            "Captured clipboard metadata: kind=\(result.clip.contentKind.rawValue), "
                + "items=\(snapshot.items.count), outcome=\(String(describing: result.outcome))"
        )
        return result
    }

    public func copy(_ clip: Clip) async throws -> Clip? {
        let marker = UUID()
        let changeCount = try await pasteboard.write(items: clip.pasteboardItems, marker: marker)
        suppress(changeCount: changeCount)
        logger.info("Wrote a stored clip to the pasteboard")
        return try await repository.recordUse(id: clip.id, at: Date())
    }

    private func suppress(changeCount: Int) {
        if suppressedChangeCounts.count >= 32 {
            suppressedChangeCounts.removeAll(keepingCapacity: true)
        }

        suppressedChangeCounts.insert(changeCount)
    }
}
