# PyPaste Progress — Session Log

> Chronological development handoff log. See [README.md](./README.md).

## 11. Session Log

### 2026-08-09 — Planning setup

- Created `PLAN.md` as a master plan.
- The progress tracker has been created as an operational record.
- No Xcode project or source code has been created yet.
- No blocker.
- Plan alignment: `ON PLAN`.
- Next action: start `PYP-001`.

### 2026-08-09 — Epic 1 Project Foundation

- Started with: direct request to deploy Epic 1.
- Completed: PYP-101 to PYP-110 and all M1 Phase Gate.
- In progress: none.
- Verification: format/lint, Debug/Release build, 2 package tests, 1 app unit
  Both the test and the 2 UI tests passed.
- Decisions: SQLite3 native for foundation; KeyboardShortcuts moved to PYP-504.
- Blockers: none.
- Plan alignment: ON PLAN via DEV-001, ADR-003 and ADR-005.
- Next action: return to PYP-001 to complete Product Definition.

### 2026-08-09 — Epic 2 Clipboard Capture Engine + Command-Shift-V

- Started with: request to deploy Epic 2, then add `⌘⇧V` to open clipboard manager.
- Completed: PYP-201 to PYP-213 and all M2 Phase Gate.
- In progress: none.
- Verification: 14/14 package tests; Swift 6 app/UI test type-check; direct app
  link; runtime database v3; named-pasteboard capture/dedup/order; real global
  hotkey opens Main Window.
- Decisions: a snapshot clipboard is an ordered multi-item Clip; native fixed
  hotkey adapter in development; recorder and auto-paste are still in M5/M6.
- Blockers: source code does not exist; ENV-001 requires users to accept the Xcode license.
- Plan alignment: ON PLAN via DEV-002/003 and ADR-006/007.
- Next action: return to PYP-001 to complete Product Definition.

### 2026-08-10 — Bottom Quick Bar + Control-Shift-V click-to-paste

- Started with: ask `⌃⇧V` to display clipboard cards at the bottom of the screen and click
  Item to paste into the previous application.
- Completed: PYP-214 and all M2 Phase Gate; fixed shortcut, non-activating
  `NSPanel`, horizontal cards, target preservation, paste coordinator, permission
  prompt, copy-only fallback and menu/settings label.
- In progress: none.
- Verification: 19/19 package tests, 1/1 app unit test, 4/4 UI tests, full app
  build and 42 Swift files/0 lint violations are passed.
- Decisions: separate Panel/ViewModel/PasteCoordinator/clipboard writer according to ADR-008;
  Accessibility is only a capability for auto-paste, not a copy function.
- Blockers: none; ENV-001 has been resolved.
- Plan alignment: ON PLAN via DEV-004 and ADR-008.
- Next action: PYP-001.

### 2026-08-10 — Command-Shift-V + reference-aligned Quick Bar

- Started with: correction to `⌘⇧V` and two new bottom UI picker photos.
- Completed: PYP-215; updated Carbon adapter/menu/settings, system-adaptive
  panel, Clipboard History header, color header card/neutral content and XCUI screenshot.
- In progress: none.
- Verification: 19/19 package tests, 1/1 app unit, 4/4 UI tests and lint 42
  File is all passed. Targeted screenshot/click test pass after QA round.
- Iteration: QA detected the test using the old card coordinates during the live-update list;
  assertion is changed to pasteboard `changeCount`, and at the same time, the receiving view hosting
  The first mouse to click the beginning still works when the panel loses key focus.
- Decisions: only show the real Clipboard History; collection/template waiting for M4/M5 domain.
- Blockers: none.
- Plan alignment: ON PLAN via DEV-005 and ADR-009.
- Next action: PYP-001.

### 2026-08-10 — Liquid glass, smart previews and keyboard navigation

- Started with: request liquid glass black-white interface, HEX swatch, source app,
  URL preview, left/right navigation and Esc close popup.
- Completed: PYP-216; add `HexColor`, `WebLinkPreview`, smart classification,
  monochrome UI card, selection state in `QuickBarModel` and key routing in panel.
- In progress: none.
- Verification: 22/22 package tests, 1/1 app unit, 5/5 UI tests and lint 45
  file/0 violations are passed; screenshot is exported and visually checked.
- Iteration: test to find out the click loss when SwiftUI Button/glass/hover competes with hit
  testing and key routing lose the first responder. The card is merged into a tap action,
  The side effect test is isolated, the panel receives first responder and local key monitor.
