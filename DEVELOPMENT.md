# PyPaste Development Guide

## Requirements

- macOS 14 or higher.
- Xcode 26 or later.
- Command Line Tools points to the Xcode you are using.
- SwiftLint 0.65 or higher; `swift-format` comes with Xcode.

Install SwiftLint once with Homebrew:

```bash
brew install swiftlint
```

## Open project

Always open `PyPaste.xcworkspace`; do not open the package or child project directly.

```bash
open PyPaste.xcworkspace
```

In Xcode:

1. Choose scheme `PyPaste`.
2. Select destination `My Mac`.
3. Press `Command-R` to run.
4. PyPaste appears on the menu bar with the `Py` icon.
5. Select `Open PyPaste` to open the main window.

## Format, lint and test

```bash
./scripts/format.sh
./scripts/lint.sh
./scripts/test.sh
```

## Signing

The project uses the temporary bundle identifier `com.pypaste.app`, Automatic Signing, and
Hardened Runtime. Because PyPaste uses Accessibility permission to auto-paste, Debug builds
must also be signed with a stable Apple Development identity. Do not use
`Sign to Run Locally`: ad-hoc signature changes after each build and macOS may
retain permission for an old binary even though System Settings still shows PyPaste as enabled.

Set up once in Xcode:

1. Open `Xcode` → `Settings…` → `Accounts` and add an Apple Account.
2. Select the account, click `Manage Certificates…`, create `Apple Development` certificate
   if Xcode hasn't created it itself.
3. In the workspace, select project `PyPaste` → target `PyPaste` →
   `Signing & Capabilities`.
4. Enable `Automatically manage signing` and select your team. A free
   `Personal Team` is sufficient for development.
5. Keep the bundle identifier stable and unique. Do not commit a personal team ID or
   provisioning profile to the repository.

Verify that the newly built app is no longer signed ad hoc:

```bash
security find-identity -v -p codesigning
codesign -d --verbose=4 \
  ~/Library/Developer/Xcode/DerivedData/PyPaste-*/Build/Products/Debug/PyPaste.app
```

The result must contain `Authority=Apple Development` and `TeamIdentifier`, not only
`Signature=adhoc`.

### Fix Accessibility turned on but PyPaste still asks again

1. Press the Stop button in Xcode and exit all PyPaste that are still running.
2. In `Privacy & Security` → `Accessibility`, delete the old PyPaste item with the `–` button.
3. After selecting Team as above, press `Command-R` to run the correct PyPaste.
4. Select a clip to trigger the macOS permission prompt, then enable PyPaste in Accessibility.
5. Quit PyPaste completely and run it again. The system prompt is asynchronous, so
   copy-only fallback behavior on the first attempt is expected.
6. Open a text field, press `Command-Shift-V`, select a clip, and confirm that it is pasted.

An empty entitlements file is correct for this flow. Accessibility is a user-granted TCC
permission, not a capability added to the entitlements file.

Related Apple documents:

- [TN3127 — Inside Code Signing Requirements](https://developer.apple.com/documentation/technotes/tn3127-inside-code-signing-requirements)
- [AXIsProcessTrustedWithOptions](https://developer.apple.com/documentation/applicationservices/1459186-axisprocesstrustedwithoptions)
- [Add an Apple account to Xcode](https://help.apple.com/xcode/mac/current/en.lproj/dev23aab79b4.html)

## Continuous Integration

The `.github/workflows/ci.yml` workflow runs on macOS 26 with Xcode 26.2. CI checks
formatting, SwiftLint, Swift Package tests, and app unit tests. UI smoke tests run
locally through `./scripts/test.sh` because they require an interactive macOS session.
