import AppKit
import Foundation
import PyPasteDomain

@MainActor
public protocol WorkspaceMonitoring: AnyObject {
    var frontmostApplication: SourceApplication? { get }
    var onSleepStateChange: ((Bool) -> Void)? { get set }

    func start()
    func stop()
}

@MainActor
public final class SystemWorkspaceMonitor: NSObject, WorkspaceMonitoring {
    public private(set) var frontmostApplication: SourceApplication?
    public var onSleepStateChange: ((Bool) -> Void)?

    private let workspace: NSWorkspace
    private var applicationTracker: FrontmostApplicationTracker
    private var isStarted = false

    public init(workspace: NSWorkspace = .shared) {
        self.workspace = workspace
        applicationTracker = FrontmostApplicationTracker(
            ignoredProcessIdentifier: ProcessInfo.processInfo.processIdentifier
        )
        super.init()
    }

    public func start() {
        guard !isStarted else {
            return
        }

        isStarted = true
        updateFrontmostApplication(workspace.frontmostApplication)
        let center = workspace.notificationCenter
        center.addObserver(
            self,
            selector: #selector(applicationDidActivate),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
        center.addObserver(
            self,
            selector: #selector(systemWillSleep(_:)),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
        center.addObserver(
            self,
            selector: #selector(systemDidWake(_:)),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
        center.addObserver(
            self,
            selector: #selector(sessionDidResignActive(_:)),
            name: NSWorkspace.sessionDidResignActiveNotification,
            object: nil
        )
        center.addObserver(
            self,
            selector: #selector(sessionDidBecomeActive(_:)),
            name: NSWorkspace.sessionDidBecomeActiveNotification,
            object: nil
        )
    }

    public func stop() {
        guard isStarted else {
            return
        }

        workspace.notificationCenter.removeObserver(self)
        isStarted = false
    }

    @objc
    private func applicationDidActivate(_ notification: Notification) {
        let application =
            notification.userInfo?[NSWorkspace.applicationUserInfoKey]
            as? NSRunningApplication
        updateFrontmostApplication(application ?? workspace.frontmostApplication)
    }

    @objc
    private func systemWillSleep(_ notification: Notification) {
        onSleepStateChange?(true)
    }

    @objc
    private func systemDidWake(_ notification: Notification) {
        updateFrontmostApplication(workspace.frontmostApplication)
        onSleepStateChange?(false)
    }

    @objc
    private func sessionDidResignActive(_ notification: Notification) {
        onSleepStateChange?(true)
    }

    @objc
    private func sessionDidBecomeActive(_ notification: Notification) {
        updateFrontmostApplication(workspace.frontmostApplication)
        onSleepStateChange?(false)
    }

    private func updateFrontmostApplication(_ application: NSRunningApplication?) {
        applicationTracker.record(application.map(WorkspaceApplicationSnapshot.init))
        frontmostApplication = applicationTracker.frontmostApplication
    }
}

struct WorkspaceApplicationSnapshot: Equatable, Sendable {
    let processIdentifier: pid_t
    let sourceApplication: SourceApplication

    init(
        processIdentifier: pid_t,
        bundleIdentifier: String?,
        localizedName: String?
    ) {
        self.processIdentifier = processIdentifier
        sourceApplication = SourceApplication(
            bundleIdentifier: bundleIdentifier,
            localizedName: localizedName
        )
    }

    init(application: NSRunningApplication) {
        self.init(
            processIdentifier: application.processIdentifier,
            bundleIdentifier: application.bundleIdentifier,
            localizedName: application.localizedName
        )
    }
}

struct FrontmostApplicationTracker {
    private(set) var frontmostApplication: SourceApplication?

    private let ignoredProcessIdentifier: pid_t

    init(ignoredProcessIdentifier: pid_t) {
        self.ignoredProcessIdentifier = ignoredProcessIdentifier
    }

    mutating func record(_ application: WorkspaceApplicationSnapshot?) {
        guard let application else {
            frontmostApplication = nil
            return
        }

        guard application.processIdentifier != ignoredProcessIdentifier else {
            return
        }

        frontmostApplication = application.sourceApplication
    }
}