- Decisions: preview link only parses offline; only valid HEX colors are allowed;
  selection belongs to the model, AppKit only transfers input.
- Blockers: none.
- Plan alignment: ON PLAN via DEV-006 and ADR-010.
- Next action: PYP-001.

### 2026-08-10 — Screenshot automatically into clipboard/history

- Started with: screenshot requests must also be saved to the clipboard.
- Completed: PYP-217; add system screenshot location resolver, directory event
  monitor, metadata/file-name recognizer, retrying pasteboard writer and lifecycle wiring.
- In progress: none.
- Verification: 27/27 package tests; screenshot 5/5; app compile/link and
  FoundationTests 1/1; SwiftFormat/SwiftLint 48 file, 0 violation.
- Iteration: fix Swift 6 POSIX typing/concurrency in test, standardize alias
  `/var`/`/private/var`, then add DispatchSource test to automatically detect new files.
- Decisions: do not intercept shortcut and do not use ScreenCaptureKit; follow
  local-only file according to ADR-011. Pause/resume simultaneously clipboard/screenshot.
- Blockers: ENV-002 — XCTest helper timeout when enabling automation mode before
  Run the test; the latest UI baseline PYP-216 is still 5/5 pass and this change does not fix the UI.
- Plan alignment: ON PLAN via DEV-007 and ADR-011.
- Next action: PYP-001; rerun XCUI after relaunching the test automation environment.

### 2026-08-11 — Monogram Py makes macOS AppIcon

- Started with: request to use the logo `Py` selected as the logo for the PyPaste app.
- Completed: PYP-111; save source brand, create `AppIcon.appiconset` with 10 slots and
  Debug/Release configuration using asset `AppIcon`.
- In progress: none.
- Verification: all PNGs are correct 16/32/64/128/256/512/1024 px; Debug build pass;
  bundle sinh `AppIcon.icns`, `CFBundleIconFile`/`CFBundleIconName = AppIcon`.
- Decisions: at the time of PYP-111 menu bar still retains the SF Symbol template;
  This specification was later replaced by PYP-112/DEV-009 at the user's request.
- Blockers: there are no new blockers; ENV-002 is still only related to XCUI environment.
- Plan alignment: ON PLAN via DEV-008; no ADR required.
- Next action: PYP-001.

### 2026-08-11 — Py monogram for the navigation/menu bar

- Started with: navbar still displays the default clipboard icon even though the AppIcon has been changed.
- Completed: PYP-112; create `MenuBarIcon.imageset` from monogram Py and connect
  `StatusItemController` to asset template with SF Symbol fallback.
- In progress: none.
- Verification: SwiftFormat/SwiftLint 48 files, 0 violations; Debug build pass;
  Compiled `Assets.car` contains 18 px/1x and 36 px/2x, transparent, template mode.
- Iteration: loop detecting the rule format and sandbox blocking the Xcode cache;
  It has been formatted again and the sandbox build has been successfully completed.
- Decisions: menu bar logo keeps tint template for macOS to automatically change white/black; source
  artwork remains unchanged in `Design/Brand`.
- Blockers: there are no new blockers; ENV-002 is still only related to XCUI environment.
- Plan alignment: ON PLAN via DEV-009; no ADR required.
- Next action: PYP-001.

### 2026-08-11 — Quick Bar card fit and single-step navigation

- Started with: hidden front/back card; left/right press may jump two items.
- Completed: PYP-218; add adaptive layout metrics for up to six cards, edge
  inset 8 pt, inside border; remove scale selected; merge keyboard route and consume
  arrow auto-repeat.
- In progress: none.
- Verification: 29/29 package tests, targeted app repeat test and isolated XCUI
  test pass; UI measures frame card first/second, paste second item and export screenshot.
- Iteration: the old test only has two items, so it cannot catch double-step; raised to seven
  item + unique data per run. Visual QA at the beginning receives the global shortcut from the old app version,
  So the test can be isolated through the status item of the correct process and successfully run again.
- Decisions: keep the key repeat consumed for arrow so that once physically pressed it is always equal to
  one step; the card below three items still retains preferred width 216 pt.
- Blockers: none; ENV-002 was solved in the last XCUI session.
- Plan alignment: ON PLAN via DEV-010; no ADR required.
- Next action: PYP-001.

### 2026-08-11 — Accessibility enabled but the current build is untrusted

- Started with: System Settings enabled Accessibility for PyPaste but the app still
  prompt now and paste is not sent.
