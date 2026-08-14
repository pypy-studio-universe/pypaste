import Foundation
import PyPasteDomain
import UniformTypeIdentifiers
import XCTest

@testable import PyPasteCore

final class ClipboardCaptureEngineTests: XCTestCase {
    @MainActor
    func testCommandShiftVGlobalShortcutRegistersAndInvokesAction() throws {
        let monitor = CarbonGlobalShortcutMonitor()
        var invocationCount = 0

        try monitor.start {
            invocationCount += 1
        }
        defer { monitor.stop() }

        XCTAssertTrue(monitor.isRegistered)
        XCTAssertEqual(monitor.displayName, "⌘⇧V")

        monitor.handleKeyPress()

        XCTAssertEqual(invocationCount, 1)
    }

    func testCanonicalSHA256NormalizesTextAndPreservesItemOrder() {
        let hasher = SHA256CanonicalHasher()
        let windowsNewlines = [item(index: 0, text: "hello\r\nworld")]
        let unixNewlines = [item(index: 0, text: "hello\nworld")]
        let reversedItems = [item(index: 0, text: "world"), item(index: 1, text: "hello")]
        let originalItems = [item(index: 0, text: "hello"), item(index: 1, text: "world")]

        XCTAssertEqual(hasher.hash(items: windowsNewlines), hasher.hash(items: unixNewlines))
        XCTAssertNotEqual(hasher.hash(items: originalItems), hasher.hash(items: reversedItems))
        XCTAssertEqual(hasher.hash(items: originalItems).count, 64)
    }

    func testProcessorKeepsEveryItemAndRepresentationInOrder() async throws {
        let processor = ClipboardContentProcessor()
        let firstItem = ClipboardItemSnapshot(
            index: 0,
            representations: [
                representation(text: "first"),
                ClipboardRepresentationSnapshot(
                    typeIdentifier: UTType.html.identifier,
                    data: Data("<b>first</b>".utf8)
                ),
            ]
        )
        let secondItem = item(index: 1, text: "second")
        let snapshot = ClipboardSnapshot(changeCount: 1, items: [secondItem, firstItem])

        let clip = await processor.makeClip(from: snapshot, sourceApplication: nil)

        let storedClip = try XCTUnwrap(clip)
        let storedOrder = storedClip.representations.map {
            ($0.itemIndex, $0.order, $0.typeIdentifier)
        }
        XCTAssertEqual(storedOrder.map(\.0), [0, 0, 1])
        XCTAssertEqual(storedOrder.map(\.1), [0, 1, 0])
        XCTAssertEqual(storedClip.pasteboardItems.map(\.index), [0, 1])
    }

    func testCopyWritesEveryItemAndRepresentationInExactOrder() async throws {
        let dependencies = makeDependencies()
        let clip = Clip(
            contentKind: .richText,
            displayTitle: "Ordered copy",
            contentHash: "ordered-copy",
            representations: [
                ClipRepresentation(
                    itemIndex: 0,
                    order: 0,
                    typeIdentifier: UTType.utf8PlainText.identifier,
                    data: Data("first-text".utf8)
                ),
                ClipRepresentation(
                    itemIndex: 0,
                    order: 1,
                    typeIdentifier: UTType.html.identifier,
                    data: Data("<b>first</b>".utf8)
                ),
                ClipRepresentation(
                    itemIndex: 1,
                    order: 0,
                    typeIdentifier: UTType.utf8PlainText.identifier,
                    data: Data("second-text".utf8)
                ),
                ClipRepresentation(
                    itemIndex: 1,
                    order: 1,
                    typeIdentifier: UTType.rtf.identifier,
                    data: Data("{\\rtf1 second}".utf8)
                ),
            ]
        )

        _ = try await dependencies.engine.copy(clip)
        let writtenSnapshot = try await dependencies.pasteboard.snapshot()
        let sanitizedItems = writtenSnapshot.items.map { item in
            ClipboardItemSnapshot(
                index: item.index,
                representations: item.representations.filter {
                    $0.typeIdentifier != ClipboardConstants.internalMarkerType
                }
            )
        }

        XCTAssertEqual(sanitizedItems, clip.pasteboardItems)
    }

    func testPyPasteCopyIsSuppressedAndCannotCreateFeedbackLoop() async throws {
        let dependencies = makeDependencies()
        let changeCount = await dependencies.pasteboard.set(items: [item(index: 0, text: "one")])
        let captured = try await dependencies.engine.capture(
            observedChangeCount: changeCount,
            sourceApplication: SourceApplication(
                bundleIdentifier: "com.example.source",
                localizedName: "Source"
            )
        )
        let clip = try XCTUnwrap(captured?.clip)
        XCTAssertEqual(clip.sourceApplication?.bundleIdentifier, "com.example.source")

        _ = try await dependencies.engine.copy(clip)
        let ownWriteCount = await dependencies.pasteboard.currentChangeCount()
        let recaptured = try await dependencies.engine.capture(
            observedChangeCount: ownWriteCount,
            sourceApplication: nil
        )
        let markerRecaptured = try await dependencies.engine.capture(
            observedChangeCount: ownWriteCount,
            sourceApplication: nil
        )

        XCTAssertNil(recaptured)
        XCTAssertNil(markerRecaptured)
        let storedClipCount = await dependencies.repository.totalCount()
        XCTAssertEqual(storedClipCount, 1)
    }

