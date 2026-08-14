import PyPasteSharedUI

extension QuickBarClipCard {
    var headerTitle: String {
        switch clip.contentKind {
        case .url:
            localization.text(.link)
        case .image:
            localization.text(.image)
        case .gif:
            localization.text(.animatedImage)
        case .pdf:
            localization.text(.pdfDocument)
        case .unknown:
            localization.text(.clipboardItem)
        default:
            clip.displayTitle
        }
    }
}