- Completed: diagnosis signing/TCC identity; stop both Debug app and hosted unit-test
  old process; add `AppLaunchContext` so that unit test does not run production lifecycle;
  Limit the system prompt once per session; add regression tests and instructions
  lead stable signing/reset grant.
- In progress: PYP-219 is waiting for reset/regrant and real-device verification.
- Verification: 30/30 package tests, 4/4 app unit tests, targeted UI menu test 1/1
  and lint 48 files/0 violations pass. After testing, there is no PyPaste service/process left.
- Iteration: the initial detection based on the unstable `DYLD_INSERT_LIBRARIES` variable because
  `ProcessInfo` scrub turns DYLD; change to `XCTestBundlePath` pair and
  `XCInjectBundleInto`. UI status-item test is deterministic by opening
  main window in UI-test mode, close and check the menu to reopen. After toggle photo
  still ON, live audit confirms that the same app path has changed CDHash; permission prompt is
  one-shot limit and regression test pass.
- Decisions: Experimental Debugging of TCC must use Apple Development/Personal Team;
  security is not lowered by designated requirement based solely on bundle ID.
- Blockers: no longer exist; ENV-003 has been resolved by Personal Team/Apple Development.
- Plan alignment: ON PLAN via DEV-011 and ADR-012.
- Next action: delete old ad-hoc grant, reissue signed build, verify through rebuild
  and complete PYP-219; then return to PYP-001.

### 2026-08-12 — Screenshot preview, persistent order and delete card

- Started with: request a screenshot showing the real preview, paste without changing the order,
  Drag-and-drop card is available and there is a `×` button to delete.
- Completed: PYP-220; migration v4 `sort_rank`, `ClipHistoryEditing`, ImageIO
  actor thumbnail, Quick Bar drag/drop, soft-delete and history mutation sequencing.
- In progress: none; PYP-219 holds `IN REVIEW` waiting for manual Accessibility paste.
- Verification: the final proof has raised to 75/75 package tests, 4/4 app unit
  baseline, targeted XCUI 2/2 baseline, signed Swift 6 app/test build and 63 files
  Clean lint. Runtime smoke verifies PNG preview, persistent drag rank and delete
  No pasteboard change; pixel-render test keeps rail correct on both edges.
- Iteration: refactor the model to separate `upsert` capture from `update` metadata; add
  persistent rank instead of `lastUsedAt`; serialize capture/move/delete to prevent
  stale reload/ghost card. The last XCUI pass was held by macOS before `app.launch()` because
  private runner approval, so final interaction can be checked by pasteboard/DB
  temporarily instead of registering fake pass.
- Decisions: thumbnail is only derived cache; original representations unchanged. Delete
  is soft-delete to prepare Trash/restore; Blob Store/lazy payload continues in M3.
- Blockers: no code blocker; PYP-219 still manual TCC confirmation.
- Plan alignment: ON PLAN via DEV-012 and ADR-013.
- Next action: complete manual PYP-219, then return to PYP-001.

### 2026-08-12 — Limit image preview in content slot

- Started with: preview image overflowing the content area of the Quick Bar card.
- Completed: fix card 162 pt to header 35 pt, preview 99 pt and footer 28 pt;
  Press all Button labels according to card bounds and preview clips in content slots.
- Verification: Xcode build pass; 47/47 package tests; SwiftFormat/SwiftLint 56
  file, 0 violation; visual QA panorama confirms the header/footer always displayed.
- Decisions: slot layout ownership card; `AsyncClipImagePreviewView` only renders according to
  allocation is granted. Keep `.fill` to keep the card beautiful and crop the excess in the slot.
- Blockers: none.
- Plan alignment: ON PLAN — correction is included in the PYP-220 acceptance criteria.
- Next action: PYP-219 manual Accessibility review.

### 2026-08-12 — Header card according to the source application color

- Started with: require the background of the title to be the same color as the app copied the content.
- Completed: add `ApplicationAccent` and async provider in SharedUI; Quick Bar
  inject provider, cache/coalesce according to bundle ID, get dominant color icon off-main,
  Use known-app override/deterministic fallback and WCAG foreground. Workspace
  tracker bypasses PyPaste PID to avoid losing external source when popup activate.
- Verification: 66/66 package tests pass outside sandbox with real Carbon/pasteboard;
  accent 16/16 and source tracker 3/3 separately. Signed Xcode Debug build pass by
  Apple Development. SwiftFormat/SwiftLint 60 files, 0 violations. Renderer 1320×238
  Confirm that the six header Mail/Notes/Music/Photos/Chrome/Xcode are the correct colors, letters/buttons are legible
  and image/content slot is unchanged.
