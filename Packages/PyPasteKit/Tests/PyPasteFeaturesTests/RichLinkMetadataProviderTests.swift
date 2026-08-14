import Foundation
import XCTest

@testable import PyPasteFeatures

final class RichLinkMetadataProviderTests: XCTestCase {
    func testCachesSuccessfulMetadata() async throws {
        let loader = StubLinkMetadataLoader(
            result: .success(RichLinkMetadata(title: "Floral Design Studio", image: nil))
        )
        let provider = RichLinkMetadataProvider(loader: loader)
        let url = try XCTUnwrap(URL(string: "https://example.com/studio"))

        let first = await provider.metadata(for: url)
        let second = await provider.metadata(for: url)
        let callCount = await loader.callCount

        XCTAssertEqual(first?.title, "Floral Design Studio")
        XCTAssertEqual(second?.title, "Floral Design Studio")
        XCTAssertEqual(callCount, 1)
    }

    func testCoalescesConcurrentRequestsForSameURL() async throws {
        let loader = StubLinkMetadataLoader(
            result: .success(RichLinkMetadata(title: "Shared metadata", image: nil)),
            delay: .milliseconds(80)
        )
        let provider = RichLinkMetadataProvider(loader: loader)
        let url = try XCTUnwrap(URL(string: "https://example.com/shared"))

        async let first = provider.metadata(for: url)
        async let second = provider.metadata(for: url)
        let results = await [first, second]
        let callCount = await loader.callCount

        XCTAssertEqual(
            results.compactMap { $0?.title },
            ["Shared metadata", "Shared metadata"]
        )
        XCTAssertEqual(callCount, 1)
    }

    func testCachesFailureToAvoidRepeatedNetworkRequests() async throws {
        let loader = StubLinkMetadataLoader(result: .failure(.unavailable))
        let provider = RichLinkMetadataProvider(loader: loader)
        let url = try XCTUnwrap(URL(string: "https://example.com/unavailable"))

        let first = await provider.metadata(for: url)
        let second = await provider.metadata(for: url)
        let callCount = await loader.callCount

        XCTAssertNil(first)
        XCTAssertNil(second)
        XCTAssertEqual(callCount, 1)
    }

    func testEvictsLeastRecentlyUsedMetadataAtCacheLimit() async throws {
        let loader = StubLinkMetadataLoader(
            result: .success(RichLinkMetadata(title: "Metadata", image: nil))
        )
        let provider = RichLinkMetadataProvider(loader: loader, cacheLimit: 1)
        let firstURL = try XCTUnwrap(URL(string: "https://example.com/first"))
        let secondURL = try XCTUnwrap(URL(string: "https://example.com/second"))

        _ = await provider.metadata(for: firstURL)
        _ = await provider.metadata(for: secondURL)
        _ = await provider.metadata(for: firstURL)
        let callCount = await loader.callCount

        XCTAssertEqual(callCount, 3)
    }
}

private actor StubLinkMetadataLoader: LinkMetadataLoading {
    private let result: Result<RichLinkMetadata, StubLinkMetadataError>
    private let delay: Duration
    private(set) var callCount = 0

    init(
        result: Result<RichLinkMetadata, StubLinkMetadataError>,
        delay: Duration = .zero
    ) {
        self.result = result
        self.delay = delay
    }

    func loadMetadata(for _: URL) async throws -> RichLinkMetadata {
        callCount += 1
        if delay != .zero {
            try await Task.sleep(for: delay)
        }
        return try result.get()
    }
}

private enum StubLinkMetadataError: Error {
    case unavailable
}
