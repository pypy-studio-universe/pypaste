import Observation
import PyPasteDomain
import PyPasteSharedUI

public enum QuickBarCollectionDialog: Equatable, Sendable {
    case create
    case delete(ClipCollection)
}

@MainActor
@Observable
public final class QuickBarModel {
    public private(set) var clips: [Clip] = []
    public private(set) var searchQuery = ""
    public private(set) var feedbackMessage: String?
    public private(set) var processingClipID: Clip.ID?
    public private(set) var selectedClipID: Clip.ID?
    public private(set) var collections: [ClipCollection] = []
    public private(set) var selectedCollectionID: ClipCollection.ID?
    public private(set) var isLoadingCollection = false
    public private(set) var collectionDialog: QuickBarCollectionDialog?

    private let maximumClipCount: Int
    private let searchEngine: ClipSearchEngine
    let localization: AppLocalization
    private var sourceClips: [Clip] = []
    private let onPaste: (Clip) -> Void
    private let onDismiss: () -> Void
    private let onMove: (Clip.ID, Clip.ID, ClipPlacement) -> Void
    private let onDelete: (Clip.ID) -> Void
    private let onSelectCollection: (ClipCollection.ID?) -> Void
    private let onAddToCollection: (Clip.ID, ClipCollection.ID) -> Void
    private let onCreateCollection: (String, String) -> Void
    private let onDeleteCollection: (ClipCollection.ID) -> Void
    private var collectionIDsByClipID: [Clip.ID: Set<ClipCollection.ID>] = [:]

    public init(
        maximumClipCount: Int = 200,
        searchEngine: ClipSearchEngine = ClipSearchEngine(),
        onPaste: @escaping (Clip) -> Void,
        onDismiss: @escaping () -> Void,
        onMove: @escaping (Clip.ID, Clip.ID, ClipPlacement) -> Void = { _, _, _ in },
        onDelete: @escaping (Clip.ID) -> Void = { _ in },
        onSelectCollection: @escaping (ClipCollection.ID?) -> Void = { _ in },
        onAddToCollection: @escaping (Clip.ID, ClipCollection.ID) -> Void = { _, _ in },
        onCreateCollection: @escaping (String, String) -> Void = { _, _ in },
        onDeleteCollection: @escaping (ClipCollection.ID) -> Void = { _ in },
        localization: AppLocalization = .shared
    ) {
        self.maximumClipCount = maximumClipCount
        self.searchEngine = searchEngine
        self.localization = localization
        self.onPaste = onPaste
        self.onDismiss = onDismiss
        self.onMove = onMove
        self.onDelete = onDelete
        self.onSelectCollection = onSelectCollection
        self.onAddToCollection = onAddToCollection
        self.onCreateCollection = onCreateCollection
        self.onDeleteCollection = onDeleteCollection
    }

    public func prepareForPresentation(with clips: [Clip]) {
        searchQuery = ""
        selectedCollectionID = nil
        isLoadingCollection = false
        collectionDialog = nil
        replaceClips(clips)
        selectedClipID = self.clips.first?.id
        feedbackMessage = nil
        processingClipID = nil
    }

    public func prepareForPresentation(with snapshot: ClipCollectionSnapshot) {
        collections = snapshot.collections
        collectionIDsByClipID = snapshot.collectionIDsByClipID
        prepareForPresentation(with: snapshot.clips)
    }

    public func selectCollection(_ collectionID: ClipCollection.ID?) {
        guard collectionID != selectedCollectionID else {
            return
        }

        selectedCollectionID = collectionID
        searchQuery = ""
        feedbackMessage = nil
        isLoadingCollection = true
        sourceClips = []
        clips = []
        selectedClipID = nil
        onSelectCollection(collectionID)
    }