- Iteration: full initial test in sandbox has 2 environment errors because one PyPaste paused
  under Xcode-beta debugserver keeps `⌘⇧V` and sandbox blocks named pasteboard; stops correctly
  debug session and rerun outside sandbox, all 66 tests passed.
- Decisions: accent is presentation data local-only according to ADR-014; not persist
  color/icon and no network. PyPaste retains its own black-white accent brand.
- Blockers: no code blocker; PYP-219 is still waiting for manual TCC confirmation.
- Plan alignment: ON PLAN — visual correction of PYP-220 according to ADR-014.
- Next action: PYP-219 manual Accessibility review.

### 2026-08-12 — Preview the insertion position when dragging the card

- Started with: requires drop position to light up or show the ball before dropping.
- Completed: replace the action-only drop with custom macOS 14 `DropDelegate`; add
  `QuickBarDragSession`, custom own-process UTType, leading/trailing rail glow,
  target highlight, animation 120 ms and Reduce Motion fallback. Hover does not reorder;
  `performDrop` commit once and then delete the session.
- Verification: 8/8 drag-session tests, 1/1 pixel-render overlay and 75/75 full
  Sandbox-side package pass; signed Xcode app/test build pass; SwiftFormat/
  SwiftLint 63 files, 0 violations. Renderer production view confirms before/after
  Edge is clear and reflow-free. Targeted XCUI exact three-card order has compiled but
  runner timeout before body test when automation mode (ENV-004) is turned on.
- Iteration: use hysteresis 42%/58% to rail vibration-free around the middle of the card; eliminate
  full ghost placeholder because it makes `LazyHStack` move under the cursor. Self-drop,
  Geometry error, stale target exit and double commit all have regression test.
- Decisions: transient presentation state/commit-on-drop according to ADR-015; unchanged
  SQLite `sort_rank` or representations.
- Blockers: no code blocker; XCUI drag rerun blocked by macOS automation worker.
- Plan alignment: ON PLAN — correction of PYP-220 according to DEV-013/ADR-015.
- Next action: users run the app and try drag; then complete the TCC manual PYP-219.

### 2026-08-13 — Restore drag-and-drop item

- Started with: users report dragging-dropping operations for missing items.
- Completed: transfer `.onDrag` from the outer wrapper directly to the main card Button;
  Use native `NSItemProvider` UTF-8 for AppKit to initialize drag stably, keep session
  guard, before/after rail glow, hysteresis and persistent `sort_rank` as before.
- Verification: real signed app seeded three cards and pulled by CGEvent; SQLite confirms
  Receive orders from `newest → middle → oldest` to `oldest → newest → middle` and inventory
  at drop. 75/75 package tests pass; SwiftFormat/SwiftLint 63 files, 0 errors.
- Iteration: targeted XCUI runner still hangs before the (ENV-004) test body, so it is not recorded
  Fake PASS; runtime independently verified by real app, mouse event and database.
- Decisions: amendment ADR-015/DEV-014; external plain-text drop cannot be rearranged
  because there is no active internal `QuickBarDragSession`.
- Blockers: no code blocker; ENV-004 only blocks XCUI rerun.
- Plan alignment: ON PLAN — PYP-220 correction follows DEV-014/ADR-015.
- Next action: `Cmd+R` user and try dragging on the card; then continue PYP-219.

### 2026-08-13 — Increase opacity drag target

- Started with: preview drop position is a bit difficult to see when dragging the card.
- Completed: increase the target fill from 8% to 20%, border from 70%/2 pt to 95%/3 pt,
  rail glow from 55% to 85%, expanding blur/shadow but unchanged hit testing/layout.
- Verification: pixel-render test before/after and center brightness pass; signed
  Xcode app build pass; SwiftFormat/SwiftLint 63 files, 0 errors.
- Decisions: visual-only tuning follows DEV-015/ADR-015.
- Blockers: no code blocker.
- Plan alignment: ON PLAN — PYP-220 visual correction, counters unchanged.
- Next action: `Cmd+R` user to check the new contrast level.

### 2026-08-13 — Quick Bar always accepts keyboard focus

- Started with: users always request all function keys of PyPaste popup
  Focus on the app when the popup appears.
- Completed: delete `.nonactivatingPanel`, turn Quick Bar into an activating key panel,
  Claim first responder immediately during the show and confirm focus again after the status menu
  end; the panel hides itself if PyPaste really loses its active state.
