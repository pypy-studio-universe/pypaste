import PyPasteDomain
import PyPasteSharedUI
import SwiftUI

public struct MainHistoryView: View {
    private let model: MainHistoryModel
    @Bindable private var localization: AppLocalization

    public init(model: MainHistoryModel, localization: AppLocalization = .shared) {
        self.model = model
        self.localization = localization
    }

    public var body: some View {
        NavigationSplitView {
            List {
                Label(
                    localization.text(.allClipsFormat, model.totalClipCount),
                    systemImage: "tray.full"
                )
                Label(localization.text(.favorites), systemImage: "star")
                Label(localization.text(.trash), systemImage: "trash")
            }
            .navigationTitle("PyPaste")
        } detail: {
            VStack(spacing: 0) {
                historyToolbar
                Divider()

                if model.clips.isEmpty, model.isSearchActive {
                    FoundationEmptyStateView(
                        title: localization.text(.noMatchingItems),
                        message: localization.text(.searchSuggestion),
                        systemImage: "magnifyingglass"
                    )
                } else if model.clips.isEmpty {
                    FoundationEmptyStateView(
                        title: localization.text(.copySomethingToBegin),
                        message: localization.text(.monitoringClipboard),
                        systemImage: "doc.on.clipboard"
                    )
                } else {
                    List(model.clips) { clip in
                        ClipRowView(
                            clip: clip,
                            onCopy: {
                                model.copy(clip)
                            },
                            onDelete: {
                                model.moveToTrash(clip.id)
                            },
                            localization: localization
                        )
                    }
                    .listStyle(.inset)
                }
            }
        }
        .frame(minWidth: 760, minHeight: 500)
    }

    private var historyToolbar: some View {
        HStack(spacing: 12) {
            Text(localization.text(.clipboardHistory))
                .font(.headline)

            Text(
                model.isSearchActive
                    ? "\(model.clips.count)/\(model.totalClipCount)" : "\(model.totalClipCount)"
            )
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)

            Spacer()

            ClipboardSearchField(
                text: Binding(
                    get: { model.searchQuery },
                    set: { query in
                        model.updateSearchQuery(query)
                    }
                ),
                width: 280,
                accessibilityIdentifier: "mainHistorySearchField",
                localization: localization
            )

            Button(action: model.toggleMonitoring) {
                Label(
                    localization.text(
                        model.isMonitoringPaused ? .resumeMonitoring : .pauseMonitoring
                    ),
                    systemImage: model.isMonitoringPaused ? "play.fill" : "pause.fill"
                )
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("monitoringToggle")
        }
        .padding()
    }
}

private struct ClipRowView: View {
    let clip: Clip
    let onCopy: () -> Void
    let onDelete: () -> Void
    @Bindable var localization: AppLocalization

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .help(localization.text(.deleteClipboardItem))
            .accessibilityLabel(localization.text(.deleteItemFormat, clip.displayTitle))

            clipPreview

            VStack(alignment: .leading, spacing: 4) {
                Text(clip.displayTitle)
                    .lineLimit(2)
                HStack(spacing: 8) {
                    Text(contentKindName)
                    if let applicationName = clip.sourceApplication?.localizedName {
                        Text(applicationName)
                    }
                    Text(clip.lastUsedAt, style: .relative)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Button(localization.text(.copy), systemImage: "doc.on.doc", action: onCopy)
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .help(localization.text(.copyClip))
                .accessibilityLabel(localization.text(.copyItemFormat, clip.displayTitle))
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var clipPreview: some View {
        if clip.contentKind == .image || clip.contentKind == .gif {
            AsyncClipImagePreviewView(
                clip: clip,
                maximumPixelSize: 160,
                contentMode: .fill,
                localization: localization
            )
            .frame(width: 48, height: 40)
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        } else {
            Image(systemName: systemImage)
                .font(.title2)
                .frame(width: 48)
                .accessibilityHidden(true)
        }
    }

    private var systemImage: String {
        switch clip.contentKind {
        case .text, .richText:
            "text.alignleft"
        case .url:
            "link"
        case .image, .gif:
            "photo"
        case .pdf:
            "doc.richtext"
        case .file, .multipleFiles:
            "folder"
        case .color:
            "paintpalette"
        case .emoji:
            "face.smiling"
        case .unknown:
            "doc"
        }
    }

    private var contentKindName: String {
        let key: AppString =
            switch clip.contentKind {
            case .text: .text
            case .richText: .richText
            case .url: .link
            case .color: .color
            case .emoji: .emoji
            case .image: .image
            case .gif: .animatedImage
            case .pdf: .pdfDocument
            case .file: .file
            case .multipleFiles: .files
            case .unknown: .clipboardItem
            }
        return localization.text(key)
    }
}
