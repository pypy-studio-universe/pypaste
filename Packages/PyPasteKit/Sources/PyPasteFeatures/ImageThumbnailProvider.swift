import CoreGraphics
import Foundation
import ImageIO
import PyPasteDomain
import UniformTypeIdentifiers

public actor ImageThumbnailProvider {
    public static let shared = ImageThumbnailProvider()

    private static let knownImageTypeIdentifiers: Set<String> = [
        UTType.gif.identifier,
        UTType.heic.identifier,
        UTType.heif.identifier,
        UTType.jpeg.identifier,
        UTType.png.identifier,
        UTType.tiff.identifier,
        "com.microsoft.bmp",
        "com.microsoft.ico",
        "public.avif",
        "public.webp",
    ]

    private let cache: NSCache<NSString, ThumbnailCacheEntry>

    public init(
        cachedImageLimit: Int = 128,
        cachedByteLimit: Int = 64 * 1_024 * 1_024
    ) {
        cache = NSCache<NSString, ThumbnailCacheEntry>()
        cache.countLimit = max(1, cachedImageLimit)
        cache.totalCostLimit = max(1, cachedByteLimit)
    }

    public func thumbnail(
        for clip: Clip,
        maximumPixelSize: Int = 512
    ) -> CGImage? {
        let normalizedPixelSize = max(1, maximumPixelSize)
        let key = cacheKey(for: clip, maximumPixelSize: normalizedPixelSize)

        if let cachedEntry = cache.object(forKey: key) {
            return cachedEntry.image
        }

        let image = firstThumbnail(
            in: clip,
            maximumPixelSize: normalizedPixelSize
        )
        let entry = ThumbnailCacheEntry(image: image)
        cache.setObject(entry, forKey: key, cost: entry.estimatedByteCost)
        return image
    }

    public func removeAllCachedImages() {
        cache.removeAllObjects()
    }

    private func firstThumbnail(
        in clip: Clip,
        maximumPixelSize: Int
    ) -> CGImage? {
        for representation in orderedImageRepresentations(in: clip) {
            if let image = makeThumbnail(
                from: representation,
                maximumPixelSize: maximumPixelSize
            ) {
                return image
            }
        }

        return nil
    }

    private func orderedImageRepresentations(in clip: Clip) -> [ClipRepresentation] {
        clip.representations
            .filter { representation in
                Self.knownImageTypeIdentifiers.contains(representation.typeIdentifier)
                    || UTType(representation.typeIdentifier)?.conforms(to: .image) == true
            }
            .sorted { left, right in
                if left.itemIndex != right.itemIndex {
                    return left.itemIndex < right.itemIndex
                }

                return left.order < right.order
            }
    }

    private func makeThumbnail(
        from representation: ClipRepresentation,
        maximumPixelSize: Int
    ) -> CGImage? {
        let sourceOptions: [CFString: Any] = [
            kCGImageSourceShouldCache: false,
            kCGImageSourceTypeIdentifierHint: representation.typeIdentifier as CFString,
        ]

        guard
            let source = CGImageSourceCreateWithData(
                representation.data as CFData,
                sourceOptions as CFDictionary
            )
        else {
            return nil
        }

        let thumbnailOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maximumPixelSize,
        ]

        return CGImageSourceCreateThumbnailAtIndex(
            source,
            0,
            thumbnailOptions as CFDictionary
        )
    }

    private func cacheKey(for clip: Clip, maximumPixelSize: Int) -> NSString {
        "v1-\(clip.contentHash)-\(maximumPixelSize)" as NSString
    }
}

private final class ThumbnailCacheEntry: NSObject {
    let image: CGImage?
    let estimatedByteCost: Int

    init(image: CGImage?) {
        self.image = image

        if let image {
            estimatedByteCost = image.bytesPerRow * image.height
        } else {
            estimatedByteCost = 1
        }
    }
}