- Verification: targeted app unit 2/2 pass; end-to-end XCUI opens from the status menu,
  Press `→`, `Return`, `Esc` pass 1/1; SwiftFormat/SwiftLint 63 files, 0 errors.
- Iteration: the initial assertion focus is too tight because the responder must be correct
  `NSHostingView`; the necessary invariant modification is the panel that owns the key window, in
  When the router in `NSPanel.sendEvent` continues to receive all keystrokes in the popup.
- Decisions: DEV-016 amendment PYP-216; do not change shortcut or paste target.
- Blockers: no code blocker; ENV-004 resolved in this UI run.
- Plan alignment: ON PLAN — PYP-216 runtime correction, counters unchanged.
- Next action: `Cmd+R` user, open Quick Bar and use the keyboard right away without clicking.

### 2026-08-13 — Pinned Quick Bar can only be closed by × or Esc

- Started with: users correcting that popup always has to appear; `←`, `→`,
  `Return`, `Esc` must always focus and only `×`/`Esc` can be turned on.
- Completed: turn off auto-hide when deactivating, add window-focus reclaim, change shortcut
  Repeat refocus instead of toggle-close; paste suspend reclaim temporarily so that the target receives
  `⌘V`, wait for grace period 120 ms, then PyPaste reclaim focus and keep popup open.
- Verification: targeted app unit 4/4 pass; targeted XCUI 2/2 confirmation popup still
  opened and the arrow still works after `Return`, `Esc` and `×` buttons are closed correctly; lint
  63 clean files.
- Iteration: the first test uses two `NSWindow` keys to simulate a crash in the fake focus
  XCTest host; replace it with regression according to the real lifecycle paste, all test passes.
- Decisions: DEV-017 supersedes the auto-hide part of DEV-016; PYP-216 is still DONE.
- Blockers: none.
- Plan alignment: ON PLAN — PYP-216 runtime correction, counters unchanged.
- Next action: `Cmd+R` user and check pinned workflow on the real app.

### 2026-08-13 — External focus, global keys and width 80%

- Started with: users request popup to not close when focusing on other apps, four keys
  The function still controls PyPaste and width by 80% of the screen.
- Completed: remove focus reclaim after presentation; keep panel floating when deactivating; add
  `QuickBarKeyboardMonitoring`/Carbon implementation temporarily registered `←`, `→`,
  `Return`, `Esc`; unregister when hide; resolve target is foreground when paste;
  Frame calculation by 80% `visibleFrame.width` and center.
- Verification: package monitor 2/2, app unit 5/5, Finder-focus XCUI 1/1 and
  full package 77/77, format/lint 66 files, 0 equal errors pass; final signed app build
  successful.
  XCUI does not emit synthetic key through Carbon hotkey pipeline so routing command
  Confirmed in monitor/router unit tests instead of fake cross-process assertion.
- Iteration: detect an old PyPaste version that is holding global keys; stop the correct process
  That is before the test round. Do not delete the database or clipboard history.
- Decisions: DEV-018/DEV-019 and ADR-016 amendment PYP-216; counters unchanged.
- Blockers: no code blocker.
- Plan alignment: ON PLAN.
- Next action: `Cmd+R` user, open Quick Bar, click the target app and try the physical key.

### 2026-08-13 — Quick Bar dismiss when losing focus

- Started with: users corrected that popup did not turn off when out-focus was an error.
- Completed: turn `NSPanel.hidesOnDeactivate` on; connect `applicationDidResignActive`
  From AppDelegate to AppCoordinator to dismiss, reset transient model/paste target
  and stop keyboard monitor. Width 80% and keyboard routing when popup focus remains unchanged.
- Verification: targeted app unit 3/3, Finder-focus XCUI 1/1 and format/lint 66
  file, 0 error pass; UI test build/sign with Apple Development successful.
- Decisions: DEV-020 supersedes the pinned-after-deactivation part of DEV-018;
  Amendment ADR-016/PYP-216, counters unchanged.
- Blockers: none.
- Plan alignment: ON PLAN.
- Next action: Stop the old version, `Cmd+R`, open the popup window and click outside to test.

### 2026-08-13 — Rich URL preview

- Started with: users request web links with preview like reference cards.
- Completed: Card URL using header `Link`, LinkPresentation to download image/title and display
  domain; async provider with cache/coalescing/timeout, ImageIO downsample off-main,
  offline fallback and fixed 99 pt preview slot. Outbound network entitlement has
  Added to the target app.
- Verification: provider 4/4, visual render 1/1, full package 82/82, signed Xcode
  build pass and SwiftLint 70 file/0 error.
