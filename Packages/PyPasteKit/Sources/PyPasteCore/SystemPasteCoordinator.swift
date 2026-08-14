import AppKit
import ApplicationServices
import Carbon.HIToolbox
import CoreGraphics
import Foundation

public enum PasteResult: Equatable, Sendable {
    case pasted
    case copiedOnlyAccessibilityDenied
    case targetUnavailable
    case keyEventCreationFailed
}

public struct PasteTarget: Equatable, Sendable {
    public let processIdentifier: Int32

    public init(processIdentifier: Int32) {
        self.processIdentifier = processIdentifier
    }
}

@MainActor
public protocol PasteCoordinating: AnyObject {
    func paste(to target: PasteTarget?) async -> PasteResult
}

@MainActor
public final class SystemPasteCoordinator: PasteCoordinating {
    private let activationDelay: Duration
    private let isAccessibilityTrusted: () -> Bool
    private let requestAccessibilityAccess: () -> Void
    private let activateApplication: (PasteTarget) -> Bool
    private let postPasteKeyStroke: () -> Bool
    private var hasRequestedAccessibilityAccess = false

    public init(activationDelay: Duration = .milliseconds(120)) {
        self.activationDelay = activationDelay
        isAccessibilityTrusted = { AXIsProcessTrusted() }
        requestAccessibilityAccess = Self.requestSystemAccessibilityAccess
        activateApplication = { target in
            guard
                let application = NSRunningApplication(
                    processIdentifier: target.processIdentifier
                )
            else {
                return false
            }

            return application.activate(options: [])
        }
        postPasteKeyStroke = Self.postCommandV
    }

    init(
        activationDelay: Duration,
        isAccessibilityTrusted: @escaping () -> Bool,
        requestAccessibilityAccess: @escaping () -> Void,
        activateApplication: @escaping (PasteTarget) -> Bool,
        postPasteKeyStroke: @escaping () -> Bool
    ) {
        self.activationDelay = activationDelay
        self.isAccessibilityTrusted = isAccessibilityTrusted
        self.requestAccessibilityAccess = requestAccessibilityAccess
        self.activateApplication = activateApplication
        self.postPasteKeyStroke = postPasteKeyStroke
    }

    public func paste(to target: PasteTarget?) async -> PasteResult {
        guard let target else {
            return .targetUnavailable
        }

        guard isAccessibilityTrusted() else {
            requestAccessibilityAccessIfNeeded()
            return .copiedOnlyAccessibilityDenied
        }

        guard activateApplication(target) else {
            return .targetUnavailable
        }

        if activationDelay > .zero {
            try? await Task.sleep(for: activationDelay)
        }

        guard postPasteKeyStroke() else {
            return .keyEventCreationFailed
        }

        return .pasted
    }

    private func requestAccessibilityAccessIfNeeded() {
        guard !hasRequestedAccessibilityAccess else {
            return
        }

        hasRequestedAccessibilityAccess = true
        requestAccessibilityAccess()
    }

    private static func requestSystemAccessibilityAccess() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    private static func postCommandV() -> Bool {
        let source = CGEventSource(stateID: .hidSystemState)

        guard
            let keyDown = CGEvent(
                keyboardEventSource: source,
                virtualKey: CGKeyCode(kVK_ANSI_V),
                keyDown: true
            ),
            let keyUp = CGEvent(
                keyboardEventSource: source,
                virtualKey: CGKeyCode(kVK_ANSI_V),
                keyDown: false
            )
        else {
            return false
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
        return true
    }
}
