import Foundation
import PyPasteDomain
import UniformTypeIdentifiers
import XCTest

@testable import PyPasteCore

final class SmartContentDetectionTests: XCTestCase {
    func testHexColorParserNormalizesSupportedFormats() throws {
        let shortColor = try XCTUnwrap(HexColor(" #3aF "))
        let alphaColor = try XCTUnwrap(HexColor("#11223380"))

        XCTAssertEqual(shortColor.canonicalCode, "#33AAFF")
        XCTAssertEqual(shortColor.red, Double(0x33) / 255, accuracy: 0.001)
        XCTAssertEqual(shortColor.green, Double(0xAA) / 255, accuracy: 0.001)
        XCTAssertEqual(shortColor.blue, 1, accuracy: 0.001)
        XCTAssertEqual(alphaColor.alpha, Double(0x80) / 255, accuracy: 0.001)
        XCTAssertNil(HexColor("112233"))
        XCTAssertNil(HexColor("#12XY56"))
    }

    func testProcessorDetectsHexColorAndPlainTextWebURL() async throws {
        let processor = ClipboardContentProcessor()
        let colorSnapshot = snapshot(changeCount: 1, text: "#5ab82c")
        let urlSnapshot = snapshot(
            changeCount: 2,
            text: "https://www.example.com/docs/start?q=swift"
        )

        let processedColor = await processor.makeClip(
            from: colorSnapshot,
            sourceApplication: nil
        )
        let processedURL = await processor.makeClip(
            from: urlSnapshot,
            sourceApplication: nil
        )
        let colorClip = try XCTUnwrap(processedColor)
        let urlClip = try XCTUnwrap(processedURL)
        let preview = try XCTUnwrap(urlClip.searchableText.flatMap(WebLinkPreview.init))

        XCTAssertEqual(colorClip.contentKind, .color)
        XCTAssertEqual(colorClip.displayTitle, "#5AB82C")
        XCTAssertEqual(urlClip.contentKind, .url)
        XCTAssertEqual(urlClip.displayTitle, "example.com")
        XCTAssertEqual(preview.pathSummary, "/docs/start?q=swift")
    }

    private func snapshot(changeCount: Int, text: String) -> ClipboardSnapshot {
        let representation = ClipboardRepresentationSnapshot(
            typeIdentifier: UTType.utf8PlainText.identifier,
            data: Data(text.utf8)
        )
        let item = ClipboardItemSnapshot(index: 0, representations: [representation])
        return ClipboardSnapshot(changeCount: changeCount, items: [item])
    }
}
