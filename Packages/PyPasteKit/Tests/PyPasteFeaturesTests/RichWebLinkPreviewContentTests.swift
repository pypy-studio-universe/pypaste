import AppKit
import CoreGraphics
import PyPasteDomain
import SwiftUI
import XCTest

@testable import PyPasteFeatures

@MainActor
final class RichWebLinkPreviewContentTests: XCTestCase {
    func testImageAndCaptionOccupySeparateBoundedRegions() throws {
        let link = try XCTUnwrap(WebLinkPreview("https://example.com/floral-design"))
        let metadata = RichLinkMetadata(
            title: "Floral Design Studio",
            image: try makeSolidRedImage(width: 320, height: 180)
        )
        let content = RichWebLinkPreviewContent(link: link, metadata: metadata)
            .frame(width: 216, height: 99)
            .clipped()

        let renderer = ImageRenderer(content: content)
        renderer.scale = 1
        let renderedImage = try XCTUnwrap(renderer.nsImage)
        var proposedRect = NSRect(origin: .zero, size: renderedImage.size)
        let cgImage = try XCTUnwrap(
            renderedImage.cgImage(
                forProposedRect: &proposedRect,
                context: nil,
                hints: nil
            )
        )
        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        let redPixelRatio = redPixelRatio(in: bitmap)

        XCTAssertGreaterThan(redPixelRatio, 0.40)
        XCTAssertLessThan(redPixelRatio, 0.75)
        XCTAssertEqual(bitmap.pixelsWide, 216)
        XCTAssertEqual(bitmap.pixelsHigh, 99)
    }

    private func makeSolidRedImage(width: Int, height: Int) throws -> CGImage {
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
            throw RichLinkPreviewTestError.couldNotCreateImage
        }

        context.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        guard let image = context.makeImage() else {
            throw RichLinkPreviewTestError.couldNotCreateImage
        }

        return image
    }

    private func redPixelRatio(in image: NSBitmapImageRep) -> CGFloat {
        var redPixelCount = 0
        let totalPixelCount = image.pixelsWide * image.pixelsHigh

        for horizontalPixel in 0..<image.pixelsWide {
            for verticalPixel in 0..<image.pixelsHigh {
                guard
                    let color = image.colorAt(
                        x: horizontalPixel,
                        y: verticalPixel
                    )?.usingColorSpace(.deviceRGB)
                else {
                    continue
                }

                if color.redComponent > 0.75,
                    color.redComponent > color.greenComponent * 1.5,
                    color.redComponent > color.blueComponent * 1.5
                {
                    redPixelCount += 1
                }
            }
        }

        return CGFloat(redPixelCount) / CGFloat(max(1, totalPixelCount))
    }
}

private enum RichLinkPreviewTestError: Error {
    case couldNotCreateImage
}
