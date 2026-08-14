import CryptoKit
import Foundation
import PyPasteDomain

public struct SHA256CanonicalHasher: CanonicalHashing {
    public init() {}

    public func hash(items: [ClipboardItemSnapshot]) -> String {
        var hasher = SHA256()

        for item in items.sorted(by: { $0.index < $1.index }) {
            update(&hasher, integer: item.index)

            let orderedRepresentations = item.representations.enumerated().sorted { left, right in
                let leftType = left.element.typeIdentifier.lowercased()
                let rightType = right.element.typeIdentifier.lowercased()

                if leftType == rightType {
                    return left.offset < right.offset
                }

                return leftType < rightType
            }

            for representation in orderedRepresentations.map(\.element)
            where representation.typeIdentifier != ClipboardConstants.internalMarkerType {
                let typeIdentifier = representation.typeIdentifier.lowercased()
                let canonicalData = canonicalData(for: representation)

                update(&hasher, data: Data(typeIdentifier.utf8))
                update(&hasher, data: canonicalData)
            }
        }

        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    private func canonicalData(for representation: ClipboardRepresentationSnapshot) -> Data {
        if PasteboardTypeClassifier.isPlainText(representation.typeIdentifier),
            let text = decodeString(from: representation.data)
        {
            let normalized =
                text
                .replacingOccurrences(of: "\r\n", with: "\n")
                .replacingOccurrences(of: "\r", with: "\n")
                .precomposedStringWithCanonicalMapping
            return Data(normalized.utf8)
        }

        if PasteboardTypeClassifier.isFileURL(representation.typeIdentifier),
            let value = decodeString(from: representation.data),
            let url = URL(string: value)
        {
            return Data(url.standardizedFileURL.absoluteString.utf8)
        }

        return representation.data
    }

    private func decodeString(from data: Data) -> String? {
        if let value = String(data: data, encoding: .utf8) {
            return value
        }

        if let propertyList = try? PropertyListSerialization.propertyList(from: data, format: nil),
            let value = propertyList as? String
        {
            return value
        }

        return nil
    }

    private func update(_ hasher: inout SHA256, data: Data) {
        update(&hasher, integer: data.count)
        hasher.update(data: data)
    }

    private func update(_ hasher: inout SHA256, integer: Int) {
        var value = UInt64(integer).bigEndian
        withUnsafeBytes(of: &value) { buffer in
            hasher.update(bufferPointer: buffer)
        }
    }
}
