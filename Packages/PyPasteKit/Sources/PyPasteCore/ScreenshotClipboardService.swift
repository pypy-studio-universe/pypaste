import AppKit
import Foundation
import PyPasteDomain

public protocol ScreenshotPasteboardWriting: Sendable {
    func writeScreenshot(at url: URL) async throws -> Int
}

public enum ScreenshotPasteboardError: LocalizedError {
    case unsupportedImage
    case unreadableImage
    case writeFailed

    public var errorDescription: String? {
        switch self {
        case .unsupportedImage:
            "The screenshot image format is not supported."
        case .unreadableImage:
            "The screenshot file could not be read."
        case .writeFailed:
            "The screenshot could not be written to the clipboard."
        }
    }
}

public actor SystemScreenshotPasteboardWriter: ScreenshotPasteboardWriting {
    private let pasteboardName: String?
    private let maximumReadAttempts: Int
    private let retryDelay: Duration

    public init(
        pasteboardName: String? = nil,
        maximumReadAttempts: Int = 4,
        retryDelay: Duration = .milliseconds(150)
    ) {
        self.pasteboardName = pasteboardName
        self.maximumReadAttempts = max(maximumReadAttempts, 1)
        self.retryDelay = retryDelay
    }

    public func writeScreenshot(at url: URL) async throws -> Int {
        guard let typeIdentifier = PasteboardTypeClassifier.imageTypeIdentifier(for: url) else {
            throw ScreenshotPasteboardError.unsupportedImage
        }

        let data = try await readCompletedFile(at: url)
        let item = NSPasteboardItem()
        item.setData(data, forType: NSPasteboard.PasteboardType(typeIdentifier))

        let pasteboard = activePasteboard
        pasteboard.clearContents()

        guard pasteboard.writeObjects([item]) else {
            throw ScreenshotPasteboardError.writeFailed
        }

        return pasteboard.changeCount
    }

    private var activePasteboard: NSPasteboard {
        if let pasteboardName {
            return NSPasteboard(name: NSPasteboard.Name(pasteboardName))
        }

        return .general
    }

    private func readCompletedFile(at url: URL) async throws -> Data {
        for attempt in 0..<maximumReadAttempts {
            if let data = try? Data(contentsOf: url, options: .mappedIfSafe), !data.isEmpty {
                return data
            }

            if attempt < maximumReadAttempts - 1 {
                try await Task.sleep(for: retryDelay)
            }
        }

        throw ScreenshotPasteboardError.unreadableImage
    }
}

@MainActor
public protocol ScreenshotClipboardCapturing: AnyObject {
    func start()
    func stop()
}

@MainActor
public final class ScreenshotClipboardService: ScreenshotClipboardCapturing {
    private let monitor: any ScreenshotCaptureMonitoring
    private let writer: any ScreenshotPasteboardWriting
    private let logger: any AppLogging

    public convenience init(logger: any AppLogging) {
        self.init(
            monitor: ScreenshotCaptureMonitor(logger: logger),
            writer: SystemScreenshotPasteboardWriter(),
            logger: logger
        )
    }

    public init(
        monitor: any ScreenshotCaptureMonitoring,
        writer: any ScreenshotPasteboardWriting,
        logger: any AppLogging
    ) {
        self.monitor = monitor
        self.writer = writer
        self.logger = logger
    }

    public func start() {
        monitor.onScreenshotCreated = { [weak self] url in
            self?.copyScreenshot(at: url)
        }
        monitor.start()
    }

    public func stop() {
        monitor.stop()
        monitor.onScreenshotCreated = nil
    }

    private func copyScreenshot(at url: URL) {
        Task { [writer, logger] in
            do {
                _ = try await writer.writeScreenshot(at: url)
                logger.notice("Saved a new screenshot to the clipboard")
            } catch {
                logger.error(
                    "Saving a screenshot to the clipboard failed: \(error.localizedDescription)"
                )
            }
        }
    }
}
