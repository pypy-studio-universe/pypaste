import Foundation

public protocol PasteboardProviding: Sendable {
    func currentChangeCount() async -> Int
    func snapshot() async throws -> ClipboardSnapshot
    func write(items: [ClipboardItemSnapshot], marker: UUID) async throws -> Int
}

public protocol CanonicalHashing: Sendable {
    func hash(items: [ClipboardItemSnapshot]) -> String
}

public protocol ClipboardContentProcessing: Sendable {
    func makeClip(
        from snapshot: ClipboardSnapshot,
        sourceApplication: SourceApplication?
    ) async -> Clip?
}

public protocol DuplicatePolicyProviding: Sendable {
    func duplicatePolicy() async -> DuplicatePolicy
}

public protocol ClipRepository: Sendable {
    func save(_ clip: Clip, duplicatePolicy: DuplicatePolicy) async throws -> ClipStoreResult
    func recentClips(limit: Int) async throws -> [Clip]
    func clip(id: UUID) async throws -> Clip?
    func recordUse(id: UUID, at date: Date) async throws -> Clip?
}

public protocol ClipboardCaptureHandling: Sendable {
    func capture(
        observedChangeCount: Int,
        sourceApplication: SourceApplication?
    ) async throws -> ClipStoreResult?

    func copy(_ clip: Clip) async throws -> Clip?
}
