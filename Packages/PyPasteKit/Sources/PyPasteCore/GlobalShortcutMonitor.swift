import Carbon.HIToolbox
import Foundation

@MainActor
public protocol GlobalShortcutMonitoring: AnyObject {
    var isRegistered: Bool { get }
    var displayName: String { get }

    func start(onKeyPressed: @escaping @MainActor () -> Void) throws
    func stop()
}

public enum GlobalShortcutError: LocalizedError, Equatable {
    case eventHandlerRegistrationFailed(OSStatus)
    case hotKeyRegistrationFailed(OSStatus)

    public var errorDescription: String? {
        switch self {
        case .eventHandlerRegistrationFailed(let status):
            "PyPaste could not install its shortcut handler (error \(status))."
        case .hotKeyRegistrationFailed(let status):
            if status == eventHotKeyExistsErr {
                "Command-Shift-V is already used by another application."
            } else {
                "PyPaste could not register Command-Shift-V (error \(status))."
            }
        }
    }
}

private enum PyPasteHotKey {
    static let signature: OSType = 0x5059_5053  // PYPS
    static let identifier: UInt32 = 1
}

@MainActor
public final class CarbonGlobalShortcutMonitor: GlobalShortcutMonitoring {
    public let displayName = "⌘⇧V"
    public private(set) var isRegistered = false

    private var eventHandlerReference: EventHandlerRef?
    private var hotKeyReference: EventHotKeyRef?
    private var onKeyPressed: (@MainActor () -> Void)?

    public init() {}

    public func start(onKeyPressed: @escaping @MainActor () -> Void) throws {
        self.onKeyPressed = onKeyPressed

        guard !isRegistered else {
            return
        }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let context = Unmanaged.passUnretained(self).toOpaque()
        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            pyPasteHotKeyEventHandler,
            1,
            &eventType,
            context,
            &eventHandlerReference
        )

        guard handlerStatus == noErr else {
            self.onKeyPressed = nil
            throw GlobalShortcutError.eventHandlerRegistrationFailed(handlerStatus)
        }

        let hotKeyID = EventHotKeyID(
            signature: PyPasteHotKey.signature,
            id: PyPasteHotKey.identifier
        )
        let modifiers = UInt32(cmdKey | shiftKey)
        let registrationStatus = RegisterEventHotKey(
            UInt32(kVK_ANSI_V),
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyReference
        )

        guard registrationStatus == noErr else {
            removeEventHandler()
            self.onKeyPressed = nil
            throw GlobalShortcutError.hotKeyRegistrationFailed(registrationStatus)
        }

        isRegistered = true
    }

    public func stop() {
        if let hotKeyReference {
            UnregisterEventHotKey(hotKeyReference)
            self.hotKeyReference = nil
        }

        removeEventHandler()
        onKeyPressed = nil
        isRegistered = false
    }

    func handleKeyPress() {
        onKeyPressed?()
    }

    private func removeEventHandler() {
        if let eventHandlerReference {
            RemoveEventHandler(eventHandlerReference)
            self.eventHandlerReference = nil
        }
    }
}

private func pyPasteHotKeyEventHandler(
    _: EventHandlerCallRef?,
    _ event: EventRef?,
    _ context: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let event, let context else {
        return OSStatus(eventNotHandledErr)
    }

    var hotKeyID = EventHotKeyID(signature: 0, id: 0)
    let parameterStatus = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )

    guard parameterStatus == noErr,
        hotKeyID.signature == PyPasteHotKey.signature,
        hotKeyID.id == PyPasteHotKey.identifier
    else {
        return OSStatus(eventNotHandledErr)
    }

    let monitor = Unmanaged<CarbonGlobalShortcutMonitor>
        .fromOpaque(context)
        .takeUnretainedValue()

    Task { @MainActor in
        monitor.handleKeyPress()
    }

    return noErr
}
