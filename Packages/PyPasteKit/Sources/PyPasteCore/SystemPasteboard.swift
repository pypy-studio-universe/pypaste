import AppKit
import Foundation
import PyPasteDomain

public enum SystemPasteboardError: LocalizedError, Equatable {
    case contentsChangedDuringRead
    case writeFailed

    public var errorDescription: String? {
        switch self {
        case .contentsChangedDuringRead:
            "The pasteboard changed while PyPaste was reading it."
        case .writeFailed:
            "PyPaste could not write the selected clip to the pasteboard."
        }
    }
}

public actor SystemPasteboard: PasteboardProviding {
    private let pasteboardName: String?

    public init(name: String? = nil) {
        pasteboardName = name
    }

    public func currentChangeCount() async -> Int {
        pasteboard.changeCount
    }

    public func snapshot() async throws -> ClipboardSnapshot {
        for _ in 0..<2 {
            let activePasteboard = pasteboard
            let initialChangeCount = activePasteboard.changeCount
            let items = readItems(from: activePasteboard)

            if activePasteboard.changeCount == initialChangeCount {
                return ClipboardSnapshot(changeCount: initialChangeCount, items: items)
            }
        }

        throw SystemPasteboardError.contentsChangedDuringRead
    }

    public func write(items: [ClipboardItemSnapshot], marker: UUID) async throws -> Int {
        let firstItemIndex = items.map(\.index).min()
        let pasteboardItems = items.sorted(by: { $0.index < $1.index }).map { item in
            makePasteboardItem(
                from: item,
                marker: item.index == firstItemIndex ? marker : nil
            )
        }

        guard !pasteboardItems.isEmpty else {
            throw SystemPasteboardError.writeFailed
        }

        let activePasteboard = pasteboard
        activePasteboard.clearContents()

        guard activePasteboard.writeObjects(pasteboardItems) else {
            throw SystemPasteboardError.writeFailed
        }

        return activePasteboard.changeCount
    }

    private var pasteboard: NSPasteboard {
        if let pasteboardName {
            return NSPasteboard(name: NSPasteboard.Name(pasteboardName))
        }

        return .general
    }

    private func readItems(from pasteboard: NSPasteboard) -> [ClipboardItemSnapshot] {
        guard let pasteboardItems = pasteboard.pasteboardItems else {
            return []
        }

        return pasteboardItems.enumerated().map { itemIndex, pasteboardItem in
            let representations = pasteboardItem.types.compactMap { type in
                pasteboardItem.data(forType: type).map {
                    ClipboardRepresentationSnapshot(typeIdentifier: type.rawValue, data: $0)
                }
            }

            return ClipboardItemSnapshot(index: itemIndex, representations: representations)
        }
    }

    private func makePasteboardItem(
        from item: ClipboardItemSnapshot,
        marker: UUID?
    ) -> NSPasteboardItem {
        let pasteboardItem = NSPasteboardItem()

        for representation in item.representations
        where representation.typeIdentifier != ClipboardConstants.internalMarkerType {
            pasteboardItem.setData(
                representation.data,
                forType: NSPasteboard.PasteboardType(representation.typeIdentifier)
            )
        }

        if let marker {
            pasteboardItem.setString(
                marker.uuidString,
                forType: NSPasteboard.PasteboardType(ClipboardConstants.internalMarkerType)
            )
        }

        return pasteboardItem
    }
}
