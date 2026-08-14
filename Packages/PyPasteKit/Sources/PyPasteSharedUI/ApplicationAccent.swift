import Foundation
import SwiftUI

public enum ApplicationAccentForeground: Sendable, Equatable {
    case black
    case white
}

public struct ApplicationAccent: Sendable, Equatable {
    public let red: Double
    public let green: Double
    public let blue: Double

    public init(red: Double, green: Double, blue: Double) {
        self.red = Self.clamp(red)
        self.green = Self.clamp(green)
        self.blue = Self.clamp(blue)
    }

    public var foreground: ApplicationAccentForeground {
        blackContrastRatio >= whiteContrastRatio ? .black : .white
    }

    public var backgroundColor: Color {
        Color(red: red, green: green, blue: blue)
    }

    public var foregroundColor: Color {
        switch foreground {
        case .black:
            .black
        case .white:
            .white
        }
    }

    public var preferredContrastRatio: Double {
        max(blackContrastRatio, whiteContrastRatio)
    }
}

extension ApplicationAccent {
    struct HSVComponents {
        let hue: Double
        let saturation: Double
        let brightness: Double
    }

    static func fromHSV(hue: Double, saturation: Double, brightness: Double) -> Self {
        let normalizedHue = hue - floor(hue)
        let normalizedSaturation = clamp(saturation)
        let normalizedBrightness = clamp(brightness)
        let scaledHue = normalizedHue * 6
        let sector = Int(floor(scaledHue)) % 6
        let fraction = scaledHue - floor(scaledHue)
        let lowerValue = normalizedBrightness * (1 - normalizedSaturation)
        let descendingValue = normalizedBrightness * (1 - fraction * normalizedSaturation)
        let ascendingValue = normalizedBrightness * (1 - (1 - fraction) * normalizedSaturation)

        switch sector {
        case 0:
            return Self(red: normalizedBrightness, green: ascendingValue, blue: lowerValue)
        case 1:
            return Self(red: descendingValue, green: normalizedBrightness, blue: lowerValue)
        case 2:
            return Self(red: lowerValue, green: normalizedBrightness, blue: ascendingValue)
        case 3:
            return Self(red: lowerValue, green: descendingValue, blue: normalizedBrightness)
        case 4:
            return Self(red: ascendingValue, green: lowerValue, blue: normalizedBrightness)
        default:
            return Self(red: normalizedBrightness, green: lowerValue, blue: descendingValue)
        }
    }

    static func deterministic(seed: String) -> Self {
        let hash = seed.utf8.reduce(UInt64(14_695_981_039_346_656_037)) { value, byte in
            (value ^ UInt64(byte)) &* 1_099_511_628_211
        }
        let hue = Double(hash % 360) / 360
        return fromHSV(hue: hue, saturation: 0.66, brightness: 0.82)
    }

    static func hsv(red: Double, green: Double, blue: Double) -> HSVComponents {
        let maximum = max(red, green, blue)
        let minimum = min(red, green, blue)
        let delta = maximum - minimum
        let saturation = maximum == 0 ? 0 : delta / maximum

        guard delta > 0 else {
            return HSVComponents(hue: 0, saturation: saturation, brightness: maximum)
        }

        let rawHue: Double
        if maximum == red {
            rawHue = ((green - blue) / delta).truncatingRemainder(dividingBy: 6)
        } else if maximum == green {
            rawHue = (blue - red) / delta + 2
        } else {
            rawHue = (red - green) / delta + 4
        }

        let hue = rawHue / 6
        return HSVComponents(
            hue: hue < 0 ? hue + 1 : hue,
            saturation: saturation,
            brightness: maximum
        )
    }

    private var blackContrastRatio: Double {
        (relativeLuminance + 0.05) / 0.05
    }

    private var whiteContrastRatio: Double {
        1.05 / (relativeLuminance + 0.05)
    }

    private var relativeLuminance: Double {
        0.2126 * Self.linearized(red)
            + 0.7152 * Self.linearized(green)
            + 0.0722 * Self.linearized(blue)
    }

    private static func linearized(_ component: Double) -> Double {
        component <= 0.04045
            ? component / 12.92
            : pow((component + 0.055) / 1.055, 2.4)
    }

    private static func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}
