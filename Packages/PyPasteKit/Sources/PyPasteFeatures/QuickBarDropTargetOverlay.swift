import PyPasteDomain
import PyPasteSharedUI
import SwiftUI

struct QuickBarDropTargetOverlay: View {
    let preview: QuickBarDropPreview
    let targetTitle: String
    @Bindable var localization: AppLocalization

    init(
        preview: QuickBarDropPreview,
        targetTitle: String,
        localization: AppLocalization = .shared
    ) {
        self.preview = preview
        self.targetTitle = targetTitle
        self.localization = localization
    }

    var body: some View {
        ZStack(alignment: indicatorAlignment) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.accentColor.opacity(0.20))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.accentColor.opacity(0.95), lineWidth: 3)
                }
                .shadow(color: Color.accentColor.opacity(0.55), radius: 8)

            insertionRail
        }
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier(accessibilityIdentifier)
    }

    private var insertionRail: some View {
        ZStack {
            Capsule()
                .fill(Color.accentColor.opacity(0.85))
                .frame(width: 16)
                .blur(radius: 6)

            Capsule()
                .fill(Color.white)
                .frame(width: 3)
                .overlay {
                    Capsule()
                        .stroke(Color.accentColor, lineWidth: 1.5)
                }
                .shadow(color: Color.accentColor, radius: 7)
        }
        .frame(width: 18, height: 144)
        .padding(preview.placement == .before ? .leading : .trailing, -4)
    }

    private var indicatorAlignment: Alignment {
        preview.placement == .before ? .leading : .trailing
    }

    private var placementName: String {
        preview.placement == .before ? "before" : "after"
    }

    private var accessibilityLabel: String {
        localization.text(
            preview.placement == .before ? .dropBeforeFormat : .dropAfterFormat,
            targetTitle
        )
    }

    private var accessibilityIdentifier: String {
        "quickBarDropInsertion-\(preview.targetClipID.uuidString)-\(placementName)"
    }
}
