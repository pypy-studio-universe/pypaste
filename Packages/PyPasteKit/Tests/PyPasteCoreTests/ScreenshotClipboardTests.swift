import AppKit
import CoreGraphics
import Darwin
import Foundation
import ImageIO
import PyPasteDomain
import UniformTypeIdentifiers
import XCTest

@testable import PyPasteCore

final class ScreenshotClipboardTests: XCTestCase {
    @MainActor
    func testDirectoryEventAutomaticallyPublishesNewScreenshot() async throws {
        let directoryURL = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directoryURL) }

        let monitor = ScreenshotCaptureMonitor(
            location: ScreenshotLocation(directoryURL: directoryURL),
            recognizer: ScreenshotFileRecognizer(),
            logger: NoOpLogger(),
            debounceDuration: .milliseconds(10)
        )
        var capturedFileNames: [String] = []
        monitor.onScreenshotCreated = { capturedFileNames.append($0.lastPathComponent) }
        monitor.start()
        defer { monitor.stop() }

        let screenshotURL = directoryURL.appendingPathComponent("Screenshot automatic.png")
        try Data([0x01]).write(to: screenshotURL)

        for _ in 0..<100 where capturedFileNames.isEmpty {
            try await Task.sleep(for: .milliseconds(10))
        }

        XCTAssertEqual(capturedFileNames, [screenshotURL.lastPathComponent])
    }

    @MainActor
    func testMonitorIgnoresExistingAndNonScreenshotImages() throws {
        let directoryURL = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directoryURL) }

        let existingScreenshot = directoryURL.appendingPathComponent("Screenshot existing.png")
        try Data([0x01]).write(to: existingScreenshot)

        let monitor = ScreenshotCaptureMonitor(
            location: ScreenshotLocation(directoryURL: directoryURL),
            recognizer: ScreenshotFileRecognizer(),
            logger: NoOpLogger(),
            debounceDuration: .milliseconds(1)
        )
        var capturedURLs: [URL] = []
        monitor.onScreenshotCreated = { capturedURLs.append($0) }
        monitor.start()
        defer { monitor.stop() }

        let ordinaryImage = directoryURL.appendingPathComponent("holiday.png")
        let newScreenshot = directoryURL.appendingPathComponent("Screenshot new.png")
        try Data([0x02]).write(to: ordinaryImage)
        try Data([0x03]).write(to: newScreenshot)

        monitor.scanForChanges()

        XCTAssertEqual(capturedURLs.map(\.lastPathComponent), [newScreenshot.lastPathComponent])
    }

    func testRecognizerUsesScreenCaptureMetadataForLocalizedFileName() throws {
        let directoryURL = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directoryURL) }

        let screenshotURL = directoryURL.appendingPathComponent("Ảnh chụp màn hình.png")
        try Data([0x01]).write(to: screenshotURL)
        try setScreenshotMetadata(on: screenshotURL)

        XCTAssertTrue(ScreenshotFileRecognizer().isScreenshot(screenshotURL))
    }

    @MainActor
    func testWriterPublishesOriginalImageWithoutPyPasteMarker() async throws {
        let directoryURL = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directoryURL) }

        let screenshotURL = directoryURL.appendingPathComponent("Screenshot writer.png")
        let originalData = try makePNG()
        try originalData.write(to: screenshotURL)

        let pasteboardName = "com.pypaste.screenshot-tests.\(UUID().uuidString)"
        let writer = SystemScreenshotPasteboardWriter(
            pasteboardName: pasteboardName,
            maximumReadAttempts: 1
        )
        let pasteboard = SystemPasteboard(name: pasteboardName)

        _ = try await writer.writeScreenshot(at: screenshotURL)
        let snapshot = try await pasteboard.snapshot()

        XCTAssertFalse(snapshot.containsInternalMarker)
        XCTAssertEqual(snapshot.items.count, 1)
        XCTAssertEqual(snapshot.items.first?.representations.first?.data, originalData)
    }

    @MainActor
    func testServiceConnectsMonitorToPasteboardWriter() async throws {
        let monitor = FakeScreenshotMonitor()
        let writer = FakeScreenshotWriter()
        let service = ScreenshotClipboardService(
            monitor: monitor,
            writer: writer,
            logger: NoOpLogger()
        )
        let screenshotURL = URL(fileURLWithPath: "/tmp/Screenshot service.png")

        service.start()
        monitor.emit(screenshotURL)

        var writtenURLs: [URL] = []
        for _ in 0..<100 {
            writtenURLs = await writer.writtenURLs
            if writtenURLs == [screenshotURL] {
                break
            }

            try await Task.sleep(for: .milliseconds(10))
        }
        service.stop()

        XCTAssertEqual(writtenURLs, [screenshotURL])
        XCTAssertEqual(monitor.startCount, 1)
        XCTAssertEqual(monitor.stopCount, 1)
    }

    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("PyPasteScreenshotTests")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func setScreenshotMetadata(on url: URL) throws {
        let result: Int32 = url.withUnsafeFileSystemRepresentation { fileSystemPath in
            guard let fileSystemPath else {
                return Int32(-1)
            }

            var value: UInt8 = 1
            return Darwin.setxattr(
                fileSystemPath,
                "com.apple.metadata:kMDItemIsScreenCapture",
                &value,
                MemoryLayout<UInt8>.size,
                0,
                0
            )
        }

        guard result == 0 else {
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }
    }

    @MainActor
    private func makePNG() throws -> Data {
        let context = try XCTUnwrap(
            CGContext(
                data: nil,
                width: 2,
                height: 1,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        )
        context.setFillColor(CGColor(red: 0.1, green: 0.4, blue: 0.9, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 2, height: 1))

        let image = try XCTUnwrap(context.makeImage())
        let data = NSMutableData()
        let destination = try XCTUnwrap(
            CGImageDestinationCreateWithData(
                data,
                UTType.png.identifier as CFString,
                1,
                nil
            )
        )
        CGImageDestinationAddImage(destination, image, nil)
        XCTAssertTrue(CGImageDestinationFinalize(destination))
        return data as Data
    }

}

@MainActor
private final class FakeScreenshotMonitor: ScreenshotCaptureMonitoring {
    var onScreenshotCreated: ((URL) -> Void)?
    private(set) var startCount = 0
    private(set) var stopCount = 0

    func start() {
        startCount += 1
    }

    func stop() {
        stopCount += 1
    }

    func emit(_ url: URL) {
        onScreenshotCreated?(url)
    }
}

private actor FakeScreenshotWriter: ScreenshotPasteboardWriting {
    private(set) var writtenURLs: [URL] = []

    func writeScreenshot(at url: URL) async throws -> Int {
        writtenURLs.append(url)
        return writtenURLs.count
    }
}
