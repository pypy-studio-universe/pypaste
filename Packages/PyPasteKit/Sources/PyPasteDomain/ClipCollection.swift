import Foundation

public struct ClipCollection: Identifiable, Equatable, Hashable, Sendable {
    public let id: UUID
    public let name: String
    public let colorHex: String
    public let sortOrder: Int
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        colorHex: String,
        sortOrder: Int,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }
}

public struct ClipCollectionSnapshot: Equatable, Sendable {
    public let collections: [ClipCollection]
    public let clips: [Clip]
    public let collectionIDsByClipID: [Clip.ID: Set<ClipCollection.ID>]

    public init(
        collections: [ClipCollection],
        clips: [Clip],
        collectionIDsByClipID: [Clip.ID: Set<ClipCollection.ID>]
    ) {
        self.collections = collections
        self.clips = clips
        self.collectionIDsByClipID = collectionIDsByClipID
    }
}

public protocol ClipCollectionManaging: Sendable {
    func collectionSnapshot(
        selectedCollectionID: ClipCollection.ID?,
        limit: Int
    ) async throws -> ClipCollectionSnapshot

    func createCollection(
        name: String,
        colorHex: String,
        at date: Date
    ) async throws -> ClipCollection

    func addClip(
        id: Clip.ID,
        to collectionID: ClipCollection.ID,
        at date: Date
    ) async throws

    func deleteCollection(id: ClipCollection.ID) async throws
}
