import Foundation

public enum ClipboardConstants {
    public static let internalMarkerType = "com.pypaste.internal.clip-id"
}

public struct SourceApplication: Codable, Equatable, Sendable {
    public let bundleIdentifier: String?
    public let localizedName: String?

    public init(bundleIdentifier: String?, localizedName: String?) {
        self.bundleIdentifier = bundleIdentifier
        self.localizedName = localizedName
    }
}

public struct ClipboardRepresentationSnapshot: Equatable, Sendable {
    public let typeIdentifier: String
    public let data: Data

    public init(typeIdentifier: String, data: Data) {
        self.typeIdentifier = typeIdentifier
        self.data = data
    }
}

public struct ClipboardItemSnapshot: Equatable, Sendable {
    public let index: Int
    public let representations: [ClipboardRepresentationSnapshot]

    public init(index: Int, representations: [ClipboardRepresentationSnapshot]) {
        self.index = index
        self.representations = representations
    }
}

public struct ClipboardSnapshot: Equatable, Sendable {
    public let changeCount: Int
    public let capturedAt: Date
    public let items: [ClipboardItemSnapshot]

    public init(changeCount: Int, capturedAt: Date = Date(), items: [ClipboardItemSnapshot]) {
        self.changeCount = changeCount
        self.capturedAt = capturedAt
        self.items = items
    }

    public var containsInternalMarker: Bool {
        items.contains { item in
            item.representations.contains {
                $0.typeIdentifier == ClipboardConstants.internalMarkerType
            }
        }
    }
}

public struct ClipRepresentation: Codable, Equatable, Sendable {
    public let itemIndex: Int
    public let order: Int
    public let typeIdentifier: String
    public let data: Data

    public init(itemIndex: Int, order: Int, typeIdentifier: String, data: Data) {
        self.itemIndex = itemIndex
        self.order = order
        self.typeIdentifier = typeIdentifier
        self.data = data
    }
}

public enum DuplicatePolicy: String, CaseIterable, Codable, Sendable {
    case moveExistingToTop
    case createNew

    public static let defaultsKey = "clipboard.duplicatePolicy"
}

public enum ClipStoreOutcome: Equatable, Sendable {
    case inserted
    case movedExisting
}

public struct ClipStoreResult: Equatable, Sendable {
    public let clip: Clip
    public let outcome: ClipStoreOutcome

    public init(clip: Clip, outcome: ClipStoreOutcome) {
        self.clip = clip
        self.outcome = outcome
    }
}