- Decisions: DEV-021/ADR-017 supersedes the offline-only URL part of ADR-010; metadata
  remote is presentation-only, no persist database/pasteboard.
- Blockers: none.
- Plan alignment: ON PLAN.
- Next action: Stop the old version, `Cmd+R`, copy a public URL and then open Quick Bar.

### 2026-08-13 — Loaded-history fuzzy search

- Started with: users request searches relatively according to title, app, content and category.
- Completed: `ClipSearchEngine` local find title/searchable text/app name/bundle/type
  aliases, regular hash/flower, prefix/substring, small typo and relevance-rank. Search
  The shared field has a debounce of 120 ms; Quick Bar/Main History displays the result count,
  empty state and clear. Keyboard paste/delete still uses result list; drag the key when filtering.
- Verification: matcher 4/4, model search 2/2, full package 88/88, signed Xcode
  build and SwiftLint 75 file/0 error passed.
- Decisions: DEV-022/ADR-018/PYP-221; loaded-history slice does not change FTS5 M3.
- Blockers: ENV-005 — targeted XCUI build/sign pass but macOS timeout when enabled
  automation before body test; no source/test assertion failure.
- Plan alignment: ON PLAN.
- Next action: `Cmd+R` user, create a few clips, open Quick Bar and try search/clear;
  Then continue manual TCC PYP-219.

### 2026-08-13 — Persistent Quick Bar collections

- Started with: the user requests the search located in the middle, `Clipboard` is the category
  By default, you can add/create categories and permanently keep sorted items.
- Completed: collection bar with four seed categories and `+` button; menu on the card added
  items enter many categories; search the correct panel center. SQLite v5 persist custom
  collection/membership and set retention protection transactionally; Quick Bar
  reset to Clipboard after each opening, while explicit delete still deletes the item correctly.
- Verification: targeted migration/repository/model 25/25, Xcode app + all
  test targets build-for-testing pass, SwiftFormat/SwiftLint 82 file/0 error.
- Decisions: DEV-023/ADR-019/PYP-222; Clipboard is a system view, membership is
  many-to-many persistence/retention boundary; full rename/delete CRUD in PYP-410.
- Blockers: ENV-006 — targeted workflow XCUI did not find test app window due to
  an old PyPaste Xcode version is running; build and all package-level assertions are passed.
- Plan alignment: ON PLAN.
- Next action: Stop the old PyPaste version, `Cmd+R` the new version and manual smoke add/reopen;
  Then continue to verify the real TCC for PYP-219.

### 2026-08-14 — Confirmed collection deletion

- Started with: users request to hover the current `×` category and must confirm
  before deleting.
- Completed: every collection has a hover-only delete control; Clipboard does not
  Can delete. Alert has Cancel/destructive Delete and clearly states that the item is still in Clipboard.
  SQLite deletes collection, cascade membership but retains clip + sticky retention;
  Delete the tab that is selected to transfer to Clipboard with revision guard.
- Verification: targeted model/repository 13/13, full app + test targets compile,
  SwiftFormat/SwiftLint 83 file/0 error.
- Decisions: DEV-024/ADR-020/PYP-223; delete collection is non-destructive with clip.
- Blockers: ENV-007 — targeted XCUI runner exited but xcodebuild hung when finalized;
  The test process was stopped correctly and the UI pass was declared without missing evidence.
- Plan alignment: ON PLAN.
- Next action: `Cmd+R`, hover over a collection, try Cancel and Delete; then continue
  manual manual TCC PYP-219.

### 2026-08-14 — Collection dialog-first Escape routing

- Started with: the user requested `Esc` to close Create/Delete popup first, next time
  PyPaste popup has just been closed.
- Completed: Create/Delete uses a modal state in the model; local AppKit event and
  global Carbon commands check modal first. Esc before clear dialog, Esc after
  dismiss Quick Bar; Return/arrow without paste/change selection behind alert.
- Verification: model 5/5, app keyboard router 2/2, full app + UI test targets
  compile, SwiftFormat/SwiftLint 83 file/0 error.
- Decisions: DEV-025/ADR-021/PYP-224; model is the source of truth for modal stack.
- Blockers: ENV-007 — targeted XCUI timeout when enabling automation before test
  body; no UI assertion is running, not functional assertion failure.
- Plan alignment: ON PLAN.
- Next action: `Cmd+R`, try Esc twice with both Create and Delete dialogs; then
  continue manual TCC PYP-219.

### 2026-08-14 — Immediate collection dialog dismissal

