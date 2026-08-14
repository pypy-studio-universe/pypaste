import Foundation
import PyPasteDomain

struct QuickBarDropPreview: Equatable {
    let targetClipID: Clip.ID
    let placement: ClipPlacement
}

struct QuickBarDropRequest: Equatable {
    let draggedClipID: Clip.ID
    let targetClipID: Clip.ID
    let placement: ClipPlacement
}

struct QuickBarDragSession: Equatable {
    private enum Threshold {
        static let switchToBefore = 0.42
        static let switchToAfter = 0.58
    }

    private(set) var draggedClipID: Clip.ID?
    private(set) var preview: QuickBarDropPreview?

    mutating func beginDragging(_ clipID: Clip.ID) {
        draggedClipID = clipID
        preview = nil
    }

    func canDrop(relativeTo targetClipID: Clip.ID) -> Bool {
        guard let draggedClipID else {
            return false
        }

        return draggedClipID != targetClipID
    }

    @discardableResult
    mutating func updatePreview(
        relativeTo targetClipID: Clip.ID,
        locationX: CGFloat,
        targetWidth: CGFloat
    ) -> Bool {
        guard let draggedClipID else {
            preview = nil
            return false
        }

        guard draggedClipID != targetClipID else {
            preview = nil
            return false
        }

        guard locationX.isFinite, targetWidth.isFinite, targetWidth > 0 else {
            leave(targetClipID)
            return false
        }

        let placement = resolvedPlacement(
            relativeTo: targetClipID,
            locationX: locationX,
            targetWidth: targetWidth
        )
        preview = QuickBarDropPreview(
            targetClipID: targetClipID,
            placement: placement
        )
        return true
    }

    mutating func leave(_ targetClipID: Clip.ID) {
        guard preview?.targetClipID == targetClipID else {
            return
        }

        preview = nil
    }

    mutating func commit(
        relativeTo targetClipID: Clip.ID,
        locationX: CGFloat,
        targetWidth: CGFloat
    ) -> QuickBarDropRequest? {
        guard
            updatePreview(
                relativeTo: targetClipID,
                locationX: locationX,
                targetWidth: targetWidth
            ),
            let draggedClipID,
            let preview
        else {
            cancel()
            return nil
        }

        let request = QuickBarDropRequest(
            draggedClipID: draggedClipID,
            targetClipID: preview.targetClipID,
            placement: preview.placement
        )
        cancel()
        return request
    }

    mutating func cancel() {
        draggedClipID = nil
        preview = nil
    }

    private func resolvedPlacement(
        relativeTo targetClipID: Clip.ID,
        locationX: CGFloat,
        targetWidth: CGFloat
    ) -> ClipPlacement {
        guard let preview, preview.targetClipID == targetClipID else {
            return locationX < targetWidth / 2 ? .before : .after
        }

        let normalizedLocation = locationX / targetWidth
        switch preview.placement {
        case .before:
            return normalizedLocation >= Threshold.switchToAfter ? .after : .before
        case .after:
            return normalizedLocation < Threshold.switchToBefore ? .before : .after
        }
    }
}
