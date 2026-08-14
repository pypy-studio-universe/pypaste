import Foundation
import PyPasteDomain

public struct ClipSearchEngine: Sendable {
    private struct SearchField {
        let value: String
        let weight: Int
    }

    private struct RankedClip {
        let clip: Clip
        let score: Int
        let sourceIndex: Int
    }

    private static let contentKindAliases: [ClipContentKind: String] = [
        .text: "text plain van ban chữ",
        .richText: "rich text formatted html rtf van ban dinh dang",
        .url: "url link web website lien ket",
        .color: "color colour hex rgb mau",
        .emoji: "emoji icon bieu tuong",
        .image: "image photo picture screenshot anh hinh",
        .gif: "gif animation animated image anh dong",
        .pdf: "pdf document tai lieu",
        .file: "file document tep tai lieu",
        .multipleFiles: "multiple files folders nhieu tep thu muc",
        .unknown: "unknown other khac",
    ]

    public init() {}

    public func results(matching query: String, in clips: [Clip]) -> [Clip] {
        let normalizedQuery = normalize(query)
        guard !normalizedQuery.isEmpty else {
            return clips
        }

        let queryTokens = tokens(in: normalizedQuery)
        guard !queryTokens.isEmpty else {
            return clips
        }

        return clips.enumerated()
            .compactMap { index, clip -> RankedClip? in
                guard
                    let score = score(
                        clip,
                        normalizedQuery: normalizedQuery,
                        queryTokens: queryTokens
                    )
                else {
                    return nil
                }

                return RankedClip(clip: clip, score: score, sourceIndex: index)
            }
            .sorted { left, right in
                left.score == right.score
                    ? left.sourceIndex < right.sourceIndex
                    : left.score > right.score
            }
            .map(\.clip)
    }

    private func score(
        _ clip: Clip,
        normalizedQuery: String,
        queryTokens: [String]
    ) -> Int? {
        let fields = searchFields(for: clip).map { field in
            SearchField(value: normalize(field.value), weight: field.weight)
        }
        var totalScore = fields.reduce(into: 0) { score, field in
            if field.value == normalizedQuery {
                score = max(score, field.weight * 120)
            } else if field.value.contains(normalizedQuery) {
                score = max(score, field.weight * 90)
            }
        }

        for queryToken in queryTokens {
            let bestTokenScore =
                fields.map { field in
                    tokenScore(queryToken, in: field) * field.weight
                }.max() ?? 0

            guard bestTokenScore > 0 else {
                return nil
            }

            totalScore += bestTokenScore
        }

        return totalScore
    }

    private func tokenScore(_ queryToken: String, in field: SearchField) -> Int {
        let fieldTokens = tokens(in: field.value)

        if fieldTokens.contains(queryToken) {
            return 70
        }

        if fieldTokens.contains(where: { $0.hasPrefix(queryToken) }) {
            return 58
        }

        if field.value.contains(queryToken) {
            return 46
        }

        let allowedDistance = queryToken.count >= 8 ? 2 : queryToken.count >= 4 ? 1 : 0
        guard allowedDistance > 0 else {
            return 0
        }

        return fieldTokens.contains { candidate in
            abs(candidate.count - queryToken.count) <= allowedDistance
                && editDistance(
                    between: queryToken,
                    and: candidate,
                    limit: allowedDistance
                ) <= allowedDistance
        } ? 30 : 0
    }

    private func searchFields(for clip: Clip) -> [SearchField] {
        [
            SearchField(value: clip.displayTitle, weight: 6),
            SearchField(value: clip.searchableText ?? "", weight: 5),
            SearchField(value: clip.sourceApplication?.localizedName ?? "", weight: 4),
            SearchField(value: clip.sourceApplication?.bundleIdentifier ?? "", weight: 2),
            SearchField(value: Self.contentKindAliases[clip.contentKind, default: ""], weight: 3),
        ]
    }

    private func normalize(_ value: String) -> String {
        let folded =
            value
            .folding(
                options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive],
                locale: Locale(identifier: "en_US_POSIX")
            )
            .replacingOccurrences(of: "đ", with: "d")
            .replacingOccurrences(of: "Đ", with: "d")
        let separators = CharacterSet.alphanumerics.inverted
        return
            folded
            .components(separatedBy: separators)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private func tokens(in value: String) -> [String] {
        value.split(separator: " ").map(String.init)
    }

    private func editDistance(
        between left: String,
        and right: String,
        limit: Int
    ) -> Int {
        let leftCharacters = Array(left)
        let rightCharacters = Array(right)

        guard abs(leftCharacters.count - rightCharacters.count) <= limit else {
            return limit + 1
        }

        var previousRow = Array(0...rightCharacters.count)
        for (leftIndex, leftCharacter) in leftCharacters.enumerated() {
            var currentRow = [leftIndex + 1]
            var rowMinimum = currentRow[0]

            for (rightIndex, rightCharacter) in rightCharacters.enumerated() {
                let insertion = currentRow[rightIndex] + 1
                let deletion = previousRow[rightIndex + 1] + 1
                let substitution =
                    previousRow[rightIndex] + (leftCharacter == rightCharacter ? 0 : 1)
                let value = min(insertion, deletion, substitution)
                currentRow.append(value)
                rowMinimum = min(rowMinimum, value)
            }

            if rowMinimum > limit {
                return limit + 1
            }

            previousRow = currentRow
        }

        return previousRow.last ?? limit + 1
    }
}