- Started with: users request `Esc` to close Create/Delete collection popup
  No delay or only very slight delay.
- Completed: replace SwiftUI system alert with modal overlay in Quick Bar, no
  transition/exit animation. Modal is removed in the same UI update when state clear;
  Scrim, focus text field, Cancel/Create/Delete and modal keyboard priority are retained.
- Verification: model 5/5, AppKit/Carbon Escape router 2/2, full app + unit/UI
  compile test targets, SwiftFormat/SwiftLint 84 file/0 error.
- Decisions: DEV-026/ADR-022/PYP-225; animation system alert is no longer located on
  collection interaction path.
- Blockers: no new code blockers; ENV-007 reappears in the new XCUI turn with
  xcresult `unknown`/0 test before body test, not functional assertion fail.
- Plan alignment: ON PLAN.
- Next action: `Cmd+R`, try Esc with Create/Delete; then continue manual TCC PYP-219.

### 2026-08-14 — Search field visual separation

- Started with: the user reported that the search box blended into the background because it did not see the border
  or shadow.
- Completed: shared search component has adaptive Light/Dark border, glass fill,
  base shadow; when focusing icon/outline, accent and shadow are slightly increased. Search logic,
  debounce, clear action and accessibility remain unchanged.
- Verification: signed app build pass; SwiftFormat/SwiftLint 84 file/0 error.
- Decisions: DEV-027/PYP-226; visual-only correction shared Quick Bar/History.
- Blockers: there are no new blockers.
- Plan alignment: ON PLAN.
- Next action: `Cmd+R`, check the search in Light/Dark; then continue PYP-219.

### 2026-08-14 — Borderless search refinement

- Started with: users want to remove borders, smooth background color and shadow transition.
- Completed: remove all strokes at normal/focus; use adaptive solid fill and
  shadow spread wide. Focus slightly increase fill/shadow by easeInOut 180 ms, icon still report
  focus on accent but do not create outline.
- Verification: signed app build pass; SwiftFormat/SwiftLint 84 file/0 error.
- Decisions: DEV-028 supersedes visual details DEV-027 in the same PYP-226.
- Blockers: there are no new blockers.
- Plan alignment: ON PLAN.
- Next action: `Cmd+R`, check the search in Light/Dark; then continue PYP-219.

### 2026-08-14 — Drag clip to the external app

- Started with: users requesting PyPaste cards can drag and drop directly to
  Other applications, in addition to the ability to reorder internally.
- Completed: NSItemProvider export original representations with visibility all;
  clip-ID marker changes from plain text UUID to custom own-process type. Internal
  drop only receives this marker; text-like payload lacks data with UTF-8 fallback.
- Verification: payload 4/4, relevant drag/reorder 23/23, signed app build and
  SwiftFormat/SwiftLint 85 file/0 error. Full package 97/101; four system resource errors
  The old statistics are kept by another process due to hotkey/pasteboard, not belonging to this change.
- Decisions: DEV-029/ADR-023/PYP-227; full multi-provider drag kept at PYP-808.
- Blockers: there is no new code blocker.
- Plan alignment: ON PLAN.
- Next action: `Cmd+R`, drag text/link/image card to TextEdit/Notes/Finder to
  manual smoke; then continue PYP-219.

### 2026-08-14 — Bold menu bar monogram

- Started with: users report that the logo in the menu bar is too faded/light and want it to be bold, beautiful,
  more impressive.
- Completed: replace old asset with monogram `Py` heavy rounded bo, alpha 100%, nearly coated
  full 18 pt canvas; retain transparent/template behavior and explicit image scaling.
  Add vector generator to reproduce 1x/2x consistently.
- Verification: signed build pass; assetutil confirms 18/36 px template mode;
  strict codesign pass; SwiftFormat/SwiftLint 85 file/0 error.
- Decisions: DEV-030 is visual correction of PYP-112, unchanged task counters.
- Blockers: there are no new blockers.
- Plan alignment: ON PLAN.
- Next action: Stop the old app, `Cmd+R` to load new assets in the menu bar; continue PYP-219.

### 2026-08-14 — Balanced lowercase menu icon

- Started with: users see `Py` is bigger than other app icons and want the menu bar only
  write in lowercase, aligned `py`; all remaining logos remain unchanged.
- Completed: asset menu changed to lowercase `py`, SF Rounded Bold 12 pt, kerning
  neat and centered canvas 18 pt; AppIcon does not change. Proportional scaling and
  Light/Dark behavior template is retained.
