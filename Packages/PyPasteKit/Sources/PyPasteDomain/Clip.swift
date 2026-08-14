import Foundation

public enum ClipContentKind: String, Codable, CaseIterable, Sendable {
    case text
    case richText
    case url
    case color
    case emoji
    case image
    case gif
    case pdf
    case file
    case multipleFiles
    case unknown
}

public struct Clip: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let createdAt: Date
    public let updatedAt: Date
    public let lastUsedAt: Date
    public let contentKind: ClipContentKind
    public let displayTitle: String
    public let searchableText: String?
    public let sourceApplication: SourceApplication?
    public let contentHash: String
    public let characterCount: Int?
    public let lineCount: Int?
    public let copyCount: Int
    public let representations: [ClipRepresentation]

    public init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        updatedAt: Date? = nil,
        lastUsedAt: Date? = nil,
        contentKind: ClipContentKind,
        displayTitle: String,
        searchableText: String? = nil,
        sourceApplication: SourceApplication? = nil,
        contentHash: String,
        characterCount: Int? = nil,
        lineCount: Int? = nil,
        copyCount: Int = 1,
        representations: [ClipRepresentation] = []
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
        self.lastUsedAt = lastUsedAt ?? createdAt
        self.contentKind = contentKind
        self.displayTitle = displayTitle
        self.searchableText = searchableText
        self.sourceApplication = sourceApplication
        self.contentHash = contentHash
        self.characterCount = characterCount
        self.lineCount = lineCount
        self.copyCount = copyCount
        self.representations = representations
    }

    public var pasteboardItems: [ClipboardItemSnapshot] {
        Dictionary(grouping: representations, by: \.itemIndex)
            .sorted { $0.key < $1.key }
            .map { itemIndex, representations in
                ClipboardItemSnapshot(
                    index: itemIndex,
                    representations:
                        representations
                        .sorted { $0.order < $1.order }
                        .map {
                            ClipboardRepresentationSnapshot(
                                typeIdentifier: $0.typeIdentifier,
                                data: $0.data
                            )
                        }
                )
            }
    }
}
