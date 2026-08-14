import CoreGraphics
import PyPasteDomain
import PyPasteSharedUI
import SwiftUI

public struct AsyncClipImagePreviewView: View {
    private enum LoadingPhase {
        case loading
        case ready(CGImage)
        case unavailable
    }

    private let clip: Clip
    private let maximumPixelSize: Int
    private let contentMode: ContentMode
    private let provider: ImageThumbnailProvider
    @Bindable private var localization: AppLocalization

    @State private var phase = LoadingPhase.loading

    public init(
        clip: Clip,
        maximumPixelSize: Int = 512,
        contentMode: ContentMode = .fill,
        provider: ImageThumbnailProvider = .shared,
        localization: AppLocalization = .shared
    ) {
        self.clip = clip
        self.maximumPixelSize = max(1, maximumPixelSize)
        self.contentMode = contentMode
        self.provider = provider
        self.localization = localization
    }

    public var body: some View {
        preview
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityIdentifier("clipImagePreview-\(clip.id.uuidString)")
            .task(id: requestID) {
                phase = .loading
                let image = await provider.thumbnail(
                    for: clip,
                    maximumPixelSize: maximumPixelSize
                )

                guard !Task.isCancelled else {
                    return
                }

                phase = image.map(LoadingPhase.ready) ?? .unavailable
            }
    }

    @ViewBuilder
    private var preview: some View {
        switch phase {
        case .loading:
            ProgressView()
                .controlSize(.small)
                .accessibilityLabel(localization.text(.loadingImagePreview))
        case let .ready(image):
            Image(
                image,
                scale: 1,
                orientation: .up,
                label: Text(localization.text(.imagePreviewFormat, clip.displayTitle))
            )
            .resizable()
            .aspectRatio(contentMode: contentMode)
        case .unavailable:
            Image(systemName: "photo")
                .font(.title2)
                .foregroundStyle(.secondary)
                .accessibilityLabel(localization.text(.imagePreviewUnavailable))
        }
    }

    private var requestID: String {
        "\(clip.contentHash)-\(maximumPixelSize)"
    }
}
