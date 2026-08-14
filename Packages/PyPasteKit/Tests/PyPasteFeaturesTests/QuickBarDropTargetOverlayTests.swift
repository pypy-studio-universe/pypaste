import AppKit
import PyPasteDomain
import SwiftUI
import XCTest

@testable import PyPasteFeatures

@MainActor
final class QuickBarDropTargetOverlayTests: XCTestCase {
    func testInsertionRailRendersOnPredictedEdge() throws {
        let targetClipID = UUID()
        let beforeImage = try renderOverlay(
            targetClipID: targetClipID,
            placement: .before
        )
        let afterImage = try renderOverlay(
            targetClipID: targetClipID,
            placement: .after
        )

        XCTAssertGreaterThan(
            edgeBrightness(of: beforeImage, edge: .leading),
            edgeBrightness(of: beforeImage, edge: .trailing) * 1.25
        )
        XCTAssertGreaterThan(
            edgeBrightness(of: afterImage, edge: .trailing),
            edgeBrightness(of: afterImage, edge: .leading) * 1.25
        )
        XCTAssertGreaterThan(centerBrightness(of: beforeImage), 0.12)
        XCTAssertGreaterThan(centerBrightness(of: afterImage), 0.12)
    }

    private func renderOverlay(
        targetClipID: Clip.ID,
        placement: ClipPlacement
    ) throws -> NSBitmapImageRep {
        let content = QuickBarDropTargetOverlay(
            preview: QuickBarDropPreview(
                targetClipID: targetClipID,
                placement: placement
            ),
            targetTitle: "Test clip"
        )
        .frame(width: 216, height: 162)
        .background(Color.black)
        .accentColor(.cyan)

        let renderer = ImageRenderer(content: content)
        renderer.scale = 1
        let image = try XCTUnwrap(renderer.nsImage)
        var proposedRect = NSRect(origin: .zero, size: image.size)
        let cgImage = try XCTUnwrap(
            image.cgImage(
                forProposedRect: &proposedRect,
                context: nil,
                hints: nil
            )
        )
        return NSBitmapImageRep(cgImage: cgImage)
    }

    private func edgeBrightness(
        of image: NSBitmapImageRep,
        edge: HorizontalEdge
    ) -> CGFloat {
        let edgeWidth = min(18, image.pixelsWide / 4)
        let xRange: Range<Int>
        switch edge {
        case .leading:
            xRange = 0..<edgeWidth
        case .trailing:
            xRange = (image.pixelsWide - edgeWidth)..<image.pixelsWide
        }

        let verticalInset = min(12, image.pixelsHigh / 4)
        let yRange = verticalInset..<(image.pixelsHigh - verticalInset)
        var total: CGFloat = 0
        var sampleCount = 0

        for horizontalPixel in xRange {
            for verticalPixel in yRange {
                guard
                    let color = image.colorAt(
                        x: horizontalPixel,
                        y: verticalPixel
                    )?.usingColorSpace(.deviceRGB)
                else {
                    continue
                }

                total +=
                    0.2126 * color.redComponent
                    + 0.7152 * color.greenComponent
                    + 0.0722 * color.blueComponent
                sampleCount += 1
            }
        }

        return sampleCount == 0 ? 0 : total / CGFloat(sampleCount)
    }

    private func centerBrightness(of image: NSBitmapImageRep) -> CGFloat {
        let centerX = image.pixelsWide / 2
        let centerY = image.pixelsHigh / 2
        guard
            let color = image.colorAt(x: centerX, y: centerY)?.usingColorSpace(.deviceRGB)
        else {
            return 0
        }

        return 0.2126 * color.redComponent
            + 0.7152 * color.greenComponent
            + 0.0722 * color.blueComponent
    }
}
