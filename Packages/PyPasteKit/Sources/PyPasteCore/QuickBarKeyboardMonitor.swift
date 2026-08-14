import Carbon.HIToolbox
import Foundation

public enum QuickBarKeyboardCommand: UInt32, CaseIterable, Sendable {
    case selectPrevious = 1
    case selectNext = 2
    case pasteSelected = 3
    case dismiss = 4

    fileprivate var virtualKeyCode: UInt32 {
        switch self {
        case .selectPrevious:
            UInt32(kVK_LeftArrow)
        case .selectNext:
            UInt32(kVK_RightArrow)
        case .pasteSelected:
            UInt32(kVK_Return)
        case .dismiss:
            UInt32(kVK_Escape)
        }
    }
}

@MainActor
public protocol QuickBarKeyboardMonitoring: AnyObject {
    var isRegistered: Bool { get }

    func start(onCommand: @escaping @MainActor (QuickBarKeyboardCommand) -> Void) throws
    func stop()
}

public enum QuickBarKeyboardMonitorError: LocalizedError, Equatable {
    case eventHandlerRegistrationFailed(OSStatus)
    case hotKeyRegistrationFailed(QuickBarKeyboardCommand, OSStatus)

    public var errorDescription: String? {
        switch self {
        case .eventHandlerRegistrationFailed(let status):
            "PyPaste could not install Quick Bar keyboard routing (error \(status))."
        case .hotKeyRegistrationFailed(let command, let status):
            "PyPaste could not register Quick Bar command \(command) (error \(status))."
        }
    }
}

private enum QuickBarHotKey {
    static let signature: OSType = 0x5059_514B  // PYQK
}

@MainActor
public final class CarbonQuickBarKeyboardMonitor: QuickBarKeyboardMonitoring {
    public private(set) var isRegistered = false

    private var eventHandlerReference: EventHandlerRef?
    private var hotKeyReferences: [EventHotKeyRef] = []
    private var onCommand: (@MainActor (QuickBarKeyboardCommand) -> Void)?

    public init() {}

    public func start(
        onCommand: @escaping @MainActor (QuickBarKeyboardCommand) -> Void
    ) throws {
        self.onCommand = onCommand

        guard !isRegistered else {
            return
        }

        try installEventHandler()

        do {
            for command in QuickBarKeyboardCommand.allCases {
                try register(command)
            }
        } catch {
            stop()
            throw error
        }

        isRegistered = true
    }

    public func stop() {
        for hotKeyReference in hotKeyReferences {
            UnregisterEventHotKey(hotKeyReference)
        }
        hotKeyReferences.removeAll()

        if let eventHandlerReference {
            RemoveEventHandler(eventHandlerReference)
            self.eventHandlerReference = nil
        }

        onCommand = nil
        isRegistered = false
    }

    func handle(commandID: UInt32) {
        guard let command = QuickBarKeyboardCommand(rawValue: commandID) else {
            return
        }

        onCommand?(command)
    }

    private func installEventHandler() throws {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let context = Unmanaged.passUnretained(self).toOpaque()
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            quickBarHotKeyEventHandler,
            1,
            &eventType,
            context,
            &eventHandlerReference
        )

        guard status == noErr else {
            throw QuickBarKeyboardMonitorError.eventHandlerRegistrationFailed(status)
        }
    }

    private func register(_ command: QuickBarKeyboardCommand) throws {
        let hotKeyID = EventHotKeyID(
            signature: QuickBarHotKey.signature,
            id: command.rawValue
        )
        var reference: EventHotKeyRef?
        let status = RegisterEventHotKey(
            command.virtualKeyCode,
            0,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &reference
        )

        guard status == noErr, let reference else {
            throw QuickBarKeyboardMonitorError.hotKeyRegistrationFailed(command, status)
        }

        hotKeyReferences.append(reference)
    }
}

private func quickBarHotKeyEventHandler(
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

    guard parameterStatus == noErr, hotKeyID.signature == QuickBarHotKey.signature else {
        return OSStatus(eventNotHandledErr)
    }

    let monitor = Unmanaged<CarbonQuickBarKeyboardMonitor>
        .fromOpaque(context)
        .takeUnretainedValue()
    let commandID = hotKeyID.id
    Task { @MainActor in
        monitor.handle(commandID: commandID)
    }

    return noErr
}
