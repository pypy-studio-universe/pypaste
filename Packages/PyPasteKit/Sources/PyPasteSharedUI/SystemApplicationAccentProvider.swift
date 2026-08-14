import AppKit
import CoreGraphics
import Foundation
import ImageIO

public protocol ApplicationAccentProviding: Sendable {
    func accent(
        bundleIdentifier: String?,
        localizedName: String?
    ) async -> ApplicationAccent?
}

public protocol ApplicationIconDataLoading: Sendable {
    func iconData(forBundleIdentifier bundleIdentifier: String) async -> Data?
}

public struct SystemApplicationIconDataLoader: ApplicationIconDataLoading {
    public init() {}

    public func iconData(forBundleIdentifier bundleIdentifier: String) async -> Data? {
        await MainActor.run { () -> Data? in
            guard
                let applicationURL = NSWorkspace.shared.urlForApplication(
                    withBundleIdentifier: bundleIdentifier
                )
            else {
                return nil
            }

            return NSWorkspace.shared.icon(forFile: applicationURL.path).tiffRepresentation
        }
    }
}

public actor SystemApplicationAccentProvider: ApplicationAccentProviding {
    public static let shared = SystemApplicationAccentProvider()

    public static let knownApplicationAccents: [String: ApplicationAccent] = [
        "com.apple.dt.xcode": ApplicationAccent(red: 0.08, green: 0.49, blue: 0.98),
        "com.apple.mail": ApplicationAccent(red: 0.04, green: 0.52, blue: 1.00),
        "com.apple.mobilesms": ApplicationAccent(red: 0.19, green: 0.82, blue: 0.35),
        "com.apple.music": ApplicationAccent(red: 0.98, green: 0.18, blue: 0.28),
        "com.apple.notes": ApplicationAccent(red: 1.00, green: 0.84, blue: 0.04),
        "com.apple.photos": ApplicationAccent(red: 1.00, green: 0.22, blue: 0.37),
        "com.apple.safari": ApplicationAccent(red: 0.00, green: 0.48, blue: 1.00),
        "com.google.chrome": ApplicationAccent(red: 0.26, green: 0.52, blue: 0.96),
        "com.microsoft.vscode": ApplicationAccent(red: 0.00, green: 0.48, blue: 0.80),
        "com.openai.chat": ApplicationAccent(red: 0.06, green: 0.64, blue: 0.50),
        "com.pypaste.app": ApplicationAccent(red: 0.13, green: 0.13, blue: 0.15),
    ]

    private let iconLoader: any ApplicationIconDataLoading
    private let overrides: [String: ApplicationAccent]
    private let maximumCachedApplicationCount: Int
    private var cachedAccents: [String: ApplicationAccent] = [:]
    private var cacheOrder: [String] = []
    private var inFlightRequests: [String: Task<ApplicationAccent, Never>] = [:]

    public init(
        iconLoader: any ApplicationIconDataLoading = SystemApplicationIconDataLoader(),
        overrides: [String: ApplicationAccent]? = nil,
        maximumCachedApplicationCount: Int = 128
    ) {
        self.iconLoader = iconLoader
        self.overrides = overrides ?? Self.knownApplicationAccents
        self.maximumCachedApplicationCount = max(1, maximumCachedApplicationCount)
    }

    public func accent(
        bundleIdentifier: String?,
        localizedName: String?
    ) async -> ApplicationAccent? {
        let normalizedBundleIdentifier = normalized(bundleIdentifier)
        let normalizedName = normalized(localizedName)
        guard let cacheKey = normalizedBundleIdentifier ?? normalizedName else {
            return nil
        }

        if let normalizedBundleIdentifier,
            let override = overrides[normalizedBundleIdentifier]
        {
            return override
        }

        if let cachedAccent = cachedAccents[cacheKey] {
            return cachedAccent
        }

        if let inFlightRequest = inFlightRequests[cacheKey] {
            return await inFlightRequest.value
        }

        let iconLoader = iconLoader
        let fallbackSeed = normalizedBundleIdentifier ?? normalizedName ?? cacheKey
        let request = Task.detached(priority: .utility) {
            if let normalizedBundleIdentifier,
                let iconData = await iconLoader.iconData(
                    forBundleIdentifier: normalizedBundleIdentifier
                ),
                let extractedAccent = ApplicationAccentAnalyzer.accent(from: iconData)
            {
                return extractedAccent
            }

            return ApplicationAccent.deterministic(seed: fallbackSeed)
        }

        inFlightRequests[cacheKey] = request
        let resolvedAccent = await request.value
        inFlightRequests[cacheKey] = nil
        cache(resolvedAccent, forKey: cacheKey)
        return resolvedAccent
    }

    private func cache(_ accent: ApplicationAccent, forKey key: String) {
        cachedAccents[key] = accent
        cacheOrder.removeAll { $0 == key }
        cacheOrder.append(key)

        while cacheOrder.count > maximumCachedApplicationCount {
            cachedAccents[cacheOrder.removeFirst()] = nil
        }
    }

    private func normalized(_ value: String?) -> String? {
        guard let value else {
            return nil
        }

        let normalizedValue = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return normalizedValue.isEmpty ? nil : normalizedValue
    }
}

