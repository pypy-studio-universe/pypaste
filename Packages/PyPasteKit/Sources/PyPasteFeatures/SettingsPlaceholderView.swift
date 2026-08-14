import PyPasteDomain
import PyPasteSharedUI
import SwiftUI

public struct SettingsPlaceholderView: View {
    @AppStorage(DuplicatePolicy.defaultsKey)
    private var duplicatePolicy = DuplicatePolicy.moveExistingToTop.rawValue
    @Bindable private var localization: AppLocalization

    public init(localization: AppLocalization = .shared) {
        self.localization = localization
    }

    public var body: some View {
        Form {
            Section(localization.text(.clipboard)) {
                LabeledContent(
                    localization.text(.settingsStatus),
                    value: localization.text(.captureEngineEnabled)
                )
                Picker(localization.text(.copiedAgain), selection: $duplicatePolicy) {
                    Text(localization.text(.moveExistingToTop))
                        .tag(DuplicatePolicy.moveExistingToTop.rawValue)
                    Text(localization.text(.createNewItem))
                        .tag(DuplicatePolicy.createNew.rawValue)
                }
            }

            Section(localization.text(.shortcuts)) {
                LabeledContent(localization.text(.toggleQuickBar), value: "⌘⇧V")
            }
        }
        .formStyle(.grouped)
        .frame(width: 560, height: 280)
        .padding()
    }
}
