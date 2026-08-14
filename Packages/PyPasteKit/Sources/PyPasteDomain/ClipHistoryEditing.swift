import Foundation

public enum ClipPlacement: Equatable, Sendable {
    case before
    case after
}

public protocol ClipHistoryEditing: Sendable {
    func move(
        id: UUID,
        relativeTo targetID: UUID,
        placement: ClipPlacement
    ) async throws

    func moveToTrash(id: UUID, at date: Date) async throws
}
