import PyPasteDomain
import PyPasteSharedUI
import SwiftUI

struct QuickBarCollectionDialogView: View {
    let dialog: QuickBarCollectionDialog
    @Binding var collectionName: String
    let onCancel: () -> Void
    let onCreate: () -> Void
    let onDelete: (ClipCollection) -> Void
    @Bindable var localization: AppLocalization
    @FocusState private var isNameFieldFocused: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.24)
                .contentShape(Rectangle())
                .onTapGesture {}

            dialogContent
                .padding(18)
                .frame(width: 390)
                .background(.regularMaterial, in: dialogShape)
                .overlay {
                    dialogShape.strokeBorder(Color.primary.opacity(0.16), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.28), radius: 20, y: 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("collectionDialog")
        .onAppear {
            if dialog == .create {
                isNameFieldFocused = true
            }
        }
    }

    @ViewBuilder
    private var dialogContent: some View {
        switch dialog {
        case .create:
            createContent
        case .delete(let collection):
            deleteContent(collection)
        }
    }

    private var createContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            dialogHeader(
                title: localization.text(.newCollection),
                systemImage: "folder.badge.plus"
            )
            Text(localization.text(.collectionPersistence))
                .font(.callout)
                .foregroundStyle(.secondary)

            TextField(localization.text(.collectionName), text: $collectionName)
                .textFieldStyle(.roundedBorder)
                .focused($isNameFieldFocused)
                .onSubmit(createIfAvailable)
                .accessibilityIdentifier("newCollectionNameField")

            actionRow {
                Button(localization.text(.create), action: createIfAvailable)
                    .keyboardShortcut(.defaultAction)
                    .disabled(normalizedCollectionName.isEmpty)
            }
        }
    }

    private func deleteContent(_ collection: ClipCollection) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            dialogHeader(
                title: localization.text(.deleteCollectionQuestion),
                systemImage: "trash"
            )
            Text(localization.text(.deleteCollectionMessageFormat, collection.name))
                .font(.callout)
                .foregroundStyle(.secondary)

            actionRow {
                Button(localization.text(.delete), role: .destructive) {
                    onDelete(collection)
                }
                .keyboardShortcut(.defaultAction)
            }
        }
    }

    private func dialogHeader(title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.headline)
            .accessibilityAddTraits(.isHeader)
    }

    private func actionRow<PrimaryAction: View>(
        @ViewBuilder primaryAction: () -> PrimaryAction
    ) -> some View {
        HStack {
            Spacer()
            Button(localization.text(.cancel), role: .cancel, action: cancel)
                .keyboardShortcut(.cancelAction)
            primaryAction()
                .buttonStyle(.borderedProminent)
        }
    }

    private var dialogShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
    }

    private var normalizedCollectionName: String {
        collectionName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func createIfAvailable() {
        guard !normalizedCollectionName.isEmpty else {
            return
        }
        onCreate()
    }

    private func cancel() {
        collectionName = ""
        onCancel()
    }
}
