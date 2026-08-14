import Foundation

public struct HexColor: Equatable, Sendable {
    public let canonicalCode: String
    public let red: Double
    public let green: Double
    public let blue: Double
    public let alpha: Double

    public init?(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmed.first == "#" else {
            return nil
        }

        let source = String(trimmed.dropFirst())
        guard [3, 4, 6, 8].contains(source.count), source.allSatisfy(\.isHexDigit) else {
            return nil
        }

        let expanded: String
        if source.count <= 4 {
            expanded = source.map { "\($0)\($0)" }.joined()
        } else {
            expanded = source
        }

        guard
            let red = Self.component(in: expanded, offset: 0),
            let green = Self.component(in: expanded, offset: 2),
            let blue = Self.component(in: expanded, offset: 4)
        else {
            return nil
        }

        let alpha = expanded.count == 8 ? Self.component(in: expanded, offset: 6) : 255
        guard let alpha else {
            return nil
        }

        canonicalCode = "#\(expanded.uppercased())"
        self.red = Double(red) / 255
        self.green = Double(green) / 255
        self.blue = Double(blue) / 255
        self.alpha = Double(alpha) / 255
    }

    public var prefersDarkForeground: Bool {
        let luminance = red * 0.299 + green * 0.587 + blue * 0.114
        return luminance > 0.58
    }

    private static func component(in value: String, offset: Int) -> UInt8? {
        let start = value.index(value.startIndex, offsetBy: offset)
        let end = value.index(start, offsetBy: 2)
        return UInt8(value[start..<end], radix: 16)
    }
}
