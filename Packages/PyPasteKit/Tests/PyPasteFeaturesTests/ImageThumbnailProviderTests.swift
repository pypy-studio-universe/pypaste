import CoreGraphics
import Foundation
import ImageIO
import PyPasteDomain
import UniformTypeIdentifiers
import XCTest

@testable import PyPasteFeatures

final class ImageThumbnailProviderTests: XCTestCase {
    func testCreatesThumbnailFromValidPNG() async throws {
        let data = try makePNG(width: 40, height: 20)
        let clip = makeImageClip(
            representations: [imageRepresentation(data: data)]
        )

        let thumbnail = await ImageThumbnailProvider().thumbnail(
            for: clip,
            maximumPixelSize: 128
        )

        let image = try XCTUnwrap(thumbnail)
        XCTAssertEqual(image.width, 40)
        XCTAssertEqual(image.height, 20)
    }

    func testReturnsNilForCorruptImageData() async {
        let clip = makeImageClip(
            representations: [imageRepresentation(data: Data([0x00, 0x01, 0x02]))]
        )

        let thumbnail = await ImageThumbnailProvider().thumbnail(for: clip)

        XCTAssertNil(thumbnail)
    }

    func testDownsamplesThumbnailToMaximumPixelSize() async throws {
        let data = try makePNG(width: 240, height: 120)
        let clip = makeImageClip(
            representations: [imageRepresentation(data: data)]
        )

        let thumbnail = await ImageThumbnailProvider().thumbnail(
            for: clip,
            maximumPixelSize: 60
        )

        let image = try XCTUnwrap(thumbnail)
        XCTAssertEqual(image.width, 60)
        XCTAssertEqual(image.height, 30)
    }

    func testUsesFirstValidImageInPasteboardOrder() async throws {
        let laterItemData = try makePNG(width: 21, height: 9)
        let firstValidData = try makePNG(width: 11, height: 7)
        let clip = makeImageClip(
            representations: [
                imageRepresentation(
                    itemIndex: 1,
                    order: 0,
                    data: laterItemData
                ),
                imageRepresentation(
                    itemIndex: 0,
                    order: 0,
                    data: Data([0xFF])
                ),
                ClipRepresentation(
                    itemIndex: 0,
                    order: 1,
                    typeIdentifier: UTType.utf8PlainText.identifier,
                    data: laterItemData
                ),
                imageRepresentation(
                    itemIndex: 0,
                    order: 2,
                    data: firstValidData
                ),
            ]
        )

        let thumbnail = await ImageThumbnailProvider().thumbnail(
            for: clip,
            maximumPixelSize: 128
        )

        let image = try XCTUnwrap(thumbnail)
        XCTAssertEqual(image.width, 11)
        XCTAssertEqual(image.height, 7)
    }

    private func makeImageClip(representations: [ClipRepresentation]) -> Clip {
        Clip(
            contentKind: .image,
            displayTitle: "Image",
            contentHash: UUID().uuidString,
            representations: representations
        )
    }

    private func imageRepresentation(
        itemIndex: Int = 0,
        order: Int = 0,
        data: Data
    ) -> ClipRepresentation {
        ClipRepresentation(
            itemIndex: itemIndex,
            order: order,
            typeIdentifier: UTType.png.identifier,
            data: data
        )
    }

    private func makePNG(width: Int, height: Int) throws -> Data {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard
            let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else {
            throw ThumbnailTestError.couldNotCreateImage
        }

        context.setFillColor(CGColor(red: 0.2, green: 0.5, blue: 0.8, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        guard let image = context.makeImage() else {
            throw ThumbnailTestError.couldNotCreateImage
        }

        let data = NSMutableData()
        guard
            let destination = CGImageDestinationCreateWithData(
                data,
                UTType.png.identifier as CFString,
                1,
                nil
            )
        else {
            throw ThumbnailTestError.couldNotEncodeImage
        }

        CGImageDestinationAddImage(destination, image, nil)

        guard CGImageDestinationFinalize(destination) else {
            throw ThumbnailTestError.couldNotEncodeImage
        }

        return data as Data
    }
}

private enum ThumbnailTestError: Error {
    case couldNotCreateImage
    case couldNotEncodeImage
}
