import PyPasteDomain
import PyPasteSharedUI
import SwiftUI

struct QuickBarCollectionBar: View {
    @State private var hoveredCollectionID: ClipCollection.ID?
    let collections: [ClipCollection]
    let selectedCollectionID: ClipCollection.ID?
    let onSelect: (ClipCollection.ID?) -> Void
    let onCreate: () -> Void
    let onDeleteRequest: (ClipCollection) -> Void
    @Bindable var localization: AppLocalization

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                collectionButton(
                    title: localization.text(.clipboard),
                    color: .secondary,
                    systemImage: "clock.arrow.circlepath",
                    collectionID: nil
                )

                ForEach(collections) { collection in
                    collectionButton(
                        title: collection.name,
                        color: collectionColor(collection.colorHex),
                        systemImage: nil,
                        collectionID: collection.id,
                        collection: collection
                    )
                }

                createButton
            }
            .padding(.horizontal, 2)
        }
        .scrollIndicators(.hidden)
        .frame(height: 28)
        .accessibilityIdentifier("quickBarCollectionBar")
    }

    private var createButton: some View {
        Button(action: onCreate) {
            Image(systemName: "plus")
                .font(.body.weight(.medium))
                .frame(width: 28, height: 24)
        }
        .buttonStyle(.plain)
        .background(Color.primary.opacity(0.06), in: Capsule())
        .help(localization.text(.createACollection))
        .accessibilityLabel(localization.text(.createCollection))
        .accessibilityIdentifier("createCollectionButton")
    }

    private func collectionButton(
        title: String,
        color: Color,
        systemImage: String?,
        collectionID: ClipCollection.ID?,
        collection: ClipCollection? = nil
    ) -> some View {
        let isSelected = selectedCollectionID == collectionID
        let isHovered = collectionID == hoveredCollectionID

        return ZStack(alignment: .trailing) {
            selectButton(
                title: title,
                systemImage: systemImage,
                collectionID: collectionID,
                collection: collection,
                isSelected: isSelected
            )

            if isHovered, let collection {
                deleteButton(for: collection)
            }
        }
        .background(
            Color.primary.opacity(isSelected ? 0.12 : 0.035),
            in: Capsule()
        )
        .overlay {
            Capsule().strokeBorder(
                isSelected ? color.opacity(0.75) : Color.clear,
                lineWidth: 1
            )
        }
        .contentShape(Capsule())
        .onHover { isHovering in
            withAnimation(.easeOut(duration: 0.12)) {
                hoveredCollectionID = isHovering ? collectionID : nil
            }
        }
    }

    private func selectButton(
        title: String,
        systemImage: String?,
        collectionID: ClipCollection.ID?,
        collection: ClipCollection?,
        isSelected: Bool
    ) -> some View {
        Button {
            onSelect(collectionID)
        } label: {
            HStack(spacing: 6) {
                collectionIcon(
                    color: collection.map { collectionColor($0.colorHex) } ?? .secondary,
                    systemImage: systemImage
                )
                Text(title).lineLimit(1)
            }
            .font(.caption.weight(isSelected ? .semibold : .medium))
            .padding(.leading, 10)
            .padding(.trailing, collection == nil ? 10 : 32)
            .frame(height: 24)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(localization.text(.openCollectionFormat, title))
        .accessibilityValue(
            localization.text(isSelected ? .selected : .notSelected)
        )
    }

    @ViewBuilder
    private func collectionIcon(color: Color, systemImage: String?) -> some View {
        if let systemImage {
            Image(systemName: systemImage)
        } else {
            Circle()
                .fill(color)
                .frame(width: 9, height: 9)
        }
    }

    private func deleteButton(for collection: ClipCollection) -> some View {
        Button {
            onDeleteRequest(collection)
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.caption.weight(.semibold))
                .symbolRenderingMode(.hierarchical)
                .frame(width: 24, height: 24)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .padding(.trailing, 3)
        .help(localization.text(.deleteItemFormat, collection.name))
        .accessibilityLabel(localization.text(.deleteCollectionFormat, collection.name))
        .accessibilityIdentifier("deleteCollection-\(collection.id.uuidString)")
        .transition(.scale(scale: 0.75).combined(with: .opacity))
    }

    private func collectionColor(_ hex: String) -> Color {
        guard let color = HexColor(hex) else {
            return .accentColor
        }
        return Color(red: color.red, green: color.green, blue: color.blue, opacity: color.alpha)
    }
}