enum ApplicationAccentAnalyzer {
    private struct Sample {
        let hue: Double
        let red: Double
        let green: Double
        let blue: Double
        let weight: Double
    }

    private static let hueBinCount = 24

    static func accent(from data: Data) -> ApplicationAccent? {
        let sourceOptions: [CFString: Any] = [kCGImageSourceShouldCache: false]
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
            kCGImageSourceThumbnailMaxPixelSize: 48,
        ]
        guard
            let image = CGImageSourceCreateThumbnailAtIndex(
                source,
                0,
                thumbnailOptions as CFDictionary
            )
        else {
            return nil
        }

        return accent(from: image)
    }

    static func accent(from image: CGImage) -> ApplicationAccent? {
        guard let pixels = rgbaPixels(from: image) else {
            return nil
        }

        let samples = makeSamples(from: pixels)
        guard !samples.isEmpty else {
            return nil
        }

        var histogram = [Double](repeating: 0, count: hueBinCount)
        for sample in samples {
            let index = min(Int(sample.hue * Double(hueBinCount)), hueBinCount - 1)
            histogram[index] += sample.weight
        }

        guard let dominantIndex = histogram.indices.max(by: { histogram[$0] < histogram[$1] })
        else {
            return nil
        }

        let dominantHue = (Double(dominantIndex) + 0.5) / Double(hueBinCount)
        let maximumHueDistance = 1.5 / Double(hueBinCount)
        let dominantSamples = samples.filter {
            circularDistance($0.hue, dominantHue) <= maximumHueDistance
        }
        let totalWeight = dominantSamples.reduce(0) { $0 + $1.weight }
        guard totalWeight > 0 else {
            return nil
        }

        let red = dominantSamples.reduce(0) { $0 + $1.red * $1.weight } / totalWeight
        let green = dominantSamples.reduce(0) { $0 + $1.green * $1.weight } / totalWeight
        let blue = dominantSamples.reduce(0) { $0 + $1.blue * $1.weight } / totalWeight
        let hsv = ApplicationAccent.hsv(red: red, green: green, blue: blue)

        return ApplicationAccent.fromHSV(
            hue: hsv.hue,
            saturation: max(hsv.saturation, 0.56),
            brightness: min(max(hsv.brightness, 0.62), 0.92)
        )
    }

    private static func rgbaPixels(from image: CGImage) -> [UInt8]? {
        let width = image.width
        let height = image.height
        guard width > 0, height > 0 else {
            return nil
        }

        let bytesPerRow = width * 4
        var pixels = [UInt8](repeating: 0, count: bytesPerRow * height)
        let rendered = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard
                let context = CGContext(
                    data: buffer.baseAddress,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: bytesPerRow,
                    space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                        | CGBitmapInfo.byteOrder32Big.rawValue
                )
            else {
                return false
            }

            context.interpolationQuality = .high
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }

        return rendered ? pixels : nil
    }

    private static func makeSamples(from pixels: [UInt8]) -> [Sample] {
        stride(from: 0, to: pixels.count, by: 4).compactMap { index in
            let alpha = Double(pixels[index + 3]) / 255
            guard alpha >= 0.20 else {
                return nil
            }

            let red = min(Double(pixels[index]) / 255 / alpha, 1)
            let green = min(Double(pixels[index + 1]) / 255 / alpha, 1)
            let blue = min(Double(pixels[index + 2]) / 255 / alpha, 1)
            let hsv = ApplicationAccent.hsv(red: red, green: green, blue: blue)
            guard
                hsv.saturation >= 0.18,
                hsv.brightness >= 0.15,
                hsv.brightness <= 0.98
            else {
                return nil
            }

            let weight =
                alpha
                * (0.35 + hsv.saturation * hsv.saturation)
                * (0.50 + hsv.brightness * 0.50)
            return Sample(
                hue: hsv.hue,
                red: red,
                green: green,
                blue: blue,
                weight: weight
            )
        }
    }

    private static func circularDistance(_ first: Double, _ second: Double) -> Double {
        let distance = abs(first - second)
        return min(distance, 1 - distance)
    }
}
