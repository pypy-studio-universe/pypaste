# PyPaste Progress — Verification Evidence

> Reproducible build, test, lint, and runtime evidence. See [README.md](./README.md).

## 10. Verification Evidence

Record important build/test/benchmark times. Do not record payload or data clipboard
Whether the sensitivity of the output is saved in this file.

| Date | Task/Milestone | Kind | Command/Method | The outcome |
|---|---|---|---|---|
| 2026-08-15 | PYP-230 | Public staged-tree security audit | `.gitignore`, staged filename scan, secret/personal-identifier pattern scan, `git diff --cached --check` | PASS — no credential, personal Team ID, local Xcode state, cache, or generated binary staged |
| 2026-08-15 | PYP-230 | Universal release archive | Release `xcodebuild archive`, `lipo`, bundle version inspection | PASS — PyPaste 0.1.0 build 1; `x86_64 arm64` |
| 2026-08-15 | PYP-230 | Release signature | strict `codesign --verify` outside the Keychain sandbox | PASS — valid on disk and satisfies its Designated Requirement |
| 2026-08-15 | PYP-230 | Package regression | isolated SwiftPM scratch/cache | PARTIAL — 101/105 pass; three Carbon hotkey and one named-pasteboard resource conflicts match the existing environment baseline |
| 2026-08-15 | PYP-230 | Format/lint | `./scripts/format.sh --lint`, `./scripts/lint.sh` | PASS — 89 Swift files, 0 violations |
| 2026-08-15 | PYP-230 | Source publication | initial commit and `git push -u origin main` | PASS — `main` tracks `origin/main` |
| 2026-08-15 | PYP-230 | GitHub prerelease | `gh release create` followed by release metadata and asset verification | PASS — `v0.1.0` prerelease contains the universal ZIP and checksum; uploaded digest matches the local SHA-256 |
| 2026-08-15 | DEV-037 | Donation documentation | source/copy image comparison, PNG inspection, Markdown link review | PASS — 711×786 PNG preserved; PayPal HTTPS URL and repository-relative MoMo asset are present |

