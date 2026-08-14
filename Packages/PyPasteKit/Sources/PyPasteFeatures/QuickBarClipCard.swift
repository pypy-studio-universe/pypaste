import Foundation
import PyPasteDomain
import PyPasteSharedUI
import SwiftUI

struct QuickBarClipCard: View {
    private enum Layout {
        static let cardHeight: CGFloat = 162
        static let headerHeight: CGFloat = 35
        static let footerHeight: CGFloat = 28
        static let previewHeight = cardHeight - headerHeight - footerHeight
    }

    let clip: Clip
    let width: CGFloat
    let isSelected: Bool
    let isProcessing: Bool
    let isEditingDisabled: Bool
    let applicationAccentProvider: any ApplicationAccentProviding
    let linkMetadataProvider: RichLinkMetadataProvider
    let onPaste: () -> Void
    let onDelete: () -> Void
    let collections: [ClipCollection]
    let collectionIDs: Set<ClipCollection.ID>
    let onAddToCollection: (ClipCollection.ID) -> Void
    let dragItemProvider: (() -> NSItemProvider)?
    @Bindable var localization: AppLocalization
    @State private var applicationAccent: ApplicationAccent?

    init(
        clip: Clip,
        width: CGFloat,
        isSelected: Bool,
        isProcessing: Bool,
        isEditingDisabled: Bool,
        applicationAccentProvider: any ApplicationAccentProviding,
        linkMetadataProvider: RichLinkMetadataProvider = .shared,
        onPaste: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        collections: [ClipCollection] = [],
        collectionIDs: Set<ClipCollection.ID> = [],
        onAddToCollection: @escaping (ClipCollection.ID) -> Void = { _ in },
        dragItemProvider: (() -> NSItemProvider)? = nil,
        localization: AppLocalization = .shared
    ) {
        self.clip = clip
        self.width = width
        self.isSelected = isSelected
        self.isProcessing = isProcessing
        self.isEditingDisabled = isEditingDisabled
        self.applicationAccentProvider = applicationAccentProvider
        self.linkMetadataProvider = linkMetadataProvider
        self.onPaste = onPaste
        self.onDelete = onDelete
        self.collections = collections
        self.collectionIDs = collectionIDs
        self.onAddToCollection = onAddToCollection
        self.dragItemProvider = dragItemProvider
        self.localization = localization
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            draggablePasteButton

            Button(action: deleteIfAvailable) {
                Image(systemName: "xmark.circle.fill")
                    .font(.body.weight(.semibold))
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 24, height: 24)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(deleteForegroundColor)
            .disabled(isEditingDisabled)
            .padding(.leading, 7)
            .padding(.top, 5)
            .help(localization.text(.deleteClipboardItem))
            .accessibilityLabel(localization.text(.deleteItemFormat, clip.displayTitle))
            .accessibilityIdentifier("deleteClip-\(clip.id.uuidString)")

            VStack {
                HStack {
                    Spacer()
                    collectionMenu
                }
                Spacer()
            }
            .padding(.trailing, 7)
            .padding(.top, 5)
        }
        .frame(width: width, height: Layout.cardHeight)
        .adaptiveLiquidGlass(in: cardShape)
        .clipShape(cardShape)
        .overlay {
            cardShape.strokeBorder(
                Color.primary.opacity(isSelected ? 0.92 : 0.16),
                lineWidth: isSelected ? 3 : 1
            )
        }
        .shadow(color: .black.opacity(isSelected ? 0.20 : 0.08), radius: 6, y: 2)
        .animation(.easeOut(duration: 0.12), value: isSelected)
        .animation(.easeOut(duration: 0.18), value: applicationAccent)
        .task(id: accentRequestID) {
            await loadApplicationAccent()
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var draggablePasteButton: some View {
        if let dragItemProvider {
            pasteButton.onDrag(dragItemProvider)
        } else {
            pasteButton
        }
    }

    private var pasteButton: some View {
        Button(action: pasteIfAvailable) {
            VStack(spacing: 0) {
                cardHeader
                previewRegion
                cardFooter
            }
            .frame(width: width, height: Layout.cardHeight, alignment: .top)
            .clipped()
            .contentShape(cardShape)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(localization.text(.pasteItemFormat, clip.displayTitle))
        .accessibilityValue(localization.text(isSelected ? .selected : .notSelected))
        .accessibilityIdentifier("quickBarClip-\(clip.id.uuidString)")
    }

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
    }

    private func pasteIfAvailable() {
        guard !isProcessing else {
            return
        }

        onPaste()
    }

    private func deleteIfAvailable() {
        guard !isEditingDisabled else {
            return
        }

        onDelete()
    }

    private var cardHeader: some View {
        HStack(spacing: 7) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))

            Text(headerTitle)
                .font(.caption.weight(.semibold))
                .lineLimit(1)

            Spacer(minLength: 4)

