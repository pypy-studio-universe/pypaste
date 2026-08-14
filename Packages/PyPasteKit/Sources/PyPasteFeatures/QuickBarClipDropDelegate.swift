import Foundation
import PyPasteDomain
import SwiftUI
import UniformTypeIdentifiers

enum QuickBarDragPayload {
    static let contentType = UTType(importedAs: ClipboardConstants.internalMarkerType)

    static func itemProvider(for clip: Clip) -> NSItemProvider {
        let provider = NSItemProvider()
        register(
            Data(clip.id.uuidString.utf8),
            typeIdentifier: contentType.identifier,
            visibility: .ownProcess,
            on: provider
        )

        var registeredTypeIdentifiers = Set(provider.registeredTypeIdentifiers)
        for representation in externalRepresentations(for: clip)
        where registeredTypeIdentifiers.insert(representation.typeIdentifier).inserted {
            register(
                representation.data,
                typeIdentifier: representation.typeIdentifier,
                visibility: .all,
                on: provider
            )
        }

        registerTextFallbackIfNeeded(
            for: clip,
            registeredTypeIdentifiers: &registeredTypeIdentifiers,
            on: provider
        )
        return provider
    }

    private static func externalRepresentations(for clip: Clip) -> [ClipRepresentation] {
        clip.representations
            .filter { $0.typeIdentifier != ClipboardConstants.internalMarkerType }
            .sorted {
                if $0.itemIndex == $1.itemIndex {
                    return $0.order < $1.order
                }
                return $0.itemIndex < $1.itemIndex
            }
    }

    private static func registerTextFallbackIfNeeded(
        for clip: Clip,
        registeredTypeIdentifiers: inout Set<String>,
        on provider: NSItemProvider
    ) {
        let supportsTextFallback: Bool =
            switch clip.contentKind {
            case .text, .richText, .url, .color, .emoji:
                true
            case .image, .gif, .pdf, .file, .multipleFiles, .unknown:
                false
            }

        let typeIdentifier = UTType.utf8PlainText.identifier
        guard
            supportsTextFallback,
            registeredTypeIdentifiers.insert(typeIdentifier).inserted,
            let searchableText = clip.searchableText,
            !searchableText.isEmpty
        else {
            return
        }

        register(
            Data(searchableText.utf8),
            typeIdentifier: typeIdentifier,
            visibility: .all,
            on: provider
        )
    }

    private static func register(
        _ data: Data,
        typeIdentifier: String,
        visibility: NSItemProviderRepresentationVisibility,
        on provider: NSItemProvider
    ) {
        provider.registerDataRepresentation(
            forTypeIdentifier: typeIdentifier,
            visibility: visibility
        ) { completion in
            completion(data, nil)
            return nil
        }
    }
}

@MainActor
struct QuickBarClipDropDelegate: DropDelegate {
    let targetClipID: Clip.ID
    let targetWidth: CGFloat
    @Binding var dragSession: QuickBarDragSession
    let animation: Animation?
    let onMove: (Clip.ID, Clip.ID, ClipPlacement) -> Bool

    func validateDrop(info: DropInfo) -> Bool {
        info.hasItemsConforming(to: [QuickBarDragPayload.contentType])
            && dragSession.canDrop(relativeTo: targetClipID)
    }

    func dropEntered(info: DropInfo) {
        updatePreview(at: info.location.x)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        guard validateDrop(info: info), updatePreview(at: info.location.x) else {
            return DropProposal(operation: .forbidden)
        }

        return DropProposal(operation: .move)
    }

    func dropExited(info _: DropInfo) {
        var updatedSession = dragSession
        updatedSession.leave(targetClipID)
        setSession(updatedSession)
    }

    func performDrop(info: DropInfo) -> Bool {
        guard info.hasItemsConforming(to: [QuickBarDragPayload.contentType]) else {
            clearSession()
            return false
        }

        var updatedSession = dragSession
        let request = updatedSession.commit(
            relativeTo: targetClipID,
            locationX: info.location.x,
            targetWidth: targetWidth
        )
        setSession(updatedSession)

        guard let request else {
            return false
        }

        return onMove(
            request.draggedClipID,
            request.targetClipID,
            request.placement
        )
    }

    @discardableResult
    private func updatePreview(at locationX: CGFloat) -> Bool {
        var updatedSession = dragSession
        let didUpdate = updatedSession.updatePreview(
            relativeTo: targetClipID,
            locationX: locationX,
            targetWidth: targetWidth
        )
        setSession(updatedSession)
        return didUpdate
    }

    private func clearSession() {
        var updatedSession = dragSession
        updatedSession.cancel()
        setSession(updatedSession)
    }

    private func setSession(_ session: QuickBarDragSession) {
        guard session != dragSession else {
            return
        }

        withAnimation(animation) {
            dragSession = session
        }
    }
}
