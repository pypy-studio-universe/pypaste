# PyPaste Progress — Completed Work

> Completed tasks and their Definition-of-Done evidence. See [README.md](./README.md).

## 6. Completed Work

### Project artifacts

| Date | Artifact | Status | Note |
|---|---|---|---|
| 2026-08-09 | `PLAN.md` | DONE | Master plan, backlog, phase gates and quality targets |
| 2026-08-09 | `progress/README.md` | DONE | Progress dashboard and plan drift controls |
| 2026-08-09 | `PyPaste.xcworkspace` | DONE | Workspace with shared scheme PyPaste |
| 2026-08-09 | `Packages/PyPasteKit` | DONE | Local Swift package contains 5 modules |
| 2026-08-09 | `.github/workflows/ci.yml` | DONE | Lint CI, package test and app unit test |

### Completed implementation tasks

| Task | Completion date | Proof | Note |
|---|---|---|---|
| PYP-101 | 2026-08-09 | Debug/Release build and Xcode test pass | App, unit test, UI test targets |
| PYP-102 | 2026-08-09 | Swift Package build/test pass | Core, Data, Domain, Features, SharedUI |
| PYP-103 | 2026-08-09 | FoundationTests pass | AppCoordinator + DependencyContainer |
| PYP-104 | 2026-08-09 | Build/lint pass | OSLog through the AppLogging abstraction |
| PYP-105 | 2026-08-09 | Package test pass | SQLite3 is isolated in Data module |
| PYP-106 | 2026-08-09 | 21 Swift files, 0 lint violation | swift-format + SwiftLint; shortcut deferred per ADR-005 |
| PYP-107 | 2026-08-09 | 3 migration assertions + schema inspection | Version 1 and 2, transaction, idempotency |
| PYP-108 | 2026-08-14 | process audit + anchor unit 1/1 + signed build + 85-file lint | A PyPaste process; anchor menu according to absolute button screen frame and only present once |
| PYP-109 | 2026-08-09 | 2 UI smoke tests pass | Main Window + Settings placeholder scenes |
| PYP-110 | 2026-08-09 | Workflow + local CI command pass | macOS 26/Xcode 26.2 CI quality gate |
| PYP-111 | 2026-08-11 | Debug build + bundle inspection | AppIcon 16–1024 px; valid `AppIcon.icns` and `CFBundleIconName` |
| PYP-112 | 2026-08-14 | Generator + signed build + assetutil/codesign + 85-file lint | Menu bar using lowercase `py` SF Rounded Bold 12 pt, template 18 pt, 1x/2x transparent; AppIcon unchanged |
| PYP-201 | 2026-08-09 | Package compile + adapter smoke | Protocol and `SystemPasteboard` actor |
| PYP-202 | 2026-08-09 | Polling interval + p95 tests | Production interval 350 ms |
| PYP-203 | 2026-08-09 | Pause/sleep lifecycle test |Fresh baseline when resume/wake|
| PYP-204 | 2026-08-09 | App type-check + runtime | NSWorkspace frontmost app tracking |
| PYP-205 | 2026-08-09 | Multi-item + 32 MiB tests | MainActor's processing of all items/types |
| PYP-206 | 2026-08-09 | Content processor tests | Minimum P0 classification; full parser in M3 |
| PYP-207 | 2026-08-09 | Canonical hash tests | SHA-256 64 hex, text normalization |
| PYP-208 | 2026-08-09 | Feedback + race tests | Change-count suppression + internal marker |
| PYP-209 | 2026-08-09 | Repository/migration tests | SQLite v3 keeps item/representation order |
| PYP-210 | 2026-08-09 | App/UI source type-check | Live history + pause/resume controls |
| PYP-211 | 2026-08-09 | Round-trip tests | Reconstruct all items in the correct order |
| PYP-212 | 2026-08-09 | Duplicate/integration tests | Move existing or create new |
| PYP-213 | 2026-08-09 | Unit + real key smoke test | `⌘⇧V` opens the Main Window |
| PYP-214 | 2026-08-10 | 19 package + 1 app + 4 UI tests; 0 lint violation | `⌃⇧V` opens Bottom Quick Bar; click-to-paste has Accessibility fallback |
| PYP-215 | 2026-08-10 | 19 package + 1 app + 4 UI tests; targeted screenshot QA; 0 lint violation | `⌘⇧V`, adaptive UI card and first-click hardening |
| PYP-216 | 2026-08-13 | Full package 82/82; rich-link 4/4 + visual 1/1; signed app build; 70 clean lint files | Liquid glass, rich URL preview, width 80% and self-closing when losing focus |
| PYP-217 | 2026-08-10 | 27 packages + 1 app test; 5 screenshot tests; app build; 48 clean lint files | Track the screenshot destination, identify metadata and save the photo to clipboard/history |
| PYP-218 | 2026-08-11 | 29 packages + targeted app/UI tests; QA screenshot; 48 clean lint files | Six fit viewport cards; arrow goes one item and bypass auto-repeat |
| PYP-220 | 2026-08-12 | 75 package tests, 4 app unit baseline, targeted UI baseline 2/2, signed app/test build, 63 clean lint files + runtime/visual QA | Migration v4, real thumbnail, persistent order, paste location, soft-delete, source-app accent and before/after drag preview |
| PYP-221 | 2026-08-13 | 88/88 package, search 6/6, signed app build, 75-file lint; XCUI runner timeout before test body | Fuzzy search title/content/app/bundle/type in Quick Bar and Main History; FTS5 deferred M3 |
| PYP-222 | 2026-08-13 | collection/migration/model 25/25, full app + test-target build, 82-file lint; XCUI blocked before workflow | Clipboard default tab, centered search, add/create collections, SQLite v5 membership + retention protection |
| PYP-223 | 2026-08-14 | delete model/repository 13/13, full app + UI test target build, 83-file lint; runtime XCUI automation hung after runner exit | Hover `×`, Cancel/Delete alert, cascade membership only, clip/retention preserved, fallback Clipboard |
| PYP-224 | 2026-08-14 | dialog model 5/5, AppKit/Carbon router 2/2, full app + UI test target build, 83-file lint; XCUI timed out before test body | First Esc closes Create/Delete dialog; second closes Quick Bar; no background paste/navigation |
| PYP-225 | 2026-08-14 | dialog model 5/5, AppKit/Carbon router 2/2, full app + UI test target build, 84-file lint | In-panel modal without exit animation; Esc closes the collection dialog in the same update UI |
| PYP-226 | 2026-08-14 | signed app build, 84-file format/lint | Shared search field without border; adaptive background, smooth shadow and focus transition 180 ms |
| PYP-227 | 2026-08-14 | payload 4/4, drag/reorder 23/23, signed build, 85-file lint | Original clip representations dragged to another app; own-process marker keeps internal reordering |
| PYP-228 | 2026-08-14 | localization 4/4, Features 46/46, status selector 1/1, signed build, 89-file lint | Default English; Vietnamese selectable/persistent; live update AppKit + SwiftUI UI |
| PYP-229 | 2026-08-15 | language/structure audits, package tests, signed build, format/lint | English source authoring and Markdown; Vietnamese retained only as localization or locale-specific test data |
| PYP-230 | 2026-08-15 | secure staged-tree audit, universal signed archive, GitHub source push and verified prerelease assets | Split tracker, bilingual user guide, protected public repository and PyPaste 0.1.0 preview release |

---