            if isProcessing {
                ProgressView()
                    .controlSize(.small)
                    .tint(headerForegroundColor)
            } else if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
            }
        }
        .foregroundStyle(headerForegroundColor)
        .padding(.leading, 38)
        .padding(.trailing, 38)
        .frame(maxWidth: .infinity)
        .frame(height: Layout.headerHeight, alignment: .leading)
        .background(headerBackgroundColor)
    }

    @ViewBuilder
    private var previewContent: some View {
        if clip.contentKind == .color, let color = clip.searchableText.flatMap(HexColor.init) {
            colorPreview(color)
        } else if clip.contentKind == .image || clip.contentKind == .gif {
            AsyncClipImagePreviewView(clip: clip, localization: localization)
        } else if clip.contentKind == .url,
            let link = clip.searchableText.flatMap(WebLinkPreview.init)
        {
            AsyncWebLinkPreviewView(
                link: link,
                provider: linkMetadataProvider,
                localization: localization
            )
        } else {
            defaultPreview
        }
    }

    private var previewRegion: some View {
        previewContent
            .frame(maxWidth: .infinity)
            .frame(height: Layout.previewHeight)
            .clipped()
            .contentShape(Rectangle())
    }

    private func colorPreview(_ color: HexColor) -> some View {
        ZStack {
            Color(
                red: color.red,
                green: color.green,
                blue: color.blue,
                opacity: color.alpha
            )

            Text(color.canonicalCode)
                .font(.title3.monospaced().weight(.semibold))
                .foregroundStyle(color.prefersDarkForeground ? Color.black : Color.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    (color.prefersDarkForeground ? Color.white : Color.black).opacity(0.16),
                    in: Capsule()
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel(localization.text(.colorFormat, color.canonicalCode))
    }

    private var defaultPreview: some View {
        Text(previewText)
            .font(previewFont)
            .foregroundStyle(.primary)
            .lineLimit(4)
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var cardFooter: some View {
        HStack(spacing: 6) {
            Label(sourceApplicationName, systemImage: "app.fill")
                .lineLimit(1)

            Spacer(minLength: 4)

            Text(metadataText)
                .lineLimit(1)
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 11)
        .frame(maxWidth: .infinity)
        .frame(height: Layout.footerHeight)
        .background(Color.primary.opacity(0.04))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            localization.text(.copiedFromFormat, sourceApplicationName, metadataText)
        )
    }

}

private extension QuickBarClipCard {
    var collectionMenu: some View {
        Menu {
            ForEach(collections) { collection in
                let isSaved = collectionIDs.contains(collection.id)
                Button {
                    onAddToCollection(collection.id)
                } label: {
                    Label(
                        collection.name,
                        systemImage: isSaved ? "checkmark.circle.fill" : "circle"
                    )
                }
                .disabled(isSaved || isEditingDisabled)
            }
        } label: {
            Image(systemName: collectionIDs.isEmpty ? "plus.circle.fill" : "folder.badge.plus")
                .font(.body.weight(.semibold))
                .symbolRenderingMode(.hierarchical)
                .frame(width: 24, height: 24)
                .contentShape(Circle())
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .foregroundStyle(headerForegroundColor.opacity(0.9))
        .disabled(collections.isEmpty || isEditingDisabled)
        .help(localization.text(.savePermanently))
        .accessibilityLabel(localization.text(.addToCollectionFormat, clip.displayTitle))
        .accessibilityIdentifier("addClipToCollection-\(clip.id.uuidString)")
    }

    var sourceApplicationName: String {
        clip.sourceApplication?.localizedName ?? localization.text(.unknownApp)
    }

    var accentRequestID: String {
        let bundleIdentifier = clip.sourceApplication?.bundleIdentifier ?? ""
        let localizedName = clip.sourceApplication?.localizedName ?? ""
        return "\(bundleIdentifier)|\(localizedName)"
    }

    var headerBackgroundColor: Color {
        applicationAccent?.backgroundColor ?? Color.primary.opacity(0.07)
    }

    var headerForegroundColor: Color {
        applicationAccent?.foregroundColor ?? .primary
    }

    var deleteForegroundColor: Color {
        applicationAccent?.foregroundColor.opacity(0.88) ?? .secondary
    }

    func loadApplicationAccent() async {
        applicationAccent = nil
        let sourceApplication = clip.sourceApplication
        let resolvedAccent = await applicationAccentProvider.accent(
            bundleIdentifier: sourceApplication?.bundleIdentifier,
            localizedName: sourceApplication?.localizedName
        )
        guard !Task.isCancelled else {
            return
        }

        applicationAccent = resolvedAccent
    }

    var previewText: String {
        if let searchableText = clip.searchableText, !searchableText.isEmpty {
            return searchableText
        }

        return clip.displayTitle
    }

    var metadataText: String {
        if let characterCount = clip.characterCount {
            return localization.text(.charactersFormat, characterCount)
        }

        return clip.lastUsedAt.formatted(.relative(presentation: .named))
    }

    var previewFont: Font {
        switch clip.contentKind {
        case .text, .richText:
            return .system(.callout, design: .monospaced)
        default:
            return .headline
        }
    }

    var systemImage: String {
        switch clip.contentKind {
        case .text, .richText:
            return "text.alignleft"
        case .url:
            return "link"
        case .image, .gif:
            return "photo"
        case .pdf:
            return "doc.richtext"
        case .file, .multipleFiles:
            return "folder"
        case .color:
            return "paintpalette"
        case .emoji:
            return "face.smiling"
        case .unknown:
            return "doc"
        }
    }
}

extension View {
    @ViewBuilder
    fileprivate func adaptiveLiquidGlass(in shape: some Shape) -> some View {
        if #available(macOS 26.0, *) {
            glassEffect(.regular, in: shape)
        } else {
            background(.ultraThinMaterial, in: shape)
        }
    }
}
