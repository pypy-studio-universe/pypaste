import Foundation
import PyPasteDomain
import UniformTypeIdentifiers

public actor ClipboardContentProcessor: ClipboardContentProcessing {
    private let hasher: any CanonicalHashing

    public init(hasher: any CanonicalHashing = SHA256CanonicalHasher()) {
        self.hasher = hasher
    }

    public func makeClip(
        from snapshot: ClipboardSnapshot,
        sourceApplication: SourceApplication?
    ) async -> Clip? {
        let items = sanitizedItems(snapshot.items)

        guard !items.isEmpty else {
            return nil
        }

        let representations = items.flatMap { item in
            item.representations.enumerated().map { order, representation in
                ClipRepresentation(
                    itemIndex: item.index,
                    order: order,
                    typeIdentifier: representation.typeIdentifier,
                    data: representation.data
                )
            }
        }

        guard !representations.isEmpty else {
            return nil
        }

        let searchableText = firstText(in: items)
        let kind = detectContentKind(in: items, searchableText: searchableText)
        let displayTitle = makeDisplayTitle(
            kind: kind,
            itemCount: items.count,
            searchableText: searchableText,
            items: items
        )
        let now = snapshot.capturedAt

        return Clip(
            createdAt: now,
            contentKind: kind,
            displayTitle: displayTitle,
            searchableText: searchableText,
            sourceApplication: sourceApplication,
            contentHash: hasher.hash(items: items),
            characterCount: searchableText?.count,
            lineCount: searchableText.map { $0.isEmpty ? 0 : $0.split(separator: "\n").count },
            representations: representations
        )
    }

    private func sanitizedItems(_ items: [ClipboardItemSnapshot]) -> [ClipboardItemSnapshot] {
        items.sorted(by: { $0.index < $1.index }).compactMap { item in
            let representations = item.representations.filter {
                $0.typeIdentifier != ClipboardConstants.internalMarkerType
            }

            guard !representations.isEmpty else {
                return nil
            }

            return ClipboardItemSnapshot(index: item.index, representations: representations)
        }
    }

    private func detectContentKind(
        in items: [ClipboardItemSnapshot],
        searchableText: String?
    ) -> ClipContentKind {
        let fileItemCount = items.filter { containsType(in: $0, conformingTo: .fileURL) }.count

        if fileItemCount > 1 {
            return .multipleFiles
        }

        if fileItemCount == 1 {
            return .file
        }

        let allRepresentations = items.flatMap(\.representations)
        let allTypes = allRepresentations.compactMap { UTType($0.typeIdentifier) }

        if allTypes.contains(where: { $0.conforms(to: .pdf) }) {
            return .pdf
        }

        if allRepresentations.contains(where: {
            PasteboardTypeClassifier.isGIF($0.typeIdentifier)
        }) {
            return .gif
        }

        if allRepresentations.contains(where: {
            PasteboardTypeClassifier.isImage($0.typeIdentifier)
        }) {
            return .image
        }

        if let searchableText, HexColor(searchableText) != nil {
            return .color
        }

        if allTypes.contains(where: { $0.conforms(to: .rtf) || $0.conforms(to: .html) }) {
            return .richText
        }

        if allTypes.contains(where: { $0.conforms(to: .url) })
            || searchableText.map(WebLinkPreview.init) != nil
        {
            return .url
        }

        if allTypes.contains(where: { $0.conforms(to: .plainText) }) {
            return .text
        }

        return .unknown
    }

    private func containsType(in item: ClipboardItemSnapshot, conformingTo expected: UTType) -> Bool
    {
        item.representations.contains { representation in
            if expected == .fileURL {
                return PasteboardTypeClassifier.isFileURL(representation.typeIdentifier)
            }

            return UTType(representation.typeIdentifier)?.conforms(to: expected) == true
        }
    }

    private func firstText(in items: [ClipboardItemSnapshot]) -> String? {
        let representations = items.flatMap(\.representations)
        let preferredTypes = [UTType.utf8PlainText, .plainText, .url]

        for preferredType in preferredTypes {
            if let representation = representations.first(where: {
                if preferredType == .utf8PlainText || preferredType == .plainText {
                    return PasteboardTypeClassifier.isPlainText($0.typeIdentifier)
                }

                return UTType($0.typeIdentifier)?.conforms(to: preferredType) == true
            }), let value = decodeString(from: representation.data) {
                return value
            }
        }

        return nil
    }

    private func makeDisplayTitle(
        kind: ClipContentKind,
        itemCount: Int,
        searchableText: String?,
        items: [ClipboardItemSnapshot]
    ) -> String {
        if let specializedTitle = makeSpecializedTitle(
            kind: kind,
            itemCount: itemCount,
            searchableText: searchableText,
            items: items
        ) {
            return specializedTitle
        }

        if let searchableText {
            let singleLine = searchableText.replacingOccurrences(of: "\n", with: " ")
            return String(singleLine.prefix(120))
        }

        if itemCount > 1 {
            return "\(itemCount) clipboard items"
        }

        return fallbackTitle(for: kind)
    }

    private func makeSpecializedTitle(
        kind: ClipContentKind,
        itemCount: Int,
        searchableText: String?,
        items: [ClipboardItemSnapshot]
    ) -> String? {
        switch kind {
        case .multipleFiles:
            return "\(itemCount) files"
        case .file:
            return firstFileName(in: items)
        case .color:
            return searchableText.flatMap(HexColor.init)?.canonicalCode
        case .url:
            return searchableText.flatMap(WebLinkPreview.init)?.displayHost
        default:
            return nil
        }
    }

    private func fallbackTitle(for kind: ClipContentKind) -> String {
        switch kind {
        case .image:
            return "Image"
        case .gif:
            return "Animated image"
        case .pdf:
            return "PDF document"
        case .richText:
            return "Rich text"
        case .unknown:
            return "Clipboard item"
        default:
            return kind.rawValue.capitalized
        }
    }

    private func firstFileName(in items: [ClipboardItemSnapshot]) -> String? {
        for representation in items.flatMap(\.representations) {
            guard PasteboardTypeClassifier.isFileURL(representation.typeIdentifier),
                let value = decodeString(from: representation.data), let url = URL(string: value)
            else {
                continue
            }

            return url.lastPathComponent
        }

        return nil
    }

    private func decodeString(from data: Data) -> String? {
        if let value = String(data: data, encoding: .utf8) {
            return value
        }

        if let propertyList = try? PropertyListSerialization.propertyList(from: data, format: nil),
            let value = propertyList as? String
        {
            return value
        }

        return nil
    }
}
