import CoreGraphics
import Foundation
import ImageIO
@preconcurrency import LinkPresentation
import UniformTypeIdentifiers

public struct RichLinkMetadata: Sendable {
    public let title: String?
    public let image: CGImage?

    public init(title: String?, image: CGImage?) {
        self.title = title
        self.image = image
    }
}

public protocol LinkMetadataLoading: Sendable {
    func loadMetadata(for url: URL) async throws -> RichLinkMetadata
}

public actor RichLinkMetadataProvider {
    public static let shared = RichLinkMetadataProvider()

    private enum CacheEntry {
        case available(RichLinkMetadata)
        case unavailable
    }

    private let loader: any LinkMetadataLoading
    private let cacheLimit: Int
    private var cache: [URL: CacheEntry] = [:]
    private var cacheOrder: [URL] = []
    private var inFlight: [URL: Task<RichLinkMetadata?, Never>] = [:]

    public init(
        loader: any LinkMetadataLoading = SystemLinkMetadataLoader(),
        cacheLimit: Int = 128
    ) {
        self.loader = loader
        self.cacheLimit = max(1, cacheLimit)
    }

    public func metadata(for url: URL) async -> RichLinkMetadata? {
        if let cached = cache[url] {
            touch(url)
            switch cached {
            case let .available(metadata):
                return metadata
            case .unavailable:
                return nil
            }
        }

        if let task = inFlight[url] {
            return await task.value
        }

        let loader = loader
        let task = Task {
            try? await loader.loadMetadata(for: url)
        }
        inFlight[url] = task
        let metadata = await task.value
        inFlight[url] = nil
        insert(metadata, for: url)
        return metadata
    }

    public func removeAllCachedMetadata() {
        cache.removeAll()
        cacheOrder.removeAll()
    }

    private func insert(_ metadata: RichLinkMetadata?, for url: URL) {
        cache[url] = metadata.map(CacheEntry.available) ?? .unavailable
        touch(url)

        while cacheOrder.count > cacheLimit {
            let evictedURL = cacheOrder.removeFirst()
            cache[evictedURL] = nil
        }
    }

    private func touch(_ url: URL) {
        cacheOrder.removeAll { $0 == url }
        cacheOrder.append(url)
    }
}

public struct SystemLinkMetadataLoader: LinkMetadataLoading {
    private static let maximumThumbnailPixelSize = 512

    public init() {}

    public func loadMetadata(for url: URL) async throws -> RichLinkMetadata {
        let provider = LPMetadataProvider()
        provider.shouldFetchSubresources = true
        provider.timeout = 6
        let metadata = try await provider.startFetchingMetadata(for: url)
        let image = await thumbnail(
            from: metadata.imageProvider ?? metadata.iconProvider
        )
        let normalizedTitle = metadata.title?.trimmingCharacters(in: .whitespacesAndNewlines)

        return RichLinkMetadata(
            title: normalizedTitle?.isEmpty == false ? normalizedTitle : nil,
            image: image
        )
    }

    private func thumbnail(from provider: NSItemProvider?) async -> CGImage? {
        guard
            let provider,
            let typeIdentifier = provider.registeredTypeIdentifiers.first(where: { identifier in
                UTType(identifier)?.conforms(to: .image) == true
            }),
            let data = await loadImageData(
                from: provider,
                typeIdentifier: typeIdentifier
            )
        else {
            return nil
        }

        let sourceOptions: [CFString: Any] = [
            kCGImageSourceShouldCache: false,
            kCGImageSourceTypeIdentifierHint: typeIdentifier as CFString,
        ]
        guard
            let source = CGImageSourceCreateWithData(
                data as CFData,
                sourceOptions as CFDictionary
            )
        else {
            return nil
        }

        let thumbnailOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: Self.maximumThumbnailPixelSize,
        ]
        return CGImageSourceCreateThumbnailAtIndex(
            source,
            0,
            thumbnailOptions as CFDictionary
        )
    }

    private func loadImageData(
        from provider: NSItemProvider,
        typeIdentifier: String
    ) async -> Data? {
        await withCheckedContinuation { continuation in
            provider.loadDataRepresentation(forTypeIdentifier: typeIdentifier) { data, _ in
                continuation.resume(returning: data)
            }
        }
    }
}
