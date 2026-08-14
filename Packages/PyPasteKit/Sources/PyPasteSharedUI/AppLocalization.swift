import Foundation
import Observation

public enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case english = "en"
    case vietnamese = "vi"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .english:
            "English"
        case .vietnamese:
            "Tiếng Việt"
        }
    }

    public var locale: Locale {
        Locale(identifier: rawValue)
    }
}

public enum AppString: String, Sendable {
    case pyPasteMenu = "PyPaste menu"
    case openPyPaste = "Open PyPaste"
    case showQuickBar = "Show Quick Bar (⌘⇧V)"
    case pauseMonitoring = "Pause Monitoring"
    case resumeMonitoring = "Resume Monitoring"
    case language = "Language"
    case quitPyPaste = "Quit PyPaste"
    case allClipsFormat = "All Clips (%lld)"
    case favorites = "Favorites"
    case trash = "Trash"
    case clipboardHistory = "Clipboard History"
    case clipboard = "Clipboard"
    case noMatchingItems = "No matching clipboard items"
    case searchSuggestion = "Try another title, app, content type, or keyword."
    case copySomethingToBegin = "Copy something to begin"
    case monitoringClipboard = "PyPaste is monitoring your clipboard."
    case deleteClipboardItem = "Delete this clipboard item"
    case deleteItemFormat = "Delete %@"
    case copy = "Copy"
    case copyClip = "Copy this clip"
    case copyItemFormat = "Copy %@"
    case searchPlaceholder = "Search title, app, content…"
    case clearSearch = "Clear search"
    case clearClipboardSearch = "Clear clipboard search"
    case navigatePasteClose = "← → Navigate   ↩ Paste   Esc Close"
    case closeQuickBar = "Close Quick Bar"
    case loadingCollectionFormat = "Loading %@…"
    case noClipboardHistory = "No clipboard history yet"
    case collectionEmpty = "Collection is empty"
    case copyThenOpenAgain = "Copy something, then press Command-Shift-V again."
    case saveHerePermanently = "Use the + button on a card to save it here permanently."
    case createCollection = "Create collection"
    case createACollection = "Create a collection"
    case openCollectionFormat = "Open %@ collection"
    case deleteCollectionFormat = "Delete %@ collection"
    case selected = "Selected"
    case notSelected = "Not selected"
    case newCollection = "New Collection"
    case collectionPersistence =
        "Items saved to a collection are kept permanently until you delete them."
    case collectionName = "Collection name"
    case create = "Create"
    case deleteCollectionQuestion = "Delete Collection?"
    case deleteCollectionMessageFormat =
        "Delete \"%@\"? Its items will remain available in Clipboard."
    case delete = "Delete"
    case cancel = "Cancel"
    case savingToCollection = "Saving to collection…"
    case enterCollectionName = "Enter a collection name."
    case creatingCollection = "Creating collection…"
    case deletingCollection = "Deleting collection…"
    case savedToCollection = "Saved permanently to collection"
    case couldNotSaveToCollection = "Could not save this item to the collection."
    case collectionCreated = "Collection created"
    case collectionNameInUse = "That collection name is already in use."
    case collectionDeleted = "Collection deleted. Items remain in Clipboard."
    case couldNotDeleteCollection = "Could not delete this collection."
    case couldNotLoadCollection = "Could not load this collection."
    case pasted = "Pasted"
    case accessibilityRequired = "Copied. Allow Accessibility, then click the card again."
    case pasteTargetUnavailable = "Copied. Return to an application, then open Quick Bar again."
    case commandVFailed = "Copied, but macOS could not send Command-V."
    case copyFailed = "Could not copy this clip. Please try again."
    case historyUpdateFailed = "Could not update clipboard history."
    case pasteItemFormat = "Paste %@"
    case colorFormat = "Color %@"
    case copiedFromFormat = "Copied from %@, %@"
    case savePermanently = "Save permanently to a collection"
    case addToCollectionFormat = "Add %@ to collection"
    case link = "Link"
    case text = "Text"
    case richText = "Rich text"
    case color = "Color"
    case emoji = "Emoji"
    case image = "Image"
    case animatedImage = "Animated image"
    case pdfDocument = "PDF document"
    case file = "File"
    case files = "Files"
    case clipboardItem = "Clipboard item"
    case unknownApp = "Unknown app"
    case charactersFormat = "%lld characters"
    case loadingImagePreview = "Loading image preview"
    case imagePreviewFormat = "Image preview for %@"
    case imagePreviewUnavailable = "Image preview unavailable"
    case loadingLinkPreviewFormat = "Loading link preview for %@"
    case linkPreviewFormat = "Link preview %@, %@"
    case previewImageFormat = "Preview image for %@"
    case dropBeforeFormat = "Drop before %@"
    case dropAfterFormat = "Drop after %@"
    case settingsStatus = "Status"
    case captureEngineEnabled = "Capture engine enabled"
    case copiedAgain = "When content is copied again"
    case moveExistingToTop = "Move existing item to top"
    case createNewItem = "Create a new item"
    case shortcuts = "Shortcuts"
    case toggleQuickBar = "Toggle Bottom Quick Bar"
    case startFailure = "PyPaste could not start"
}

