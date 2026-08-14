import PyPasteSharedUI
import SwiftUI

struct ClipboardSearchField: View {
    @Binding var text: String
    let width: CGFloat
    let accessibilityIdentifier: String
    @Bindable var localization: AppLocalization
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isFocused: Bool
    @State private var draftText = ""

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(isFocused ? Color.accentColor : Color.secondary)

            TextField(localization.text(.searchPlaceholder), text: $draftText)
                .textFieldStyle(.plain)
                .focused($isFocused)
                .accessibilityIdentifier(accessibilityIdentifier)

            if !draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button {
                    draftText = ""
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help(localization.text(.clearSearch))
                .accessibilityLabel(localization.text(.clearClipboardSearch))
            }
        }
        .font(.caption)
        .padding(.horizontal, 10)
        .frame(width: width, height: 30)
        .background(searchFieldFill, in: searchFieldShape)
        .shadow(
            color: shadowColor,
            radius: isFocused ? 14 : 10,
            y: isFocused ? 5 : 4
        )
        .animation(.easeInOut(duration: 0.18), value: isFocused)
        .onAppear {
            draftText = text
        }
        .onChange(of: text) { _, newValue in
            guard newValue != draftText else {
                return
            }

            draftText = newValue
        }
        .task(id: draftText) {
            do {
                try await Task.sleep(for: .milliseconds(120))
            } catch {
                return
            }

            guard !Task.isCancelled, text != draftText else {
                return
            }

            text = draftText
        }
    }

    private var searchFieldShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 9, style: .continuous)
    }

    private var searchFieldFill: Color {
        if colorScheme == .dark {
            return Color.white.opacity(isFocused ? 0.15 : 0.10)
        }

        return Color.white.opacity(isFocused ? 0.98 : 0.90)
    }

    private var shadowColor: Color {
        colorScheme == .dark
            ? Color.black.opacity(isFocused ? 0.38 : 0.30)
            : Color.black.opacity(isFocused ? 0.20 : 0.14)
    }
}
