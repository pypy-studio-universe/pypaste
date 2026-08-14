#!/usr/bin/env swift
import AppKit
import Foundation

private enum MenuBarIconGenerator {
    static let canvasSize: CGFloat = 18
    static let fontSize: CGFloat = 12
    static let kerning: CGFloat = -0.35
    static let filenames = [
        1: "MenuBarIcon.png",
        2: "MenuBarIcon@2x.png",
    ]

    static func generate(in outputDirectory: URL) throws {
        for scale in filenames.keys.sorted() {
            let imageData = try renderPNG(scale: scale)
            guard let filename = filenames[scale] else {
                continue
            }
            let outputURL = outputDirectory.appendingPathComponent(filename)
            try imageData.write(to: outputURL, options: .atomic)
        }
    }

    private static func renderPNG(scale: Int) throws -> Data {
        let pixelSize = Int(canvasSize) * scale
        guard
            let bitmap = NSBitmapImageRep(
                bitmapDataPlanes: nil,
                pixelsWide: pixelSize,
                pixelsHigh: pixelSize,
                bitsPerSample: 8,
                samplesPerPixel: 4,
                hasAlpha: true,
                isPlanar: false,
                colorSpaceName: .deviceRGB,
                bytesPerRow: 0,
                bitsPerPixel: 0
            )
        else {
            throw GenerationError.couldNotCreateBitmap
        }

        bitmap.size = NSSize(width: canvasSize, height: canvasSize)
        guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
            throw GenerationError.couldNotCreateContext
        }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        context.imageInterpolation = .high
        context.shouldAntialias = true
        context.cgContext.clear(
            CGRect(x: 0, y: 0, width: canvasSize, height: canvasSize)
        )

        let systemFont = NSFont.systemFont(ofSize: fontSize, weight: .bold)
        let font =
            systemFont.fontDescriptor.withDesign(.rounded)
            .flatMap { NSFont(descriptor: $0, size: fontSize) }
            ?? systemFont
        let monogram = NSAttributedString(
            string: "py",
            attributes: [
                .font: font,
                .foregroundColor: NSColor.black,
                .kern: kerning,
            ]
        )
        let monogramSize = monogram.size()
        let origin = NSPoint(
            x: (canvasSize - monogramSize.width) / 2,
            y: (canvasSize - monogramSize.height) / 2 + 0.25
        )
        monogram.draw(at: origin)
        context.flushGraphics()
        NSGraphicsContext.restoreGraphicsState()

        guard let imageData = bitmap.representation(using: .png, properties: [:]) else {
            throw GenerationError.couldNotEncodePNG
        }
        return imageData
    }
}

private enum GenerationError: Error {
    case couldNotCreateBitmap
    case couldNotCreateContext
    case couldNotEncodePNG
}

let defaultOutputDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("App/Resources/Assets.xcassets/MenuBarIcon.imageset")
let outputDirectory =
    CommandLine.arguments.dropFirst().first
    .map { URL(fileURLWithPath: $0, isDirectory: true) }
    ?? defaultOutputDirectory

try MenuBarIconGenerator.generate(in: outputDirectory)
