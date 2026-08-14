import Foundation
import XCTest

@testable import PyPasteSharedUI

@MainActor
final class AppLocalizationTests: XCTestCase {
    func testDefaultsToEnglishWithoutStoredSelection() throws {
        let defaults = try makeDefaults()
        let localization = AppLocalization(defaults: defaults)

        XCTAssertEqual(localization.language, .english)
        XCTAssertEqual(localization.text(.openPyPaste), "Open PyPaste")
    }

    func testVietnameseCanBeSelectedExplicitly() throws {
        let defaults = try makeDefaults()
        let localization = AppLocalization(defaults: defaults)

        localization.select(.vietnamese)

        XCTAssertEqual(localization.language, .vietnamese)
        XCTAssertEqual(localization.text(.openPyPaste), "Mở PyPaste")
    }

    func testSelectionPersistsAcrossInstances() throws {
        let defaults = try makeDefaults()
        let first = AppLocalization(defaults: defaults)

        first.select(.vietnamese)
        let second = AppLocalization(defaults: defaults)

        XCTAssertEqual(second.language, .vietnamese)
        XCTAssertEqual(second.text(.language), "Ngôn ngữ")
    }

    func testFormattedTextUsesSelectedTranslation() throws {
        let defaults = try makeDefaults()
        let localization = AppLocalization(defaults: defaults)

        localization.select(.vietnamese)

        XCTAssertEqual(
            localization.text(.deleteCollectionMessageFormat, "Công việc"),
            "Xóa \"Công việc\"? Các mục vẫn còn trong Clipboard."
        )
        XCTAssertEqual(localization.text(.charactersFormat, 25), "25 ký tự")
    }

    private func makeDefaults() throws -> UserDefaults {
        let suiteName = "AppLocalizationTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
