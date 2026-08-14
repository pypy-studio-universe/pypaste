import PyPasteFeatures
import PyPasteSharedUI
import SwiftUI

@main
struct PyPasteApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsPlaceholderView(localization: .shared)
        }
    }
}