    func testClipboardChangeDuringCaptureIsRetriedWithoutCreatingDuplicate() async throws {
        let dependencies = makeDependencies()
        let staleChangeCount = await dependencies.pasteboard.set(
            items: [item(index: 0, text: "stale")]
        )
        let currentChangeCount = await dependencies.pasteboard.set(
            items: [item(index: 0, text: "current")]
        )

        let staleResult = try await dependencies.engine.capture(
            observedChangeCount: staleChangeCount,
            sourceApplication: nil
        )
        let currentResult = try await dependencies.engine.capture(
            observedChangeCount: currentChangeCount,
            sourceApplication: nil
        )

        XCTAssertNil(staleResult)
        XCTAssertEqual(currentResult?.clip.searchableText, "current")
        let storedClipCount = await dependencies.repository.totalCount()
        XCTAssertEqual(storedClipCount, 1)
    }

    func testProductionPollingIntervalStaysInsideRequirement() {
        XCTAssertEqual(
            ClipboardMonitor.Configuration.production.pollingInterval,
            .milliseconds(350)
        )
    }

    @MainActor
    func testCaptureToCallbackLatencyRemainsBelow750MillisecondsAtP95() async throws {
        let dependencies = makeDependencies()
        let workspace = FakeWorkspaceMonitor()
        var startedAt: [String: Date] = [:]
        var latencies: [TimeInterval] = []
        let monitor = ClipboardMonitor(
            pasteboard: dependencies.pasteboard,
            captureHandler: dependencies.engine,
            workspaceMonitor: workspace,
            logger: NoOpLogger(),
            configuration: .production
        ) { result in
            guard let text = result.clip.searchableText, let start = startedAt[text] else {
                return
            }

            latencies.append(Date().timeIntervalSince(start))
        }

        monitor.start()
        try await Task.sleep(for: .milliseconds(25))

        for index in 0..<25 {
            let text = "latency-\(index)"
            startedAt[text] = Date()
            _ = await dependencies.pasteboard.set(items: [item(index: 0, text: text)])
            let expectedCount = index + 1

            while latencies.count < expectedCount {
                try await Task.sleep(for: .milliseconds(2))
            }
        }

        monitor.stop()
        let sorted = latencies.sorted()
        let p95Index = min(Int(Double(sorted.count) * 0.95), sorted.count - 1)
        XCTAssertLessThan(sorted[p95Index], 0.75)
    }

    @MainActor
    func testPauseAndSleepSuspendCaptureAndResumeUsesFreshBaseline() async throws {
        let dependencies = makeDependencies()
        let workspace = FakeWorkspaceMonitor()
        var capturedCount = 0
        let monitor = ClipboardMonitor(
            pasteboard: dependencies.pasteboard,
            captureHandler: dependencies.engine,
            workspaceMonitor: workspace,
            logger: NoOpLogger(),
            configuration: .init(pollingInterval: .milliseconds(10))
        ) { _ in
            capturedCount += 1
        }

        monitor.start()
        try await Task.sleep(for: .milliseconds(25))
        monitor.pause()
        _ = await dependencies.pasteboard.set(items: [item(index: 0, text: "paused")])
        try await Task.sleep(for: .milliseconds(30))
        XCTAssertEqual(capturedCount, 0)

        monitor.resume()
        try await Task.sleep(for: .milliseconds(25))
        _ = await dependencies.pasteboard.set(items: [item(index: 0, text: "resumed")])
        try await waitUntil { capturedCount == 1 }

        workspace.emitSleep(true)
        _ = await dependencies.pasteboard.set(items: [item(index: 0, text: "sleeping")])
        try await Task.sleep(for: .milliseconds(30))
        XCTAssertEqual(capturedCount, 1)

        workspace.emitSleep(false)
        try await Task.sleep(for: .milliseconds(25))
        _ = await dependencies.pasteboard.set(items: [item(index: 0, text: "awake")])
        try await waitUntil { capturedCount == 2 }
        monitor.stop()
    }

    private func makeDependencies() -> TestDependencies {
        let pasteboard = FakePasteboard()
        let repository = FakeClipRepository()
        let engine = ClipboardCaptureEngine(
            pasteboard: pasteboard,
            processor: ClipboardContentProcessor(),
            repository: repository,
            duplicatePolicyProvider: FixedDuplicatePolicyProvider(),
            logger: NoOpLogger()
        )
        return TestDependencies(pasteboard: pasteboard, repository: repository, engine: engine)
    }

    private func item(index: Int, text: String) -> ClipboardItemSnapshot {
        ClipboardItemSnapshot(index: index, representations: [representation(text: text)])
    }

    private func representation(text: String) -> ClipboardRepresentationSnapshot {
        ClipboardRepresentationSnapshot(
            typeIdentifier: UTType.utf8PlainText.identifier,
            data: Data(text.utf8)
        )
    }

    @MainActor
    private func waitUntil(
        timeout: TimeInterval = 1,
        condition: () -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)

        while !condition(), Date() < deadline {
            try await Task.sleep(for: .milliseconds(2))
        }

        XCTAssertTrue(condition())
    }
}

extension ClipboardCaptureEngineTests {
    @MainActor
    func testLargeImageProcessingLeavesMainActorResponsive() async throws {
        let dependencies = makeDependencies()
        let largeImage = Data(repeating: 0xA5, count: 32 * 1_024 * 1_024)
        let imageItem = ClipboardItemSnapshot(
            index: 0,
            representations: [
                ClipboardRepresentationSnapshot(
                    typeIdentifier: UTType.png.identifier,
                    data: largeImage
                )
            ]
        )
        let changeCount = await dependencies.pasteboard.set(items: [imageItem])
        let heartbeatStart = Date()
        let captureTask = Task {
            try await dependencies.engine.capture(
                observedChangeCount: changeCount,
                sourceApplication: nil
            )
        }

        try await Task.sleep(for: .milliseconds(10))
        let heartbeatLatency = Date().timeIntervalSince(heartbeatStart)
        _ = try await captureTask.value

        XCTAssertLessThan(heartbeatLatency, 0.25)
    }
}
