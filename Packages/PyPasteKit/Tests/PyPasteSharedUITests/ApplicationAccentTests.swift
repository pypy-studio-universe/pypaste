import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers
import XCTest

@testable import PyPasteSharedUI

final class ApplicationAccentTests: XCTestCase {
    func testClampsComponentsToValidColorRange() {
        let accent = ApplicationAccent(red: -0.5, green: 0.4, blue: 1.5)

        XCTAssertEqual(accent.red, 0)
        XCTAssertEqual(accent.green, 0.4)
        XCTAssertEqual(accent.blue, 1)
    }

    func testChoosesBlackForegroundForBrightAccent() {
        let accent = ApplicationAccent(red: 1, green: 0.84, blue: 0.04)

        XCTAssertEqual(accent.foreground, .black)
        XCTAssertGreaterThanOrEqual(accent.preferredContrastRatio, 4.5)
    }

    func testChoosesWhiteForegroundForDarkAccent() {
        let accent = ApplicationAccent(red: 0.02, green: 0.12, blue: 0.32)

        XCTAssertEqual(accent.foreground, .white)
        XCTAssertGreaterThanOrEqual(accent.preferredContrastRatio, 4.5)
    }

    func testDeterministicAccentIsStableForSameSeed() {
        let firstAccent = ApplicationAccent.deterministic(seed: "com.example.editor")
        let secondAccent = ApplicationAccent.deterministic(seed: "com.example.editor")

        XCTAssertEqual(firstAccent, secondAccent)
    }
}

final class ApplicationAccentAnalyzerTests: XCTestCase {
    func testExtractsColorWhileIgnoringTransparentAndWhitePixels() throws {
        let image = try makeImage(width: 20, height: 20) { context in
            context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
            context.fill(CGRect(x: 0, y: 0, width: 10, height: 20))
            context.setFillColor(CGColor(red: 0.9, green: 0.08, blue: 0.06, alpha: 1))
            context.fill(CGRect(x: 10, y: 0, width: 10, height: 10))
        }

        let accent = try XCTUnwrap(ApplicationAccentAnalyzer.accent(from: image))

        XCTAssertGreaterThan(accent.red, 0.75)
        XCTAssertLessThan(accent.green, 0.25)
        XCTAssertLessThan(accent.blue, 0.25)
    }

    func testChoosesDominantHueCluster() throws {
        let image = try makeImage(width: 40, height: 10) { context in
            context.setFillColor(CGColor(red: 0.08, green: 0.18, blue: 0.85, alpha: 1))
            context.fill(CGRect(x: 0, y: 0, width: 30, height: 10))
            context.setFillColor(CGColor(red: 0.85, green: 0.08, blue: 0.06, alpha: 1))
            context.fill(CGRect(x: 30, y: 0, width: 10, height: 10))
        }

        let accent = try XCTUnwrap(ApplicationAccentAnalyzer.accent(from: image))

        XCTAssertGreaterThan(accent.blue, accent.red)
        XCTAssertGreaterThan(accent.blue, accent.green)
    }

    func testReturnsNilWhenImageContainsOnlyNeutralPixels() throws {
        let image = try makeImage(width: 12, height: 12) { context in
            context.setFillColor(CGColor(gray: 0.5, alpha: 1))
            context.fill(CGRect(x: 0, y: 0, width: 12, height: 12))
        }

        XCTAssertNil(ApplicationAccentAnalyzer.accent(from: image))
    }

    func testExtractsAccentFromEncodedImageData() throws {
        let image = try makeImage(width: 12, height: 12) { context in
            context.setFillColor(CGColor(red: 0.1, green: 0.75, blue: 0.25, alpha: 1))
            context.fill(CGRect(x: 0, y: 0, width: 12, height: 12))
        }
        let imageData = try encodePNG(image)

        let accent = try XCTUnwrap(ApplicationAccentAnalyzer.accent(from: imageData))

        XCTAssertGreaterThan(accent.green, accent.red)
        XCTAssertGreaterThan(accent.green, accent.blue)
    }
}

final class SystemApplicationAccentProviderTests: XCTestCase {
    func testPyPasteUsesMonochromeBrandAccent() async throws {
        let provider = SystemApplicationAccentProvider(
            iconLoader: AccentIconDataLoader(data: nil)
        )

        let resolvedAccent = await provider.accent(
            bundleIdentifier: "com.pypaste.app",
            localizedName: "PyPaste"
        )
        let accent = try XCTUnwrap(resolvedAccent)

        XCTAssertEqual(
            accent,
            SystemApplicationAccentProvider.knownApplicationAccents[
                "com.pypaste.app"
            ])
        XCTAssertEqual(accent.foreground, .white)
    }

    func testReturnsKnownOverrideWithoutLoadingIcon() async {
        let iconLoader = AccentIconDataLoader(data: nil)
        let expectedAccent = ApplicationAccent(red: 0.2, green: 0.4, blue: 0.6)
        let provider = SystemApplicationAccentProvider(
            iconLoader: iconLoader,
            overrides: ["com.example.editor": expectedAccent]
        )

        let accent = await provider.accent(
            bundleIdentifier: " COM.EXAMPLE.EDITOR ",
            localizedName: "Editor"
        )

        XCTAssertEqual(accent, expectedAccent)
        let requestCount = await iconLoader.requestCount()
        XCTAssertEqual(requestCount, 0)
    }

