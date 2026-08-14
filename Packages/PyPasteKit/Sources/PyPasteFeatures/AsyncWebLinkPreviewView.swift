import PyPasteDomain
import PyPasteSharedUI
import SwiftUI

public struct AsyncWebLinkPreviewView: View {
    private enum LoadingPhase {
        case loading
        case ready(RichLinkMetadata)
        case unavailable
    }

    private let link: WebLinkPreview
    private let provider: RichLinkMetadataProvider
    @Bindable private var localization: AppLocalization
    @State private var phase = LoadingPhase.loading

    public init(
        link: WebLinkPreview,
        provider: RichLinkMetadataProvider = .shared,
        localization: AppLocalization = .shared
    ) {
        self.link = link
        self.provider = provider
        self.localization = localization
    }

    public var body: some View {
        preview
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.primary.opacity(0.035))
            .task(id: link.url) {
                phase = .loading
                let metadata = await provider.metadata(for: link.url)
                guard !Task.isCancelled else {
                    return
                }

                phase = metadata.map(LoadingPhase.ready) ?? .unavailable
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityIdentifier("webLinkPreview-\(link.url.absoluteString)")
    }

    @ViewBuilder
    private var preview: some View {
        switch phase {
        case .loading:
            fallbackPreview(showsProgress: true)
        case let .ready(metadata):
            richPreview(metadata)
        case .unavailable:
            fallbackPreview(showsProgress: false)
        }
    }

    private func richPreview(_ metadata: RichLinkMetadata) -> some View {
        RichWebLinkPreviewContent(
            link: link,
            metadata: metadata,
            localization: localization
        )
    }

    private func fallbackPreview(showsProgress: Bool) -> some View {
        VStack(spacing: 0) {
            ZStack {
                linkPlaceholder

                if showsProgress {
                    ProgressView()
                        .controlSize(.small)
                }
            }
            .frame(height: 45)

            WebLinkCaption(title: link.pathSummary, host: link.displayHost)
        }
    }

    private var linkPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color.primary.opacity(0.04), Color.primary.opacity(0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: "link")
                .font(.title2.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }

    private var accessibilityLabel: String {
        switch phase {
        case .loading:
            localization.text(.loadingLinkPreviewFormat, link.displayHost)
        case let .ready(metadata):
            localization.text(
                .linkPreviewFormat,
                metadata.title ?? link.pathSummary,
                link.displayHost
            )
        case .unavailable:
            localization.text(.linkPreviewFormat, link.pathSummary, link.displayHost)
        }
    }
}

struct RichWebLinkPreviewContent: View {
    let link: WebLinkPreview
    let metadata: RichLinkMetadata
    @Bindable var localization: AppLocalization

    init(
        link: WebLinkPreview,
        metadata: RichLinkMetadata,
        localization: AppLocalization = .shared
    ) {
        self.link = link
        self.metadata = metadata
        self.localization = localization
    }

    var body: some View {
        VStack(spacing: 0) {
            if let image = metadata.image {
                Image(
                    image,
                    scale: 1,
                    orientation: .up,
                    label: Text(
                        localization.text(
                            .previewImageFormat,
                            metadata.title ?? link.displayHost
                        )
                    )
                )
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity)
                .frame(height: 61)
                .clipped()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [Color.primary.opacity(0.04), Color.primary.opacity(0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    Image(systemName: "link")
                        .font(.title2.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .frame(height: 45)
            }

            WebLinkCaption(
                title: metadata.title ?? link.pathSummary,
                host: link.displayHost
            )
        }
    }
}

private struct WebLinkCaption: View {
    let title: String
    let host: String

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Text(host)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.88))
    }
}