| Date | Task/Milestone | Kind | Command/Method | The outcome |
|---|---|---|---|---|
| 2026-08-09 | M1 | Format/lint | `./scripts/format.sh` + `./scripts/lint.sh` | PASS — 21 Swift files, 0 violations |
| 2026-08-09 | PYP-107 | Package tests | `swift test --package-path Packages/PyPasteKit` | PASS — 2/2 tests |
| 2026-08-09 | M1 | Xcode tests | `xcodebuild test -workspace PyPaste.xcworkspace -scheme PyPaste -destination 'platform=macOS'` | PASS — 3/3 tests |
| 2026-08-09 | PYP-108/109 | UI interaction | XCUI click `PyPaste menu` → `Open PyPaste` | PASS — Main Window appears |
| 2026-08-09 | M1 | Debug build | Clean DerivedData `xcodebuild build` | PASS |
| 2026-08-09 | M1 | Release build | `xcodebuild build -configuration Release` | PASS |
| 2026-08-09 | PYP-107 | Runtime database | Query app database after UI test | PASS — `user_version=2`, both tables present |
| 2026-08-09 | PYP-110 | CI simulation | YAML parse + exact unsigned Xcode test command | PASS — valid workflow, unit test pass |
| 2026-08-09 | M2/PYP-213 | Format | direct `swift-format format/lint --strict` | PASS — 37 Swift files |
| 2026-08-09 | M2/PYP-213 | Package XCTest | build with Swift toolchain + run XCTest Agent | PASS — 14/14 tests |
| 2026-08-09 | PYP-202 | Performance | 25 captures with polling production 350 ms | PASS — p95 < 750 ms |
| 2026-08-09 | PYP-205 | Responsiveness | Hash/persist payload fake image 32 MiB | PASS — MainActor heartbeat < 250 ms |
| 2026-08-09 | PYP-209 | Runtime database | App smoke + SQLite query | PASS — `user_version=3`, enough 2 sheets |
| 2026-08-09 | PYP-212 | Runtime capture | Named pasteboard → app → SQLite | PASS — dedup and correct item order |
| 2026-08-09 | PYP-213 | Global hotkey | Real registration + post `⌘⇧V` + CGWindow query | PASS — from 0 to 1 Main Window |
| 2026-08-09 | M2/PYP-213 | App compile/link | Swift 6 type-check + direct executable link | PASS |
| 2026-08-09 | ENV-001 | Standard Xcode/SwiftLint | `xcodebuild` / `swiftlint` | BLOCKED — Xcode license has not accepted yet |
| 2026-08-10 | ENV-001 | Xcode environment | `xcrun --sdk macosx --show-sdk-path` | RESOLVED — license accepted |
| 2026-08-10 | PYP-214 | Format/lint | `./scripts/lint.sh` | PASS — 42 Swift files, 0 violations |
| 2026-08-10 | PYP-214 | Package XCTest | `swift test` through `./scripts/test.sh` | PASS — 19/19 tests |
| 2026-08-10 | PYP-214 | Xcode unit/UI tests | `xcodebuild test` through `./scripts/test.sh` | PASS — 1/1 app unit + 4/4 UI tests |
| 2026-08-10 | PYP-214 | App target build | clean DerivedData `xcodebuild build` | PASS — Swift 6 app and QuickBar panel link successfully |
| 2026-08-10 | PYP-214 | Quick Bar accessibility/UI | XCUI `⌃⇧V` + click card + hierarchy inspection | PASS — bottom dialog 1320×218; click the clipboard recording card |
| 2026-08-10 | PYP-214 | Paste permission branches | injected `SystemPasteCoordinatorTests` | PASS — trusted paste, denied fallback and missing target |
| 2026-08-10 | PYP-215 | Format/lint | `./scripts/format.sh` + `./scripts/lint.sh` | PASS — 42 Swift files, 0 violations |
| 2026-08-10 | PYP-215 | Package + Xcode regression | `./scripts/test.sh` | PASS — 19/19 package, 1/1 app unit, 4/4 UI tests |
| 2026-08-10 | PYP-215 | Hotkey/UI interaction | XCUI `⌘⇧V`, label assertions, click and pasteboard `changeCount` | PASS — selected clip recorded |
| 2026-08-10 | PYP-215 | Visual QA | `XCUIScreen` attachment + `xcresulttool` + image inspection | PASS — bottom panel 1320×238, adaptive material and colored-header card |
| 2026-08-10 | PYP-216 | Format/lint | `./scripts/format.sh` + `./scripts/lint.sh` | PASS — 45 Swift files, 0 violations |
| 2026-08-10 | PYP-216 | Smart detection unit tests | `SmartContentDetectionTests` | PASS — HEX 3/4/6/8 digits, invalid input and HTTP(S) URL offline preview |
| 2026-08-10 | PYP-216 | Package + Xcode regression | `./scripts/test.sh` | PASS — 22/22 package, 1/1 app unit, 5/5 UI tests |
| 2026-08-10 | PYP-216 | Click + keyboard UI | XCUI click, `→`, `Return`, `Esc` and named pasteboard assertion | PASS — the selected color is recorded correctly and the panel closes |
| 2026-08-10 | PYP-216 | Visual QA | `XCUIScreen` attachment + `xcresulttool export attachments` + image inspection | PASS — monochrome liquid glass, URL/HEX preview and source app footer |
| 2026-08-10 | PYP-217 | Format/lint | `./scripts/format.sh` + `./scripts/lint.sh` | PASS — 48 Swift files, 0 violations |
| 2026-08-10 | PYP-217 | Screenshot integration | `ScreenshotClipboardTests` | PASS — 5/5: directory event, baseline/filter, localized metadata, service and marker-free writer |
| 2026-08-10 | PYP-217 | Package regression | `swift test --package-path Packages/PyPasteKit` | PASS — 27/27 tests; p95 still below 750 ms |
| 2026-08-10 | PYP-217 | App build/unit | `xcodebuild test` | PASS — compile/link app and FoundationTests 1/1 |
| 2026-08-10 | ENV-002 | UI regression rerun | `xcodebuild test` / `test-without-building` | INFRA BLOCKED — XCTest timeout when automation mode is enabled before the test; PYP-216 baseline 5/5 is still the last UI pass |
| 2026-08-11 | PYP-111 | AppIcon asset validation | Debug `xcodebuild build` + bundle inspection | PASS — 10 macOS slots compile into `AppIcon.icns`; Info.plist has `CFBundleIconName = AppIcon` |
| 2026-08-11 | PYP-112 | Menu bar icon validation | `./scripts/lint.sh`, Debug `xcodebuild build` + `assetutil` | PASS — 48 clean Swift files; `MenuBarIcon` 18/36 px, transparent and template mode |
| 2026-08-11 | PYP-218 | Quick Bar regression + visual QA | Swift/Xcode tests, seven-item XCUI frame assertions + screenshot | PASS — 29/29 package, targeted app/UI pass; six cards fully inside popup; one arrow selects item 2 |
| 2026-08-11 | PYP-219 | Signing/TCC diagnosis | `security find-identity`, `codesign -dvvv`, process/launch-service audit | CONFIRMED — 0 valid identities; ad-hoc/no TeamIdentifier; change CDHash `9052…` → `12e8…` with DerivedData path after rebuild |
| 2026-08-11 | PYP-219 | Code regression | format/lint + package tests + isolated app unit/UI tests | PASS — 48 Swift files/0 violations; 30/30 package; 4/4 app unit; 1/1 targeted UI; no more hosted PyPaste after test |
| 2026-08-12 | PYP-219 | Stable signing verification | `security find-identity`, strict `codesign --verify`, designated requirement inspection | PASS — Valid Apple Development identity and TeamIdentifier; Apple Root/WWDR chain; artifact valid on disk |
| 2026-08-12 | PYP-220 | Format/lint | `./scripts/format.sh` + `./scripts/lint.sh` | PASS — 56 Swift files, 0 violations |
| 2026-08-12 | PYP-220 | Package regression | isolated `swift test --disable-sandbox` | PASS — 47/47 tests; thumbnail, models, SQLite v4, screenshot and clipboard core |
| 2026-08-12 | PYP-220 | SQLite/order regression | migration/repository XCTest | PASS — v3→v4, persistent/hidden order, `recordUse`, soft-delete and exact representations |
| 2026-08-12 | PYP-220 | App build/unit | signed Xcode build + FoundationTests | PASS — Swift 6 build/sign; 4/4 app unit tests |
| 2026-08-12 | PYP-220 | Targeted UI baseline | paste-order + delete/reopen XCUI | PASS — 2/2 before sequencing hardening; delete paste-free and order unchanged |
| 2026-08-12 | PYP-220 | Runtime smoke on final build | PNG pasteboard test + CGEvent drag/delete + SQLite/pasteboard inspection | PASS — real thumbnail; `sort_rank` change 2→1; soft-delete `is_deleted=1`; `changeCount` keep 192 |
| 2026-08-12 | PYP-220 | Final targeted XCUI rerun | fresh DerivedData + reset `testmanagerd` | INFRA BLOCKED — macOS waits for private `PyPasteUITests-Runner` approval before `app.launch()`; build/sign pass, no test assertion fail |
| 2026-08-12 | PYP-220 | Preview bounds correction | unsigned Xcode build, 47 package tests, 56-file lint + cropped Quick Bar screenshot | PASS — 162 pt card divided 35/99/28; panorama only renders in content slot, header/footer not covered |
| 2026-08-12 | PYP-220 | Drag-preview state + full regression | Isolated SwiftPM tests outside sandbox | PASS — 8/8 drag-session + 1/1 pixel-render overlay; 75/75 full package including Carbon hotkey and real named pasteboard |
| 2026-08-12 | PYP-220 | Drag-preview build/lint | signed Xcode app/test `build-for-testing` + `./scripts/lint.sh` | PASS — Apple Development signing; Swift 6 compile/link; 63 files, 0 violation |
| 2026-08-12 | PYP-220 | Drag-preview visual QA | production overlay pixel-render + manual card render at before/after edge | PASS — rail/glow leading/trailing correctly, clear target highlight and no reflow layout |
| 2026-08-12 | PYP-220 | Targeted drag/reopen XCUI | `xcodebuild test` fresh DerivedData | INFRA BLOCKED — runner timeout when enabling automation mode before test body; build/sign pass, no assertion fail |
| 2026-08-12 | ENV-004 | XCUI automation worker | targeted drag/reopen runner | ACTIVE — only blocks rerun automation; exact three-card test compiled and package/render regressions pass |
| 2026-08-13 | PYP-220 | Drag source runtime correction | real signed app + named pasteboard + CGEvent mouse drag + SQLite inspection | PASS — pull oldest before newest; persisted order is correct `oldest → newest → middle` with rank `3 → 2 → 1` |
| 2026-08-13 | PYP-220 | Final drag regression | full SwiftPM + format/lint | PASS — 75/75 tests; 8 drag-session, pixel-render overlay, repository persistence; 63 Swift files, 0 violation |
| 2026-08-13 | ENV-004 | Targeted XCUI rerun | fresh signed runner | INFRA BLOCKED — runner still hangs before body test; stopped cleanly, replaced with real CGEvent/SQLite smoke test |
| 2026-08-13 | PYP-220 | Drag target visibility | pixel-render overlay + signed Xcode build + format/lint | PASS — fill 20%, border 95%/3 pt, glow 85%; center brightness assertion pass; 63 files, 0 violation |
| 2026-08-13 | PYP-216 | Keyboard-focus unit regression | targeted signed `xcodebuild test` | PASS — 2/2: activating panel claim key focus and arrow repeat still only go one item |
| 2026-08-13 | PYP-216 | Status-menu keyboard end-to-end | targeted XCUI: menu bar → Quick Bar → `→` → `Return` → `Esc` | PASS — 1/1; select the correct next item, write the correct named pasteboard and close the popup without clicking first |
| 2026-08-13 | PYP-216 | Keyboard-focus format/lint | `./scripts/format.sh` + `./scripts/lint.sh` | PASS — 63 Swift files, 0 violations |
| 2026-08-13 | PYP-216 | Pinned-popup unit regression | targeted signed `xcodebuild test` | PASS — 4/4: activating/persistent panel, paste focus restore, Return without dismissing, Esc dismiss and arrow repeat |
| 2026-08-13 | PYP-216 | Pinned-popup end-to-end | status menu → `→` → `Return` → pop-up still exists → `→` → `Esc` | PASS — 1/1; keyboard continues to work after paste and Esc closes the popup |
| 2026-08-13 | PYP-216 | Pinned-popup close button | status menu → Quick Bar → click `Close Quick Bar` (`×`) | PASS — 1/1; × button closes popup |
| 2026-08-13 | PYP-216 | Pinned-popup format/lint | `./scripts/format.sh` + `./scripts/lint.sh` | PASS — 63 Swift files, 0 violations |
| 2026-08-13 | PYP-216 | Final signed app build | Incremental `xcodebuild build` after clean-code rename `showQuickBar` and paste grace period 120 ms | PASS — Swift 6 compile/link, Apple Development codesign and bundle validation |
| 2026-08-13 | PYP-216 | Global command monitor | targeted `QuickBarKeyboardMonitorTests` | PASS — 2/2; register/unregister with four commands, valid route ID and ignore strange ID |
| 2026-08-13 | PYP-216 | External-focus + width regression | targeted signed `xcodebuild test` | PASS — 5/5; width is 80%, lifecycle monitor, Return/Esc and arrow repeat |
| 2026-08-13 | PYP-216 | External-app pinned popup XCUI (superseded by DEV-020) | status menu → Quick Bar → activate Finder | HISTORICAL PASS — 1/1; behavior of pop-up retention after deactivation has been replaced |
| 2026-08-13 | PYP-216 | External-focus correction format/lint | `./scripts/format.sh` + `./scripts/lint.sh` | PASS — 66 Swift files, 0 violations |
| 2026-08-13 | PYP-216 | External-focus correction final build | signed `xcodebuild build` with fresh DerivedData | PASS — Swift 6 compile/link, Apple Development codesign and bundle validation |
| 2026-08-13 | PYP-216 | Full package regression | `swift test --package-path Packages/PyPasteKit` | PASS — 77/77 tests, 0 failures in 9.45 s |
| 2026-08-13 | PYP-216 | Blur-dismiss unit regression | targeted signed `xcodebuild test` | PASS — 3/3; dismiss-on-deactivate, cleanup hotkey and width 80% |
| 2026-08-13 | PYP-216 | Blur-dismiss XCUI | status menu → Quick Bar → activate Finder | PASS — 1/1; popup disappears when Finder foreground |
| 2026-08-13 | PYP-216 | Blur-dismiss format/lint | `./scripts/format.sh` + `./scripts/lint.sh` | PASS — 66 Swift files, 0 violations |
| 2026-08-13 | PYP-216 | Rich-link provider regression | `swift test --filter RichLinkMetadataProviderTests` | PASS — 4/4; success/failure cache, concurrent coalescing and bounded eviction |
| 2026-08-13 | PYP-216 | Rich-link bounded visual render | `swift test --filter RichWebLinkPreviewContentTests` | PASS — 1/1; image and caption separate the area in the frame 216×99, no overflow |
| 2026-08-13 | PYP-216 | Full rich-link regression | `swift test --package-path Packages/PyPasteKit` | PASS — 82/82 tests, 0 failures in 9.55 s |
| 2026-08-13 | PYP-216 | Rich-link signed app build | `xcodebuild build` with Apple Development | PASS — Swift 6 compile/link; outbound network entitlement bundled and codesigned |
| 2026-08-13 | PYP-216 | Rich-link format/lint | `./scripts/lint.sh` | PASS — 70 Swift files, 0 violations |
| 2026-08-13 | PYP-221 | Fuzzy matcher regression | `ClipSearchEngineTests` | PASS — 4/4; title/content/app/bundle/type, Vietnamese folding, typo and relevance |
| 2026-08-13 | PYP-221 | Search model integration | `QuickBarModelTests` + `MainHistoryModelTests` | PASS — 2 search cases; selection/canonical order/live update kept correct |
| 2026-08-13 | PYP-221 | Full package regression | `swift test --package-path Packages/PyPasteKit` | PASS — 88/88 tests, 0 failures in 9.52 s |
| 2026-08-13 | PYP-221 | Signed app build | `xcodebuild build` fresh DerivedData + incremental verify | PASS — Swift 6 compile/link and Apple Development signing |
| 2026-08-13 | PYP-221 | Format/lint | `./scripts/format.sh` + `./scripts/lint.sh` | PASS — 75 Swift files, 0 violations |
| 2026-08-13 | PYP-221/ENV-005 | Quick Bar search XCUI | capture 2 clips → type query → clear | INFRA BLOCKED — app/test build/sign pass; runner timeout enabling automation before test body, no assertion fail |
| 2026-08-13 | PYP-222 | Collection persistence regression | targeted `SQLite*`, `QuickBarCollectionModelTests`, `QuickBarModelTests` | PASS — 25/25; migration v5, restart persistence, membership, retention, explicit delete and Clipboard-default state |
| 2026-08-13 | PYP-222 | App + test-target compile | `xcodebuild build-for-testing`, fresh DerivedData | PASS — app, unit tests and UI tests compile; `QuickBarCollectionUITests` lies exactly in the UI target |
| 2026-08-13 | PYP-222 | Format/lint | `./scripts/format.sh` + `./scripts/lint.sh` | PASS — 82 Swift files, 0 violations |
| 2026-08-13 | PYP-222/ENV-006 | Collection workflow XCUI | centered search → add Useful Links → reopen → Clipboard default | INFRA BLOCKED before workflow — runner does not see the app window because an old PyPaste is running with the bundle ID; there is no collection assertion failure |
| 2026-08-14 | PYP-223 | Collection deletion regression | `QuickBarCollectionModelTests`, `SQLiteClipRepositoryTests`, `SQLiteClipCollectionDeletionTests` | PASS — 13/13; request/apply state, cascade membership, clip + sticky retention preserved |
| 2026-08-14 | PYP-223 | App + test-target compile | fresh DerivedData `xcodebuild build-for-testing` | PASS — compile app, unit and UI test targets |
| 2026-08-14 | PYP-223 | Format/lint | `./scripts/format.sh` + `./scripts/lint.sh` | PASS — 83 Swift files, 0 violations |
| 2026-08-14 | PYP-223/ENV-007 | Hover/confirm/delete XCUI | hover Useful Links → Cancel → hover → Delete | INFRA BLOCKED — runner exited but xcodebuild hung when finalized; stopped the test process correctly, there was no valid xcresult to declare pass |
| 2026-08-14 | PYP-224 | Collection dialog model | `QuickBarCollectionModelTests` | PASS — 5/5; mutually-exclusive Create/Delete state, top-modal dismiss and presentation reset |
| 2026-08-14 | PYP-224 | Local/global Escape router | targeted `FoundationTests` | PASS — 2/2; first Esc dismiss dialog, second Esc dismiss Quick Bar, Return/global paste blocked behind modal |
| 2026-08-14 | PYP-224 | App + UI test-target compile | fresh DerivedData `xcodebuild build-for-testing` | PASS — app, unit and UI targets compile |
| 2026-08-14 | PYP-224 | Format/lint | `./scripts/format.sh` + `./scripts/lint.sh` | PASS — 83 Swift files, 0 violations |
| 2026-08-14 | PYP-224/ENV-007 | Two-stage Esc XCUI | Create → Esc×2; Delete → Esc×2 | INFRA BLOCKED before body test — UI runner timed out while enabling automation mode; 0 UI assertions executed |
| 2026-08-14 | PYP-225 | Immediate dialog model | `QuickBarCollectionModelTests` | PASS — 5/5; create/delete state clear synchronously and mutually exclusive |
| 2026-08-14 | PYP-225 | Local/global Escape router | targeted `FoundationTests` | PASS — 2/2 in 0.004 s; first Esc clear modal right away, Quick Bar still open |
| 2026-08-14 | PYP-225 | App + UI test-target compile | fresh DerivedData `xcodebuild build-for-testing` | PASS — app, unit and UI targets compile with custom modal overlay |
| 2026-08-14 | PYP-225 | Format/lint | `./scripts/format.sh` + `./scripts/lint.sh` | PASS — 84 Swift files, 0 violations |
| 2026-08-14 | PYP-225/ENV-007 | Immediate dialog XCUI | Create/Delete → Esc×2 | INFRA BLOCKED before body test — xcodebuild exit 0 but xcresult `unknown`, totalTestCount 0; no functional assertion failure |
| 2026-08-14 | PYP-226 | Signed app build | fresh DerivedData `xcodebuild build` | PASS — Quick Bar and Main History compile/link with shared search style |
| 2026-08-14 | PYP-226 | Format/lint | `./scripts/format.sh` + `./scripts/lint.sh` | PASS — 84 Swift files, 0 violations |
| 2026-08-14 | PYP-226/DEV-028 | Borderless search build | fresh DerivedData signed `xcodebuild build` | PASS — adaptive background + smooth shadow compile/link in Quick Bar and History |
| 2026-08-14 | PYP-226/DEV-028 | Format/lint | `./scripts/format.sh` + `./scripts/lint.sh` | PASS — 84 Swift files, 0 violations |
| 2026-08-14 | PYP-227 | External drag payload | `QuickBarDragPayloadTests` | PASS — 4/4; original text/HTML/image bytes, URL fallback and first-item type priority |
| 2026-08-14 | PYP-227 | Drag/reorder regression | payload + session + overlay + model tests | PASS — 23/23, internal reorder/preview unchanged |
| 2026-08-14 | PYP-227 | Full package regression | isolated `swift test` | PARTIAL — 97/101 pass; 4 system-resource tests fail due to Carbon hotkey/named pasteboard being held by another process, no external-drag failure |
| 2026-08-14 | PYP-227 | Signed app build | fresh DerivedData `xcodebuild build` | PASS — compile/link app successfully |
| 2026-08-14 | PYP-227 | Format/lint | `./scripts/format.sh` + `./scripts/lint.sh` | PASS — 85 Swift files, 0 violations |
| 2026-08-14 | PYP-112/DEV-030 | Menu bar asset generation | vector generator + `sips` inspection | PASS — transparent RGBA 18×18 and 36×36, deterministic heavy `Py` glyph |
| 2026-08-14 | PYP-112/DEV-030 | Signed app + compiled asset | fresh DerivedData build, `assetutil`, strict `codesign` | PASS — both scales in Assets.car, Template Mode=template; app satisfies DR |
| 2026-08-14 | PYP-112/DEV-030 | Format/lint | `./scripts/format.sh` + `./scripts/lint.sh` | PASS — 85 Swift files, 0 violations |
| 2026-08-14 | PYP-112/DEV-031 | Lowercase menu asset | generator + `sips` + standalone strict format | PASS — centered `py`, transparent RGBA 18×18/36×36; generator clean |
| 2026-08-14 | PYP-112/DEV-031 | Signed app + compiled asset | fresh DerivedData build, `assetutil`, strict `codesign` | PASS — both scales template mode; app satisfies DR; AppIcon untouched |
| 2026-08-14 | PYP-112/DEV-031 | Format/lint | `./scripts/format.sh` + `./scripts/lint.sh` | PASS — 85 Swift files, 0 violations |
| 2026-08-14 | PYP-108/DEV-032 | Status menu anchor | targeted `FoundationTests` | PASS — 1/1 in 0.002 s; anchor right current button bottom-leading |
| 2026-08-14 | PYP-108/DEV-032 | Signed app build | fresh DerivedData `xcodebuild build` | PASS — explicit menu presentation compile/link successful |
| 2026-08-14 | PYP-108/DEV-032 | Format/lint | `./scripts/format.sh` + `./scripts/lint.sh` | PASS — 85 Swift files, 0 violations |
| 2026-08-14 | PYP-108/DEV-033 | Runtime process audit | `pgrep` + LaunchServices registration | PASS — is a PyPaste process and an application registration; not duplicate app |
| 2026-08-14 | PYP-108/DEV-033 | Absolute screen anchor | targeted `FoundationTests` | PASS — 1/1 in 0.005 s; anchor right bottom-leading of the button screen frame |
| 2026-08-14 | PYP-108/DEV-033 | Signed app build | fresh DerivedData `xcodebuild build` | PASS — screen-coordinate popup and reentrancy guard compile/link successfully |
| 2026-08-14 | PYP-108/DEV-033 | Format/lint | `./scripts/format.sh` + `./scripts/lint.sh` | PASS — 85 Swift files, 0 violations |
| 2026-08-14 | PYP-228 | Localization unit | `AppLocalizationTests` | PASS — 4/4; English default, Vietnamese selection, formatting and restart persistence |
| 2026-08-14 | PYP-228 | Features regression | isolated `swift test --filter PyPasteFeaturesTests` | PASS — 46/46; search, collections, drag, previews and regressions models |
| 2026-08-14 | PYP-228 | Status selector integration | targeted `FoundationTests` | PASS — 1/1 in 0.022 s; English/Vietnamese rows, checkmark and persisted `vi` |
| 2026-08-14 | PYP-228 | Full package regression | isolated `swift test` | PARTIAL — 101/105 pass; 4 system-resource tests fail because Carbon hotkey/named pasteboard was held by another process, there was no localization failure |
| 2026-08-14 | PYP-228 | Signed app build | fresh DerivedData `xcodebuild build` | PASS — Apple Development app compile/link/sign successfully |
| 2026-08-14 | PYP-228 | Format/lint | `./scripts/format.sh` + `./scripts/lint.sh` | PASS — 89 Swift files, 0 violations |
| 2026-08-15 | PYP-229 | Markdown language + structure audit | language recognizer, regex counts, backup comparison | PASS — 0 Vietnamese documentation lines; line, heading, checkbox, fence, table, link, task/ADR/DEV marker counts preserved |
| 2026-08-15 | PYP-229 | Source-language audit | Swift file scan + language recognizer | PASS — source authoring is English; Vietnamese remains only in localization data and locale-specific fixtures |
| 2026-08-15 | PYP-229 | Package regression | isolated `/tmp` SwiftPM caches and scratch | PARTIAL — 101/105 pass; 3 Carbon hotkey and 1 named-pasteboard resource conflicts, no language/documentation failure |
| 2026-08-15 | PYP-229 | Signed app build | fresh `/tmp/PyPastePYP229DerivedData` `xcodebuild build` | PASS — compile, link, Apple Development signing, validation, and LaunchServices registration succeeded |
| 2026-08-15 | PYP-229 | Format/lint | `./scripts/format.sh` + `./scripts/lint.sh` | PASS — 89 Swift files, 0 violations |

---