    public func applyCollectionSnapshot(
        _ snapshot: ClipCollectionSnapshot,
        for collectionID: ClipCollection.ID?
    ) {
        guard selectedCollectionID == collectionID else {
            return
        }

        collections = snapshot.collections
        collectionIDsByClipID = snapshot.collectionIDsByClipID
        replaceClips(snapshot.clips)
        selectedClipID = clips.first?.id
        isLoadingCollection = false
    }

    public func addToCollection(
        clipID: Clip.ID,
        collectionID: ClipCollection.ID
    ) {
        guard processingClipID == nil,
            !collectionIDs(for: clipID).contains(collectionID)
        else {
            return
        }

        feedbackMessage = localization.text(.savingToCollection)
        onAddToCollection(clipID, collectionID)
    }

    public func createCollection(named name: String) {
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedName.isEmpty else {
            feedbackMessage = localization.text(.enterCollectionName)
            return
        }

        let colors = ["#BF5AF2", "#64D2FF", "#FF9F0A", "#FF375F", "#5E5CE6", "#AC8E68"]
        let colorHex = colors[collections.count % colors.count]
        feedbackMessage = localization.text(.creatingCollection)
        onCreateCollection(normalizedName, colorHex)
    }

    public func deleteCollection(_ collectionID: ClipCollection.ID) {
        guard processingClipID == nil,
            collections.contains(where: { $0.id == collectionID })
        else {
            return
        }

        feedbackMessage = localization.text(.deletingCollection)
        onDeleteCollection(collectionID)
    }

    public func applyDeletedCollection(_ collectionID: ClipCollection.ID) {
        collections.removeAll(where: { $0.id == collectionID })
        guard selectedCollectionID == collectionID else {
            return
        }

        selectedCollectionID = nil
        searchQuery = ""
        isLoadingCollection = true
        sourceClips = []
        clips = []
        selectedClipID = nil
    }

    public func collectionIDs(for clipID: Clip.ID) -> Set<ClipCollection.ID> {
        collectionIDsByClipID[clipID] ?? []
    }

    public func completeCollectionUpdate(feedbackMessage: String) {
        isLoadingCollection = false
        self.feedbackMessage = feedbackMessage
    }

    public func replaceClips(_ clips: [Clip]) {
        sourceClips = Array(clips.prefix(maximumClipCount))
        refreshSearchResults()
    }

    public func upsert(_ clip: Clip) {
        ClipListMutation.upsertAtFront(clip, in: &sourceClips)

        if sourceClips.count > maximumClipCount {
            sourceClips.removeLast(sourceClips.count - maximumClipCount)
        }
        refreshSearchResults()
    }

    public func update(_ clip: Clip) {
        ClipListMutation.updatePreservingPosition(clip, in: &sourceClips)
        refreshSearchResults()
    }

    public func updateSearchQuery(_ query: String) {
        searchQuery = query
        feedbackMessage = nil
        refreshSearchResults()
    }

    @discardableResult
    public func move(
        _ clipID: Clip.ID,
        relativeTo targetID: Clip.ID,
        placement: ClipPlacement
    ) -> Bool {
        guard processingClipID == nil,
            ClipListMutation.move(
                clipID,
                relativeTo: targetID,
                placement: placement,
                in: &sourceClips
            )
        else {
            return false
        }

        refreshSearchResults()
        onMove(clipID, targetID, placement)
        return true
    }

    public func moveToTrash(_ clipID: Clip.ID) {
        guard processingClipID == nil,
            let removedIndex = clips.firstIndex(where: { $0.id == clipID }),
            ClipListMutation.remove(clipID, from: &sourceClips) != nil
        else {
            return
        }

        refreshSearchResults(selectingFirstIfNeeded: false)
        if selectedClipID == clipID {
            selectedClipID = ClipListMutation.adjacentID(
                afterRemovingAt: removedIndex,
                from: clips
            )
        }

        onDelete(clipID)
    }

    public func selectPrevious() {
        moveSelection(by: -1)
    }

    public func selectNext() {
        moveSelection(by: 1)
    }