@MainActor
@Observable
public final class AppLocalization {
    public static let defaultsKey = "pypaste.appLanguage"
    public static let shared = AppLocalization()

    public private(set) var language: AppLanguage
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let storedValue = defaults.string(forKey: Self.defaultsKey),
            let storedLanguage = AppLanguage(rawValue: storedValue)
        {
            language = storedLanguage
        } else {
            language = .english
        }
    }

    public func select(_ language: AppLanguage) {
        guard self.language != language else {
            return
        }

        self.language = language
        defaults.set(language.rawValue, forKey: Self.defaultsKey)
    }

    public func text(_ key: AppString, _ arguments: CVarArg...) -> String {
        let template =
            language == .vietnamese
            ? Self.vietnamese[key, default: key.rawValue]
            : key.rawValue
        guard !arguments.isEmpty else {
            return template
        }

        return String(format: template, locale: language.locale, arguments: arguments)
    }

    private static let vietnamese: [AppString: String] = [
        .pyPasteMenu: "Menu PyPaste",
        .openPyPaste: "Mở PyPaste",
        .showQuickBar: "Hiện thanh nhanh (⌘⇧V)",
        .pauseMonitoring: "Tạm dừng theo dõi",
        .resumeMonitoring: "Tiếp tục theo dõi",
        .language: "Ngôn ngữ",
        .quitPyPaste: "Thoát PyPaste",
        .allClipsFormat: "Tất cả mục (%lld)",
        .favorites: "Yêu thích",
        .trash: "Thùng rác",
        .clipboardHistory: "Lịch sử clipboard",
        .clipboard: "Clipboard",
        .noMatchingItems: "Không tìm thấy mục phù hợp",
        .searchSuggestion: "Thử tiêu đề, ứng dụng, loại nội dung hoặc từ khóa khác.",
        .copySomethingToBegin: "Hãy sao chép nội dung để bắt đầu",
        .monitoringClipboard: "PyPaste đang theo dõi clipboard của bạn.",
        .deleteClipboardItem: "Xóa mục clipboard này",
        .deleteItemFormat: "Xóa %@",
        .copy: "Sao chép",
        .copyClip: "Sao chép mục này",
        .copyItemFormat: "Sao chép %@",
        .searchPlaceholder: "Tìm tiêu đề, ứng dụng, nội dung…",
        .clearSearch: "Xóa tìm kiếm",
        .clearClipboardSearch: "Xóa tìm kiếm clipboard",
        .navigatePasteClose: "← → Di chuyển   ↩ Dán   Esc Đóng",
        .closeQuickBar: "Đóng thanh nhanh",
        .loadingCollectionFormat: "Đang tải %@…",
        .noClipboardHistory: "Chưa có lịch sử clipboard",
        .collectionEmpty: "Danh mục đang trống",
        .copyThenOpenAgain: "Hãy sao chép nội dung rồi nhấn Command-Shift-V lần nữa.",
        .saveHerePermanently: "Dùng nút + trên thẻ để lưu vĩnh viễn vào đây.",
        .createCollection: "Tạo danh mục",
        .createACollection: "Tạo một danh mục",
        .openCollectionFormat: "Mở danh mục %@",
        .deleteCollectionFormat: "Xóa danh mục %@",
        .selected: "Đã chọn",
        .notSelected: "Chưa chọn",
        .newCollection: "Danh mục mới",
        .collectionPersistence:
            "Các mục trong danh mục được giữ vĩnh viễn cho đến khi bạn xóa chúng.",
        .collectionName: "Tên danh mục",
        .create: "Tạo",
        .deleteCollectionQuestion: "Xóa danh mục?",
        .deleteCollectionMessageFormat: "Xóa \"%@\"? Các mục vẫn còn trong Clipboard.",
        .delete: "Xóa",
        .cancel: "Hủy",
        .savingToCollection: "Đang lưu vào danh mục…",
        .enterCollectionName: "Hãy nhập tên danh mục.",
        .creatingCollection: "Đang tạo danh mục…",
        .deletingCollection: "Đang xóa danh mục…",
        .savedToCollection: "Đã lưu vĩnh viễn vào danh mục",
        .couldNotSaveToCollection: "Không thể lưu mục này vào danh mục.",
        .collectionCreated: "Đã tạo danh mục",
        .collectionNameInUse: "Tên danh mục này đã được sử dụng.",
        .collectionDeleted: "Đã xóa danh mục. Các mục vẫn còn trong Clipboard.",
        .couldNotDeleteCollection: "Không thể xóa danh mục này.",
        .couldNotLoadCollection: "Không thể tải danh mục này.",
        .pasted: "Đã dán",
        .accessibilityRequired: "Đã sao chép. Hãy cấp quyền Trợ năng rồi bấm lại thẻ.",
        .pasteTargetUnavailable: "Đã sao chép. Hãy quay lại ứng dụng rồi mở thanh nhanh lần nữa.",
        .commandVFailed: "Đã sao chép nhưng macOS không thể gửi Command-V.",
        .copyFailed: "Không thể sao chép mục này. Vui lòng thử lại.",
        .historyUpdateFailed: "Không thể cập nhật lịch sử clipboard.",
        .pasteItemFormat: "Dán %@",
        .colorFormat: "Màu %@",
        .copiedFromFormat: "Sao chép từ %@, %@",
        .savePermanently: "Lưu vĩnh viễn vào danh mục",
        .addToCollectionFormat: "Thêm %@ vào danh mục",
        .link: "Liên kết",
        .text: "Văn bản",
        .richText: "Văn bản định dạng",
        .color: "Màu sắc",
        .emoji: "Biểu tượng cảm xúc",
        .image: "Hình ảnh",
        .animatedImage: "Ảnh động",
        .pdfDocument: "Tài liệu PDF",
        .file: "Tệp",
        .files: "Nhiều tệp",
        .clipboardItem: "Mục clipboard",
        .unknownApp: "Ứng dụng không xác định",
        .charactersFormat: "%lld ký tự",
        .loadingImagePreview: "Đang tải bản xem trước ảnh",
        .imagePreviewFormat: "Bản xem trước ảnh của %@",
        .imagePreviewUnavailable: "Không có bản xem trước ảnh",
        .loadingLinkPreviewFormat: "Đang tải bản xem trước liên kết cho %@",
        .linkPreviewFormat: "Bản xem trước liên kết %@, %@",
        .previewImageFormat: "Ảnh xem trước của %@",
        .dropBeforeFormat: "Thả trước %@",
        .dropAfterFormat: "Thả sau %@",
        .settingsStatus: "Trạng thái",
        .captureEngineEnabled: "Đang bật theo dõi clipboard",
        .copiedAgain: "Khi nội dung được sao chép lại",
        .moveExistingToTop: "Đưa mục hiện có lên đầu",
        .createNewItem: "Tạo mục mới",
        .shortcuts: "Phím tắt",
        .toggleQuickBar: "Bật/tắt thanh nhanh phía dưới",
        .startFailure: "Không thể khởi động PyPaste",
    ]
}
