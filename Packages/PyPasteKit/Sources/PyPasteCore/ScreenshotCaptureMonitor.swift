import Darwin
import Foundation
import PyPasteDomain

@MainActor
public protocol ScreenshotCaptureMonitoring: AnyObject {
    var onScreenshotCreated: ((URL) -> Void)? { get set }

    func start()
    func stop()
}

public struct ScreenshotFileRecognizer: Sendable {
    private static let screenCaptureMetadataKey =
        "com.apple.metadata:kMDItemIsScreenCapture"

    private let configuredBaseName: String?

    public init(configuredBaseName: String? = nil) {
        let normalizedName = configuredBaseName?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.configuredBaseName = normalizedName?.isEmpty == false ? normalizedName : nil
    }

    public func isScreenshot(_ url: URL) -> Bool {
        guard isSupportedImage(url) else {
            return false
        }

        return hasScreenCaptureMetadata(url) || hasScreenshotFileName(url)
    }

    private func isSupportedImage(_ url: URL) -> Bool {
        PasteboardTypeClassifier.imageTypeIdentifier(for: url) != nil
    }

    private func hasScreenCaptureMetadata(_ url: URL) -> Bool {
        url.withUnsafeFileSystemRepresentation { fileSystemPath in
            guard let fileSystemPath else {
                return false
            }

            return Darwin.getxattr(
                fileSystemPath,
                Self.screenCaptureMetadataKey,
                nil,
                0,
                0,
                0
            ) > 0
        }
    }

    private func hasScreenshotFileName(_ url: URL) -> Bool {
        let fileName = url.deletingPathExtension().lastPathComponent
        let baseNames = [configuredBaseName, "Screenshot", "Screen Shot"].compactMap { $0 }

        return baseNames.contains { baseName in
            fileName == baseName || fileName.hasPrefix("\(baseName) ")
        }
    }
}

public struct ScreenshotLocation: Equatable, Sendable {
    public let directoryURL: URL
    public let configuredBaseName: String?

    public init(directoryURL: URL, configuredBaseName: String? = nil) {
        self.directoryURL = directoryURL
        self.configuredBaseName = configuredBaseName
    }
}

public struct SystemScreenshotLocationResolver {
    private static let preferencesDomain = "com.apple.screencapture"

    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func resolve() -> ScreenshotLocation? {
        let preferences = UserDefaults.standard.persistentDomain(
            forName: Self.preferencesDomain
        )
        let configuredBaseName = preferences?["name"] as? String

        if let location = preferences?["location"] as? String,
            let directoryURL = directoryURL(from: location)
        {
            return ScreenshotLocation(
                directoryURL: directoryURL,
                configuredBaseName: configuredBaseName
            )
        }

        guard
            let desktopURL = fileManager.urls(
                for: .desktopDirectory,
                in: .userDomainMask
            ).first
        else {
            return nil
        }

        return ScreenshotLocation(
            directoryURL: desktopURL,
            configuredBaseName: configuredBaseName
        )
    }

    private func directoryURL(from configuredLocation: String) -> URL? {
        let url: URL

        if let fileURL = URL(string: configuredLocation), fileURL.isFileURL {
            url = fileURL
        } else {
            url = URL(
                fileURLWithPath: (configuredLocation as NSString).expandingTildeInPath,
                isDirectory: true
            )
        }

        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory),
            isDirectory.boolValue
        else {
            return nil
        }

        return url.standardizedFileURL
    }
}

@MainActor
public final class ScreenshotCaptureMonitor: ScreenshotCaptureMonitoring {
    public var onScreenshotCreated: ((URL) -> Void)?

    private let location: ScreenshotLocation?
    private let recognizer: ScreenshotFileRecognizer
    private let logger: any AppLogging
    private let debounceDuration: Duration
    private var knownPaths: Set<String> = []
    private var directorySource: DispatchSourceFileSystemObject?
    private var scanTask: Task<Void, Never>?

    public convenience init(logger: any AppLogging) {
        let location = SystemScreenshotLocationResolver().resolve()
        self.init(
            location: location,
            recognizer: ScreenshotFileRecognizer(
                configuredBaseName: location?.configuredBaseName
            ),
            logger: logger
        )
    }

    public init(
        location: ScreenshotLocation?,
        recognizer: ScreenshotFileRecognizer,
        logger: any AppLogging,
        debounceDuration: Duration = .milliseconds(450)
    ) {
        self.location = location
        self.recognizer = recognizer
        self.logger = logger
        self.debounceDuration = debounceDuration
    }

    deinit {
        directorySource?.cancel()
        scanTask?.cancel()
    }

    public func start() {
        guard directorySource == nil else {
            return
        }

        guard let directoryURL = location?.directoryURL else {
            logger.notice("Screenshot monitoring unavailable because no file destination exists")
            return
        }

        knownPaths = Set(directoryContents(at: directoryURL).map(\.path))

        let descriptor = Darwin.open(directoryURL.path, O_EVTONLY)
        guard descriptor >= 0 else {
            logger.error("Screenshot monitoring could not open its configured directory")
            return
        }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.write, .extend, .attrib, .rename],
            queue: .main
        )
        source.setEventHandler { [weak self] in
            Task { @MainActor [weak self] in
                self?.scheduleScan()
            }
        }
        source.setCancelHandler {
            Darwin.close(descriptor)
        }
        source.resume()
        directorySource = source
        logger.notice("Screenshot directory monitoring started")
    }

    public func stop() {
        scanTask?.cancel()
        scanTask = nil
        directorySource?.cancel()
        directorySource = nil
        knownPaths.removeAll(keepingCapacity: false)
        logger.notice("Screenshot directory monitoring stopped")
    }

    func scanForChanges() {
        guard let directoryURL = location?.directoryURL else {
            return
        }

        let currentURLs = directoryContents(at: directoryURL)
        let currentPaths = Set(currentURLs.map(\.path))
        let newPaths = currentPaths.subtracting(knownPaths)
        knownPaths = currentPaths

        currentURLs
            .filter { newPaths.contains($0.path) && recognizer.isScreenshot($0) }
            .sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
            .forEach { onScreenshotCreated?($0) }
    }

    private func scheduleScan() {
        scanTask?.cancel()
        scanTask = Task { [weak self] in
            guard let self else {
                return
            }

            try? await Task.sleep(for: debounceDuration)
            guard !Task.isCancelled else {
                return
            }

            scanForChanges()
        }
    }

    private func directoryContents(at directoryURL: URL) -> [URL] {
        do {
            return try FileManager.default.contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
                options: [.skipsHiddenFiles]
            )
        } catch {
            logger.error("Screenshot directory scan failed: \(error.localizedDescription)")
            return []
        }
    }
}
