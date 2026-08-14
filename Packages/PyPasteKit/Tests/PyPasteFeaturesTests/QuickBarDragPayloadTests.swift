import Foundation
import PyPasteDomain
import UniformTypeIdentifiers
import XCTest

@testable import PyPasteFeatures

final class QuickBarDragPayloadTests: XCTestCase {
    func testProviderExportsInternalMarkerAndOriginalRepresentations() async throws {
        let plainText = Data("PyPaste text".utf8)
        let html = Data("<strong>PyPaste text</strong>".utf8)
        let clip = makeClip(
            contentKind: .richText,
            searchableText: "PyPaste text",
            representations: [
                representation(order: 0, type: UTType.html.identifier, data: html),
                representation(order: 1, type: UTType.utf8PlainText.identifier, data: plainText),
            ]
        )

        let provider = QuickBarDragPayload.itemProvider(for: clip)
        let exportedHTML = try await data(from: provider, type: UTType.html.identifier)
        let exportedText = try await data(from: provider, type: UTType.utf8PlainText.identifier)

        XCTAssertTrue(
            provider.hasItemConformingToTypeIdentifier(QuickBarDragPayload.contentType.identifier))
        XCTAssertEqual(exportedHTML, html)
        XCTAssertEqual(exportedText, plainText)
    }

    func testProviderExportsImageDataWithoutReplacingItWithTitleText() async throws {
        let imageData = Data([0x89, 0x50, 0x4E, 0x47])
        let clip = makeClip(
            contentKind: .image,
            searchableText: "Image",
            representations: [
                representation(order: 0, type: UTType.png.identifier, data: imageData)
            ]
        )

        let provider = QuickBarDragPayload.itemProvider(for: clip)
        let exportedImage = try await data(from: provider, type: UTType.png.identifier)

        XCTAssertEqual(exportedImage, imageData)
        XCTAssertFalse(provider.hasItemConformingToTypeIdentifier(UTType.utf8PlainText.identifier))
    }

    func testProviderAddsPlainTextFallbackForTextLikeClipWithoutRepresentations() async throws {
        let clip = makeClip(
            contentKind: .url,
            searchableText: "https://pypaste.app",
            representations: []
        )

        let provider = QuickBarDragPayload.itemProvider(for: clip)

        let exportedData = try await data(from: provider, type: UTType.utf8PlainText.identifier)
        XCTAssertEqual(String(data: exportedData, encoding: .utf8), "https://pypaste.app")
    }

    func testProviderDeduplicatesTypesUsingFirstRepresentationInClipboardOrder() async throws {
        let first = Data("first item".utf8)
        let second = Data("second item".utf8)
        let clip = makeClip(
            contentKind: .text,
            searchableText: "first item",
            representations: [
                representation(
                    itemIndex: 1, order: 0, type: UTType.utf8PlainText.identifier, data: second),
                representation(
                    itemIndex: 0, order: 0, type: UTType.utf8PlainText.identifier, data: first),
            ]
        )

        let provider = QuickBarDragPayload.itemProvider(for: clip)
        let exportedText = try await data(from: provider, type: UTType.utf8PlainText.identifier)

        XCTAssertEqual(exportedText, first)
    }

    private func makeClip(
        contentKind: ClipContentKind,
        searchableText: String?,
        representations: [ClipRepresentation]
    ) -> Clip {
        Clip(
            contentKind: contentKind,
            displayTitle: "Drag test",
            searchableText: searchableText,
            contentHash: UUID().uuidString,
            representations: representations
        )
    }

    private func representation(
        itemIndex: Int = 0,
        order: Int,
        type: String,
        data: Data
    ) -> ClipRepresentation {
        ClipRepresentation(
            itemIndex: itemIndex,
            order: order,
            typeIdentifier: type,
            data: data
        )
    }

    private func data(from provider: NSItemProvider, type: String) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            provider.loadDataRepresentation(forTypeIdentifier: type) { data, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: MissingProviderDataError())
                }
            }
        }
    }
}

private struct MissingProviderDataError: Error {}
