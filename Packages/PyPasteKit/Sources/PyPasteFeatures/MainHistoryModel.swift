import Observation
import PyPasteDomain

@MainActor
@Observable
public final class MainHistoryModel {
    public private(set) var clips: [Clip] = []
    public private(set) var searchQuery = ""
    public private(set) var isMonitoringPaused = false
    private let searchEngine: ClipSearchEngine
    private var sourceClips: [Clip] = []

    private let onCopy: (Clip) -> Void
    private let onToggleMonitoring: () -> Void
    private let onMove: (Clip.ID, Clip.ID, ClipPlacement) -> Void
    private let onDelete: (Clip.ID) -> Void

    public init(
        onCopy: @escaping (Clip) -> Void,
        onToggleMonitoring: @escaping () -> Void,
        searchEngine: ClipSearchEngine = ClipSearchEngine(),
        onMove: @escaping (Clip.ID, Clip.ID, ClipPlacement) -> Void = { _, _, _ in },
        onDelete: @escaping (Clip.ID) -> Void = { _ in }
    ) {
        self.onCopy = onCopy
        self.onToggleMonitoring = onToggleMonitoring
        self.searchEngine = searchEngine
        self.onMove = onMove
        self.onDelete = onDelete
    }

    public func replaceClips(_ clips: [Clip]) {
        sourceClips = clips
        refreshSearchResults()
    }

    public func upsert(_ clip: Clip) {
        ClipListMutation.upsertAtFront(clip, in: &sourceClips)
        refreshSearchResults()
    }

    public func update(_ clip: Clip) {
        ClipListMutation.updatePreservingPosition(clip, in: &sourceClips)
        refreshSearchResults()
    }

    public func updateSearchQuery(_ query: String) {
        searchQuery = query
        refreshSearchResults()
    }

    public func move(
        _ clipID: Clip.ID,
        relativeTo targetID: Clip.ID,
        placement: ClipPlacement
    ) {
        guard
            ClipListMutation.move(
                clipID,
                relativeTo: targetID,
                placement: placement,
                in: &sourceClips
            )
        else {
            return
        }

        refreshSearchResults()
        onMove(clipID, targetID, placement)
    }

    public func moveToTrash(_ clipID: Clip.ID) {
        guard ClipListMutation.remove(clipID, from: &sourceClips) != nil else {
            return
        }

        refreshSearchResults()
        onDelete(clipID)
    }

    public func setMonitoringPaused(_ isPaused: Bool) {
        isMonitoringPaused = isPaused
    }

    public func copy(_ clip: Clip) {
        onCopy(clip)
    }

    public func toggleMonitoring() {
        onToggleMonitoring()
    }

    public var totalClipCount: Int {
        sourceClips.count
    }

    public var isSearchActive: Bool {
        !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func refreshSearchResults() {
        clips = searchEngine.results(matching: searchQuery, in: sourceClips)
    }
}
