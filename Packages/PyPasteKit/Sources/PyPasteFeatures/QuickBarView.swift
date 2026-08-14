import Foundation
import PyPasteDomain
import PyPasteSharedUI
import SwiftUI

public struct QuickBarView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dragSession = QuickBarDragSession()
    @State private var newCollectionName = ""
    @Bindable private var localization: AppLocalization
    private let model: QuickBarModel
    private let applicationAccentProvider: any ApplicationAccentProviding
    private let linkMetadataProvider: RichLinkMetadataProvider

    public init(
        model: QuickBarModel,
        applicationAccentProvider: any ApplicationAccentProviding =
            SystemApplicationAccentProvider.shared,
        linkMetadataProvider: RichLinkMetadataProvider = .shared,
        localization: AppLocalization = .shared
    ) {
        self.model = model
        self.applicationAccentProvider = applicationAccentProvider
        self.linkMetadataProvider = linkMetadataProvider
        self.localization = localization
    }

    public var body: some View {
        VStack(spacing: 10) {
            header
            collectionBar

            if model.isLoadingCollection {
                loadingState
            } else if model.clips.isEmpty {
                emptyState
            } else {
                clipScroller
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .accessibilityIdentifier("quickBarRoot")
        .onChange(of: model.processingClipID) { _, processingClipID in
            guard processingClipID != nil else {
                return
            }

            dragSession.cancel()
        }
        .overlay {
            if let dialog = model.collectionDialog {
                QuickBarCollectionDialogView(
                    dialog: dialog,
                    collectionName: $newCollectionName,
                    onCancel: dismissCollectionDialog,
                    onCreate: createCollection,
                    onDelete: deleteCollection,
                    localization: localization
                )
                .zIndex(10)
            }
        }
    }

    private var header: some View {
        ZStack {
            ClipboardSearchField(
                text: Binding(
                    get: { model.searchQuery },
                    set: { query in
                        model.updateSearchQuery(query)
                    }
                ),
                width: 300,
                accessibilityIdentifier: "quickBarSearchField",
                localization: localization
            )
            .zIndex(1)

            HStack(spacing: 10) {
                Text(model.selectedCollectionName)
                    .font(.subheadline.weight(.medium))

                Text(resultCountText)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)

                Spacer()

                if let feedbackMessage = model.feedbackMessage {
                    Label(feedbackMessage, systemImage: "info.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .accessibilityIdentifier("quickBarFeedback")
                }

                Text(localization.text(.navigatePasteClose))
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)

                Text("⌘⇧V")
                    .font(.caption.monospaced())
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 7))

                Button(action: model.dismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help(localization.text(.closeQuickBar))
                .accessibilityLabel(localization.text(.closeQuickBar))
            }
        }
        .frame(height: 26)
    }

    private var clipScroller: some View {
        GeometryReader { geometry in
            let layout = QuickBarLayoutMetrics(
                containerWidth: geometry.size.width,
                itemCount: model.clips.count
            )

            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    LazyHStack(spacing: layout.cardSpacing) {
                        ForEach(model.clips) { clip in
                            reorderableCard(
                                for: clip,
                                width: layout.cardWidth
                            )
                        }
                    }
                    .padding(.horizontal, layout.edgeInset)
                    .scrollTargetLayout()
                }
                .scrollIndicators(.hidden)
                .scrollTargetBehavior(.viewAligned)
                .onChange(of: model.selectedClipID) { _, selectedClipID in
                    guard let selectedClipID else {
                        return
                    }

                    withAnimation(.easeOut(duration: 0.14)) {
                        proxy.scrollTo(selectedClipID, anchor: .center)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func reorderableCard(for clip: Clip, width: CGFloat) -> some View {
        let dropPreview = dragSession.preview.flatMap { preview in
            preview.targetClipID == clip.id ? preview : nil
        }
        let card = makeCard(for: clip, width: width)

        if model.processingClipID == nil, !model.isSearchActive {
            card
                .overlay {
                    if let dropPreview {
                        QuickBarDropTargetOverlay(
                            preview: dropPreview,
                            targetTitle: clip.displayTitle,
                            localization: localization
                        )
                        .transition(.opacity)
                    }
                }
                .animation(dropAnimation, value: dropPreview)
                .zIndex(dropPreview == nil ? 0 : 1)
                .onDrop(
                    of: [QuickBarDragPayload.contentType],
                    delegate: QuickBarClipDropDelegate(
                        targetClipID: clip.id,
                        targetWidth: width,
                        dragSession: $dragSession,
                        animation: dropAnimation,
                        onMove: model.move
                    )
                )
        } else {
            card
        }
    }

    private func makeCard(for clip: Clip, width: CGFloat) -> QuickBarClipCard {
        QuickBarClipCard(
            clip: clip,
            width: width,
            isSelected: model.selectedClipID == clip.id,
            isProcessing: model.processingClipID == clip.id,
            isEditingDisabled: model.processingClipID != nil,
            applicationAccentProvider: applicationAccentProvider,
            linkMetadataProvider: linkMetadataProvider,
            onPaste: {
                model.paste(clip)
            },
            onDelete: {
                model.moveToTrash(clip.id)
            },
            collections: model.collections,
            collectionIDs: model.collectionIDs(for: clip.id),
            onAddToCollection: { collectionID in
                model.addToCollection(clipID: clip.id, collectionID: collectionID)
            },
            dragItemProvider: {
                dragSession.beginDragging(clip.id)
                return QuickBarDragPayload.itemProvider(for: clip)
            },
            localization: localization
        )
    }

    private var dropAnimation: Animation? {
        reduceMotion ? nil : .easeOut(duration: 0.12)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: model.isSearchActive ? "magnifyingglass" : "clipboard")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(emptyTitle)
                .font(.headline)
            Text(emptyMessage)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var loadingState: some View {
        VStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
            Text(localization.text(.loadingCollectionFormat, model.selectedCollectionName))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

}

private extension QuickBarView {
    var collectionBar: some View {
        QuickBarCollectionBar(
            collections: model.collections,
            selectedCollectionID: model.selectedCollectionID,
            onSelect: model.selectCollection,
            onCreate: {
                model.presentCreateCollectionDialog()
            },
            onDeleteRequest: { collection in
                model.presentDeleteCollectionDialog(for: collection)
            },
            localization: localization
        )
    }

    func dismissCollectionDialog() {
        newCollectionName = ""
        model.dismissCollectionDialog()
    }

    func createCollection() {
        model.createCollection(named: newCollectionName)
        dismissCollectionDialog()
    }

    func deleteCollection(_ collection: ClipCollection) {
        model.deleteCollection(collection.id)
        dismissCollectionDialog()
    }

    var emptyTitle: String {
        if model.isSearchActive {
            return localization.text(.noMatchingItems)
        }
        return model.selectedCollectionID == nil
            ? localization.text(.noClipboardHistory) : localization.text(.collectionEmpty)
    }

    var emptyMessage: String {
        if model.isSearchActive {
            return localization.text(.searchSuggestion)
        }
        return model.selectedCollectionID == nil
            ? localization.text(.copyThenOpenAgain)
            : localization.text(.saveHerePermanently)
    }

    var resultCountText: String {
        model.isSearchActive
            ? "\(model.clips.count)/\(model.totalClipCount)"
            : "\(model.totalClipCount)"
    }
}

struct QuickBarLayoutMetrics {
    static let maximumVisibleCardCount = 6
    static let preferredCardWidth: CGFloat = 216
    static let minimumCardWidth: CGFloat = 176
    static let cardSpacing: CGFloat = 12
    static let edgeInset: CGFloat = 8

    let visibleCardCount: Int
    let cardWidth: CGFloat
    let cardSpacing: CGFloat
    let edgeInset: CGFloat

    init(containerWidth: CGFloat, itemCount: Int) {
        cardSpacing = Self.cardSpacing
        edgeInset = Self.edgeInset

        let availableWidth = max(0, containerWidth - edgeInset * 2)
        let fittingCardCount = max(
            1,
            Int((availableWidth + cardSpacing) / (Self.minimumCardWidth + cardSpacing))
        )
        visibleCardCount = max(
            1,
            min(
                max(1, itemCount),
                min(Self.maximumVisibleCardCount, fittingCardCount)
            )
        )

        let totalSpacing = cardSpacing * CGFloat(visibleCardCount - 1)
        let fittedCardWidth = max(
            1,
            (availableWidth - totalSpacing) / CGFloat(visibleCardCount)
        )
        cardWidth = min(Self.preferredCardWidth, fittedCardWidth)
    }
}
