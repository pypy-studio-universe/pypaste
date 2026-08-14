import Foundation
import PyPasteDomain

@testable import PyPasteCore

struct TestDependencies {
    let pasteboard: FakePasteboard
    let repository: FakeClipRepository
    let engine: ClipboardCaptureEngine
}

actor FakePasteboard: PasteboardProviding {
    private var changeCount = 0
    private var items: [ClipboardItemSnapshot] = []

    func currentChangeCount() async -> Int {
        changeCount
    }

    func snapshot() async throws -> ClipboardSnapshot {
        ClipboardSnapshot(changeCount: changeCount, items: items)
    }

    func write(items: [ClipboardItemSnapshot], marker: UUID) async throws -> Int {
        changeCount += 1
        self.items = items.enumerated().map { index, item in
            var representations = item.representations

            if index == 0 {
                representations.append(
                    ClipboardRepresentationSnapshot(
                        typeIdentifier: ClipboardConstants.internalMarkerType,
                        data: Data(marker.uuidString.utf8)
                    ))
            }

            return ClipboardItemSnapshot(index: item.index, representations: representations)
        }
        return changeCount
    }

    func set(items: [ClipboardItemSnapshot]) -> Int {
        changeCount += 1
        self.items = items
        return changeCount
    }
}

actor FakeClipRepository: ClipRepository {
    private var clips: [Clip] = []

    func save(_ clip: Clip, duplicatePolicy: DuplicatePolicy) async throws -> ClipStoreResult {
        clips.insert(clip, at: 0)
        return ClipStoreResult(clip: clip, outcome: .inserted)
    }

    func recentClips(limit: Int) async throws -> [Clip] {
        Array(clips.prefix(limit))
    }

    func clip(id: UUID) async throws -> Clip? {
        clips.first { $0.id == id }
    }

    func recordUse(id: UUID, at date: Date) async throws -> Clip? {
        clips.first { $0.id == id }
    }

    func totalCount() -> Int {
        clips.count
    }
}

actor FixedDuplicatePolicyProvider: DuplicatePolicyProviding {
    func duplicatePolicy() async -> DuplicatePolicy {
        .moveExistingToTop
    }
}

@MainActor
final class FakeWorkspaceMonitor: WorkspaceMonitoring {
    var frontmostApplication: SourceApplication? = SourceApplication(
        bundleIdentifier: "com.example.test",
        localizedName: "Test"
    )
    var onSleepStateChange: ((Bool) -> Void)?

    func start() {}
    func stop() {}

    func emitSleep(_ isSleeping: Bool) {
        onSleepStateChange?(isSleeping)
    }
}
