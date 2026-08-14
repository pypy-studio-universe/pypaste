import Foundation
import UniformTypeIdentifiers

enum PasteboardTypeClassifier {
    private static let plainTextIdentifiers: Set<String> = [
        UTType.plainText.identifier,
        UTType.text.identifier,
        UTType.utf8PlainText.identifier,
        UTType.utf16PlainText.identifier,
        "NSStringPboardType",
    ]

    private static let fileURLIdentifiers: Set<String> = [
        UTType.fileURL.identifier,
        "NSFilenamesPboardType",
    ]

    private static let imageIdentifiersByExtension: [String: String] = [
        "avif": "public.avif",
        "bmp": "com.microsoft.bmp",
        "gif": UTType.gif.identifier,
        "heic": UTType.heic.identifier,
        "heif": UTType.heif.identifier,
        "jpeg": UTType.jpeg.identifier,
        "jpg": UTType.jpeg.identifier,
        "png": UTType.png.identifier,
        "tif": UTType.tiff.identifier,
        "tiff": UTType.tiff.identifier,
        "webp": "org.webmproject.webp",
    ]

    private static let imageIdentifiers = Set(imageIdentifiersByExtension.values)

    static func isPlainText(_ identifier: String) -> Bool {
        plainTextIdentifiers.contains(identifier)
            || UTType(identifier)?.conforms(to: .plainText) == true
    }

    static func isFileURL(_ identifier: String) -> Bool {
        fileURLIdentifiers.contains(identifier)
            || UTType(identifier)?.conforms(to: .fileURL) == true
    }

    static func isImage(_ identifier: String) -> Bool {
        imageIdentifiers.contains(identifier)
            || UTType(identifier)?.conforms(to: .image) == true
    }

    static func isGIF(_ identifier: String) -> Bool {
        identifier == UTType.gif.identifier
            || UTType(identifier)?.conforms(to: .gif) == true
    }

    static func imageTypeIdentifier(for url: URL) -> String? {
        let fileExtension = url.pathExtension.lowercased()

        if let contentType = UTType(filenameExtension: fileExtension),
            isImage(contentType.identifier)
        {
            return contentType.identifier
        }

        return imageIdentifiersByExtension[fileExtension]
    }
}