- Verification: generator strict-format pass; SwiftFormat/SwiftLint 85 file/0 error;
  signed app build, assetutil 18/36 px template mode and strict codesign pass.
- Decisions: DEV-031 supersedes the DEV-030 menu-bar visual details in PYP-112.
- Blockers: there are no new blockers.
- Plan alignment: ON PLAN.
- Next action: Stop the old app `Cmd+R` to reload the status item `py`; continue PYP-219.

### 2026-08-14 — Status menu follows its icon

- Started with: the user reported that the PyPaste menu appeared offset from the `py` icon to the position
  Different ideas on the menu bar.
- Investigation: the host only has one PyPaste process; the error is not due to duplicate app.
  Code is directly passing the menu to `NSStatusItem`, implicitly dependent on the system anchor.
- Completed: status button automatically handles click, highlight native and call `NSMenu.popUp`
  at bottom-leading in the coordinate space of the current button. Actions,
  shortcuts, accessibility label and native menu behavior are preserved.
- Verification: anchor unit 1/1 passed in 0.002 s; signed build passed;
  SwiftFormat/SwiftLint 85 file/0 error.
- Decisions: DEV-032 correction of PYP-108; unchanged task counters.
- Blockers: there are no new blockers.
- Plan alignment: ON PLAN.
- Next action: Stop the old `Cmd+R` app, click `py` and visually check the menu directly
  under the icon; then continue PYP-219.

### 2026-08-14 — One screen-anchored status menu

- Started with: users see two popups and request to delete the first pop-up that cuts off the goods
  `Open PyPaste`.
- Investigation: the host only has one PyPaste process and one LaunchServices
  registration. The first Popup is the same menu presented by flipped view coordinate,
  make it touch the top edge and cover the front row; not two instances.
- Completed: change button bounds through window to absolute screen frame, call
  `NSMenu.popUp` in screen coordinate space and add reentry guard to one
  Clicking only opens one menu. Native highlight and the entire menu actions are preserved.
- Verification: targeted anchor test 1/1 passed in 0.005 s; signed build passed;
  SwiftFormat/SwiftLint 85 file/0 error.
- Decisions: DEV-033 supersedes the coordinate part of DEV-032; unchanged task counters.
- Blockers: there are no new blockers.
- Plan alignment: ON PLAN.
- Next action: Stop the old app `Cmd+R`, click `py` and visually check the correct menu
  appear directly below the icon; then continue PYP-219.

### 2026-08-14 — Runtime English and Vietnamese

- Started with: users requesting apps to support English/Vietnamese and set selectors
  directly in the pop-up window of the `py` icon.
- Completed: add shared observable `AppLocalization`; the globe submenu is below
  monitoring with English/Vietnamese and checkmark; choose persist in
  UserDefaults. Status menu, Quick Bar, Main History, Settings, collection modal,
  Feedback, search/content labels and accessibility text change immediately without relaunch.
- Verification: localization 4/4, Features 46/46, status selector 1/1 pass; full
  package 101/105 with four old system-resource errors; signed app build pass and
  SwiftFormat/SwiftLint 89 file/0 error.
- Decisions: DEV-034/ADR-024/PYP-228; English is default when there is no selection.
- Blockers: there is no new code blocker.
- Plan alignment: ON PLAN.
- Next action: Stop old app, `Cmd+R`, open `py` → Language → Vietnamese and visual
  smoke status menu/Quick Bar; then continue PYP-219.

### 2026-08-15 — English repository authoring standard

- Started with: the user requested that all source authoring and Markdown files use English.
- Completed: converted DEVELOPMENT.md, PLAN.md, and the progress tracker to English; repaired
  translated heading/checkbox markers; audited Swift authoring; recorded PYP-229,
  DEV-035, and ADR-025. Vietnamese remains only in localization data and test fixtures
  that explicitly validate Vietnamese behavior.
- Verification: documentation/source language audits pass; all structural counts match
  the pre-conversion backup; package regression 101/105 with four known system-resource
  conflicts; signed app build passes; SwiftFormat/SwiftLint pass on 89 files.
- Decisions: English is the canonical repository authoring language. Localized product
  strings are data and remain available to preserve runtime bilingual support.
- Blockers: no new code blocker.
- Plan alignment: ON PLAN.
- Next action: complete the manual Accessibility/TCC verification for PYP-219.

### Session template

```markdown
### YYYY-MM-DD — Session name

- Started with:
- Completed:
- In progress:
- Verification:
- Decisions:
- Blockers:
- Plan alignment: ON PLAN / DRIFT DETECTED
- Next action:
```

---
