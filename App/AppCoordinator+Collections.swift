import AppKit
import Foundation
import PyPasteCore
import PyPasteDomain
import PyPasteSharedUI

@MainActor
extension AppCoordinator {
    func currentPasteTarget() -> PasteTarget? {
        guard let application = NSWorkspace.shared.frontmostApplication,
            application.processIdentifier != ProcessInfo.processInfo.processIdentifier
        else {
            return nil
        }

        return PasteTarget(processIdentifier: application.processIdentifier)
    }

    func selectCollection(_ collectionID: ClipCollection.ID?) {
        refreshCollection(collectionID, successMessage: nil)
    }

    func addClip(_ clipID: Clip.ID, to collectionID: ClipCollection.ID) {
        let selectedCollectionID = quickBarModel.selectedCollectionID
        let revision = nextCollectionViewRevision()

        Task { [weak self] in
            guard let self else {
                return
            }

            do {
                try await dependencies.clipCollectionManager.addClip(
                    id: clipID,
                    to: collectionID,
                    at: Date()
                )
                try await loadCollection(
                    selectedCollectionID,
                    revision: revision,
                    successMessage: localization.text(.savedToCollection)
                )
            } catch {
                guard revision == collectionViewRevision else {
                    return
                }
                quickBarModel.completeCollectionUpdate(
                    feedbackMessage: localization.text(.couldNotSaveToCollection)
                )
                dependencies.logger.error(
                    "Adding a clipboard item to a collection failed: \(error.localizedDescription)"
                )
            }
        }
    }

    func createCollection(name: String, colorHex: String) {
        let selectedCollectionID = quickBarModel.selectedCollectionID
        let revision = nextCollectionViewRevision()

        Task { [weak self] in
            guard let self else {
                return
            }

            do {
                _ = try await dependencies.clipCollectionManager.createCollection(
                    name: name,
                    colorHex: colorHex,
                    at: Date()
                )
                try await loadCollection(
                    selectedCollectionID,
                    revision: revision,
                    successMessage: localization.text(.collectionCreated)
                )
            } catch {
                guard revision == collectionViewRevision else {
                    return
                }
                quickBarModel.completeCollectionUpdate(
                    feedbackMessage: localization.text(.collectionNameInUse)
                )
                dependencies.logger.error(
                    "Creating a clipboard collection failed: \(error.localizedDescription)"
                )
            }
        }
    }

    func deleteCollection(_ collectionID: ClipCollection.ID) {
        let selectedCollectionID = quickBarModel.selectedCollectionID
        let revision = nextCollectionViewRevision()

        Task { [weak self] in
            guard let self else {
                return
            }

            do {
                try await dependencies.clipCollectionManager.deleteCollection(id: collectionID)
                guard revision == collectionViewRevision else {
                    return
                }

                quickBarModel.applyDeletedCollection(collectionID)
                let collectionToLoad =
                    selectedCollectionID == collectionID ? nil : selectedCollectionID
                try await loadCollection(
                    collectionToLoad,
                    revision: revision,
                    successMessage: localization.text(.collectionDeleted)
                )
            } catch {
                guard revision == collectionViewRevision else {
                    return
                }
                quickBarModel.completeCollectionUpdate(
                    feedbackMessage: localization.text(.couldNotDeleteCollection)
                )
                dependencies.logger.error(
                    "Deleting a clipboard collection failed: \(error.localizedDescription)"
                )
            }
        }
    }

    func refreshSelectedCollection() {
        refreshCollection(quickBarModel.selectedCollectionID, successMessage: nil)
    }

    func refreshCollection(
        _ collectionID: ClipCollection.ID?,
        successMessage: String?
    ) {
        let revision = nextCollectionViewRevision()
        Task { [weak self] in
            guard let self else {
                return
            }

            do {
                try await loadCollection(
                    collectionID,
                    revision: revision,
                    successMessage: successMessage
                )
            } catch {
                guard revision == collectionViewRevision else {
                    return
                }
                quickBarModel.completeCollectionUpdate(
                    feedbackMessage: localization.text(.couldNotLoadCollection)
                )
                dependencies.logger.error(
                    "Loading a clipboard collection failed: \(error.localizedDescription)"
                )
            }
        }
    }

    func loadCollection(
        _ collectionID: ClipCollection.ID?,
        revision: Int,
        successMessage: String?
    ) async throws {
        let snapshot = try await dependencies.clipCollectionManager.collectionSnapshot(
            selectedCollectionID: collectionID,
            limit: 200
        )
        guard revision == collectionViewRevision else {
            return
        }

        if collectionID == nil {
            clipboardCollectionSnapshot = snapshot
            historyModel.replaceClips(snapshot.clips)
        }
        quickBarModel.applyCollectionSnapshot(snapshot, for: collectionID)
        if let successMessage {
            quickBarModel.completeCollectionUpdate(feedbackMessage: successMessage)
        }
    }

    func nextCollectionViewRevision() -> Int {
        collectionViewRevision &+= 1
        return collectionViewRevision
    }

    func handlePasteResult(_ result: PasteResult) {
        switch result {
        case .pasted:
            quickBarModel.completePaste(feedbackMessage: localization.text(.pasted))
            dependencies.logger.info("Quick Bar pasted a clip into the previous application")
        case .copiedOnlyAccessibilityDenied:
            quickBarModel.completePaste(
                feedbackMessage: localization.text(.accessibilityRequired)
            )
            dependencies.logger.notice(
                "Quick Bar used copy-only fallback because Accessibility is unavailable"
            )
        case .targetUnavailable:
            quickBarModel.completePaste(
                feedbackMessage: localization.text(.pasteTargetUnavailable)
            )
            dependencies.logger.notice("Quick Bar paste target is unavailable")
        case .keyEventCreationFailed:
            quickBarModel.completePaste(
                feedbackMessage: localization.text(.commandVFailed)
            )
            dependencies.logger.error("Quick Bar could not create the paste key event")
        }
    }
}
