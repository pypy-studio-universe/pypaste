import PyPasteDomain
import XCTest

@testable import PyPasteFeatures

final class ClipSearchEngineTests: XCTestCase {
    private let searchEngine = ClipSearchEngine()

    func testSearchIgnoresCaseAndVietnameseDiacritics() {
        let clips = [
            makeClip(title: "Địa chỉ giao hàng", text: "Quận Bình Thạnh"),
            makeClip(title: "Meeting notes", text: "Product roadmap"),
        ]

        XCTAssertEqual(
            searchEngine.results(matching: "dia chi", in: clips).map(\.id),
            [clips[0].id]
        )
        XCTAssertEqual(
            searchEngine.results(matching: "BINH thanh", in: clips).map(\.id),
            [clips[0].id]
        )
    }

    func testSearchMatchesTitleContentApplicationBundleAndType() {
        let chromeLink = makeClip(
            title: "Design inspiration",
            text: "https://example.com/floral-studio",
            kind: .url,
            appName: "Google Chrome",
            bundleIdentifier: "com.google.Chrome"
        )
        let finderImage = makeClip(
            title: "Image",
            text: nil,
            kind: .image,
            appName: "Finder",
            bundleIdentifier: "com.apple.finder"
        )

        XCTAssertEqual(
            searchEngine.results(matching: "floral", in: [chromeLink, finderImage]), [chromeLink])
        XCTAssertEqual(
            searchEngine.results(matching: "chrome", in: [chromeLink, finderImage]), [chromeLink])
        XCTAssertEqual(
            searchEngine.results(matching: "com.apple", in: [chromeLink, finderImage]),
            [finderImage])
        XCTAssertEqual(
            searchEngine.results(matching: "anh", in: [chromeLink, finderImage]), [finderImage])
    }

    func testSearchSupportsSmallTyposAndTokensAcrossFields() {
        let invoice = makeClip(
            title: "Invoice August",
            text: "Payment confirmation",
            appName: "Safari"
        )
        let other = makeClip(title: "Random note", text: "Nothing relevant", appName: "Notes")

        XCTAssertEqual(searchEngine.results(matching: "invoce", in: [other, invoice]), [invoice])
        XCTAssertEqual(
            searchEngine.results(matching: "safari payment", in: [other, invoice]), [invoice])
    }

    func testTitleMatchRanksAheadOfContentMatchWithoutChangingEqualScoreOrder() {
        let contentMatch = makeClip(title: "Weekly note", text: "Project Phoenix")
        let titleMatch = makeClip(title: "Project Phoenix", text: "Status")
        let equalMatch = makeClip(title: "Project Phoenix", text: "Next steps")

        XCTAssertEqual(
            searchEngine.results(
                matching: "project phoenix",
                in: [contentMatch, titleMatch, equalMatch]
            ).map(\.id),
            [titleMatch.id, equalMatch.id, contentMatch.id]
        )
    }

    private func makeClip(
        title: String,
        text: String?,
        kind: ClipContentKind = .text,
        appName: String? = nil,
        bundleIdentifier: String? = nil
    ) -> Clip {
        Clip(
            contentKind: kind,
            displayTitle: title,
            searchableText: text,
            sourceApplication: appName == nil && bundleIdentifier == nil
                ? nil
                : SourceApplication(
                    bundleIdentifier: bundleIdentifier,
                    localizedName: appName
                ),
            contentHash: UUID().uuidString
        )
    }
}