    public func pasteSelected() {
        guard
            let selectedClipID,
            let clip = clips.first(where: { $0.id == selectedClipID })
        else {
            return
        }

        paste(clip)
    }

    public func paste(_ clip: Clip) {
        guard processingClipID == nil else {
            return
        }

        selectedClipID = clip.id
        processingClipID = clip.id
        feedbackMessage = nil
        onPaste(clip)
    }

    public func completePaste(feedbackMessage: String? = nil) {
        processingClipID = nil
        self.feedbackMessage = feedbackMessage
    }

    public func dismiss() {
        onDismiss()
    }

    private func moveSelection(by offset: Int) {
        guard !clips.isEmpty, processingClipID == nil else {
            return
        }

        let currentIndex =
            selectedClipID.flatMap { selectedClipID in
                clips.firstIndex(where: { $0.id == selectedClipID })
            } ?? 0
        let targetIndex = min(
            max(currentIndex + offset, clips.startIndex), clips.index(before: clips.endIndex))
        selectedClipID = clips[targetIndex].id
    }

    private func refreshSearchResults(selectingFirstIfNeeded: Bool = true) {
        clips = searchEngine.results(matching: searchQuery, in: sourceClips)

        if !clips.contains(where: { $0.id == selectedClipID }) {
            selectedClipID = selectingFirstIfNeeded ? clips.first?.id : selectedClipID
        }
    }
}

public extension QuickBarModel {
    func presentCreateCollectionDialog() {
        collectionDialog = .create
    }

    func presentDeleteCollectionDialog(for collection: ClipCollection) {
        collectionDialog = .delete(collection)
    }

    @discardableResult
    func dismissCollectionDialog() -> Bool {
        guard collectionDialog != nil else {
            return false
        }

        collectionDialog = nil
        return true
    }

    var isPresentingCollectionDialog: Bool {
        collectionDialog != nil
    }

    var collectionPendingDeletion: ClipCollection? {
        guard case .delete(let collection) = collectionDialog else {
            return nil
        }
        return collection
    }

    var totalClipCount: Int {
        sourceClips.count
    }

    var isSearchActive: Bool {
        !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

}

enum ClipListMutation {
    static func upsertAtFront(_ clip: Clip, in clips: inout [Clip]) {
        clips.removeAll { $0.id == clip.id }
        clips.insert(clip, at: 0)
    }

    static func updatePreservingPosition(_ clip: Clip, in clips: inout [Clip]) {
        guard let index = clips.firstIndex(where: { $0.id == clip.id }) else {
            return
        }

        clips[index] = clip
    }

    static func move(
        _ clipID: Clip.ID,
        relativeTo targetID: Clip.ID,
        placement: ClipPlacement,
        in clips: inout [Clip]
    ) -> Bool {
        guard clipID != targetID,
            let sourceIndex = clips.firstIndex(where: { $0.id == clipID }),
            clips.contains(where: { $0.id == targetID })
        else {
            return false
        }

        let originalIDs = clips.map(\.id)
        let clip = clips.remove(at: sourceIndex)

        guard let targetIndex = clips.firstIndex(where: { $0.id == targetID }) else {
            clips.insert(clip, at: sourceIndex)
            return false
        }

        let insertionIndex = placement == .before ? targetIndex : targetIndex + 1
        clips.insert(clip, at: insertionIndex)
        return clips.map(\.id) != originalIDs
    }

    static func remove(_ clipID: Clip.ID, from clips: inout [Clip]) -> Int? {
        guard let index = clips.firstIndex(where: { $0.id == clipID }) else {
            return nil
        }

        clips.remove(at: index)
        return index
    }

    static func adjacentID(afterRemovingAt index: Int, from clips: [Clip]) -> Clip.ID? {
        guard !clips.isEmpty else {
            return nil
        }

        return clips[min(index, clips.index(before: clips.endIndex))].id
    }
}