    func testCachesResolvedAccentForRepeatedRequests() async {
        let iconLoader = AccentIconDataLoader(data: nil)
        let provider = SystemApplicationAccentProvider(iconLoader: iconLoader, overrides: [:])

        let firstAccent = await provider.accent(
            bundleIdentifier: "com.example.editor",
            localizedName: "Editor"
        )
        let secondAccent = await provider.accent(
            bundleIdentifier: "com.example.editor",
            localizedName: "Editor"
        )

        XCTAssertEqual(firstAccent, secondAccent)
        let requestCount = await iconLoader.requestCount()
        XCTAssertEqual(requestCount, 1)
    }

    func testCoalescesConcurrentRequestsForSameApplication() async {
        let iconLoader = AccentIconDataLoader(data: nil, delayNanoseconds: 50_000_000)
        let provider = SystemApplicationAccentProvider(iconLoader: iconLoader, overrides: [:])

        async let firstRequest = provider.accent(
            bundleIdentifier: "com.example.editor",
            localizedName: "Editor"
        )
        async let secondRequest = provider.accent(
            bundleIdentifier: "com.example.editor",
            localizedName: "Editor"
        )
        let (firstAccent, secondAccent) = await (firstRequest, secondRequest)

        XCTAssertEqual(firstAccent, secondAccent)
        let requestCount = await iconLoader.requestCount()
        XCTAssertEqual(requestCount, 1)
    }

    func testUsesIconAccentWhenImageDataIsValid() async throws {
        let image = try makeImage(width: 12, height: 12) { context in
            context.setFillColor(CGColor(red: 0.75, green: 0.12, blue: 0.55, alpha: 1))
            context.fill(CGRect(x: 0, y: 0, width: 12, height: 12))
        }
        let iconLoader = AccentIconDataLoader(data: try encodePNG(image))
        let provider = SystemApplicationAccentProvider(iconLoader: iconLoader, overrides: [:])

        let resolvedAccent = await provider.accent(
            bundleIdentifier: "com.example.editor",
            localizedName: "Editor"
        )
        let accent = try XCTUnwrap(resolvedAccent)

        XCTAssertGreaterThan(accent.red, accent.green)
        XCTAssertGreaterThan(accent.blue, accent.green)
    }

    func testFallbackIsStableAcrossProviderInstances() async {
        let firstProvider = SystemApplicationAccentProvider(
            iconLoader: AccentIconDataLoader(data: nil),
            overrides: [:]
        )
        let secondProvider = SystemApplicationAccentProvider(
            iconLoader: AccentIconDataLoader(data: nil),
            overrides: [:]
        )

        let firstAccent = await firstProvider.accent(
            bundleIdentifier: "com.example.missing",
            localizedName: "Missing"
        )
        let secondAccent = await secondProvider.accent(
            bundleIdentifier: "com.example.missing",
            localizedName: "Missing"
        )

        XCTAssertEqual(firstAccent, secondAccent)
    }

    func testReturnsNilForMissingAndBlankSourceMetadata() async {
        let iconLoader = AccentIconDataLoader(data: nil)
        let provider = SystemApplicationAccentProvider(iconLoader: iconLoader, overrides: [:])

        let missingAccent = await provider.accent(bundleIdentifier: nil, localizedName: nil)
        let blankAccent = await provider.accent(
            bundleIdentifier: "  \n ",
            localizedName: "\t"
        )

        XCTAssertNil(missingAccent)
        XCTAssertNil(blankAccent)
        let requestCount = await iconLoader.requestCount()
        XCTAssertEqual(requestCount, 0)
    }

    func testEvictsLeastRecentlyResolvedAccentAtCacheLimit() async {
        let iconLoader = AccentIconDataLoader(data: nil)
        let provider = SystemApplicationAccentProvider(
            iconLoader: iconLoader,
            overrides: [:],
            maximumCachedApplicationCount: 1
        )

        _ = await provider.accent(bundleIdentifier: "com.example.first", localizedName: nil)
        _ = await provider.accent(bundleIdentifier: "com.example.second", localizedName: nil)
        _ = await provider.accent(bundleIdentifier: "com.example.first", localizedName: nil)

        let requestCount = await iconLoader.requestCount()
        XCTAssertEqual(requestCount, 3)
    }
}

private actor AccentIconDataLoader: ApplicationIconDataLoading {
    private let data: Data?
    private let delayNanoseconds: UInt64
    private var numberOfRequests = 0

    init(data: Data?, delayNanoseconds: UInt64 = 0) {
        self.data = data
        self.delayNanoseconds = delayNanoseconds
    }

    func iconData(forBundleIdentifier _: String) async -> Data? {
        numberOfRequests += 1
        if delayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: delayNanoseconds)
        }
        return data
    }

    func requestCount() -> Int {
        numberOfRequests
    }
}

private func makeImage(
    width: Int,
    height: Int,
    draw: (CGContext) -> Void
) throws -> CGImage {
    guard
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
    else {
        throw AccentTestError.couldNotCreateImage
    }

    draw(context)
    guard let image = context.makeImage() else {
        throw AccentTestError.couldNotCreateImage
    }
    return image
}

private func encodePNG(_ image: CGImage) throws -> Data {
    let data = NSMutableData()
    guard
        let destination = CGImageDestinationCreateWithData(
            data,
            UTType.png.identifier as CFString,
            1,
            nil
        )
    else {
        throw AccentTestError.couldNotEncodeImage
    }

    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        throw AccentTestError.couldNotEncodeImage
    }
    return data as Data
}

private enum AccentTestError: Error {
    case couldNotCreateImage
    case couldNotEncodeImage
}
