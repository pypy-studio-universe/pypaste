# PyPaste

PyPaste is a native, local-first clipboard manager for macOS 14 or later. It provides a
keyboard-driven Quick Bar, fuzzy search, persistent collections, image and link previews,
screenshot capture, drag and drop, and English/Vietnamese runtime localization.

## Highlights

- Open the bottom Quick Bar with `⌘⇧V`.
- Navigate with `←` / `→`, paste with `Return`, and close with `Esc`.
- Capture text, links, HEX colors, images, PDFs, files, and multi-item clipboard payloads.
- Search by title, content, source app, bundle identifier, and content type.
- Keep important clips in persistent collections.
- Preview screenshots, images, colors, and HTTP(S) links.
- Reorder cards or drag their original content into another macOS application.
- Keep clipboard history on the local Mac.

## Installation and usage

Read the [Vietnamese-first, English-second user guide](./docs/USER_GUIDE.md) for installation,
required permissions, features, keyboard controls, and troubleshooting.

Development preview downloads are published on
[GitHub Releases](https://github.com/pypy-studio-universe/pypaste/releases).

## Development

Open `PyPaste.xcworkspace` in Xcode. Select your own development team for the PyPaste app and
test targets; the repository intentionally does not commit a personal Team ID.

```sh
./scripts/format.sh
./scripts/lint.sh
xcodebuild -workspace PyPaste.xcworkspace -scheme PyPaste -destination 'platform=macOS' build
```

The product and engineering roadmap is in [PLAN.md](./PLAN.md). Start development sessions at
the [progress tracker index](./progress/README.md).

## Privacy and security

Clipboard history is stored locally. Network access is used only for bounded HTTP(S) rich-link
previews. Build products, credentials, local Xcode state, and personal signing identifiers are
excluded from source control.

## Status

Version 0.1.0 is a development preview. It is not yet a notarized production distribution.
