# PyPaste Progress — Blockers and Plan Alignment

> Blockers, plan alignment, deviations, and approved scope changes. See
> [README.md](./README.md) for the tracker index.

## 7. Blocked Work

There is no current blocker source code. ENV-001 to ENV-004 have been resolved;
PYP-219 has one more step to verify interaction on TextEdit. ENV-005 to ENV-007 is
block automation, do not block the corresponding DoD source/build/unit of the task.

| Task | Blocker | From the day | What do you need to continue | Owner |
|---|---|---|---|---|
| ENV-001 | RESOLVED — Xcode license accepted | 2026-08-09 | No need to take any further action | User |
| ENV-002 | RESOLVED — isolated XCUI test has run and visual QA pass | 2026-08-10 | No need to take any further action | Environment |
| ENV-003 | RESOLVED — Personal Team/Apple Development identity valid; strict codesign pass | 2026-08-11 | No need to sign any more | User |
| ENV-004 | RESOLVED — signed UI runner has started and targeted keyboard XCUI pass 1/1 | 2026-08-13 | Monitor if timeout automation reappears | Environment |
| ENV-005 | ACTIVE — search XCUI runner timeout when automation is enabled before test body | 2026-08-13 | Rerun after macOS XCTest automation worker is stable; manual Cmd+R smoke | Environment |
| ENV-006 | ACTIVE — XCUI collection does not see the test app window because an old Xcode-launched PyPaste is holding the same bundle ID | 2026-08-13 | Stop the old PyPaste version and rerun targeted XCUI collection | User/Environment |
| ENV-007 | ACTIVE — unstable XCUI automation collection: one finalize suspension; modal-Esc timeout when enabling automation before test body | 2026-08-14 | Rerun manual or targeted XCUI after macOS automation worker is stable | Environment |

---

## 8. Plan Alignment Check

Run this checklist before starting a task and before ending a work session.

### Pre-work check

- [x] PYP-220 exists in M2 of `PLAN.md`.
- [x] The user has directly requested to perform M2 and shortcut before M0.
- [x] Preview/order/delete scope is recorded in DEV-012 and ADR-013.
- [x] Source-app accent, drag-placement and runtime drag-source correction are recorded
  in ADR-014/ADR-015 with DEV-013/DEV-014/DEV-015.
- [x] Keyboard-focus/pinned correction of Quick Bar is recorded in DEV-016/DEV-017
  and PYP-216.
- [x] External-focus/global-key and width 80% are recorded in DEV-018/DEV-019, ADR-016
  and PYP-216.
- [x] Correction dismiss-on-blur is recorded in DEV-020, amendment ADR-016 and PYP-216.
- Rich URL preview is recorded in DEV-021, ADR-017 and amendment PYP-216.
- [x] Loaded-history fuzzy search is recorded in DEV-022, ADR-018 and PYP-221;
  FTS5 PYP-311/312 is not marked as early completed.
- [x] Task does not drag P1/P2 into MVP.
- [x] Persistent order/soft-delete/derived thumbnail has been recorded as ADR-013.
- [x] Privacy constraints are still maintained.

### End-of-session check

- [x] Update the task that is currently being done and the rest.
- [x] Update build/test evidence.
- [x] Synchronize checkbox task in `PLAN.md` if task DONE.
- [x] Update Milestone Dashboard.
- [x] Update MVP/Roadmap progress.
- [x] Mark a new blocker if available.
- [x] Record Plan Deviation if there are changes in scope/order.
- [x] Update Session Log.

### Alignment status

| The test time | The outcome | Note |
|---|---|---|
| 2026-08-09 | ON PLAN | Implementation has not started; next task is PYP-001 |
| 2026-08-09 | ON PLAN | M1 completed according to DEV-001; ADR-003/005 synchronized dependency; return to PYP-001 |
| 2026-08-09 | ON PLAN | PYP-201→212 M2 completed according to DEV-002 and ADR-006 |
| 2026-08-09 | ON PLAN | PYP-213 completed according to DEV-003/ADR-007; returned to PYP-001 |
| 2026-08-10 | ON PLAN | PYP-214 completed according to DEV-004/ADR-008; M2 phase gate pass; return to PYP-001 |
| 2026-08-10 | ON PLAN | PYP-215 completed according to DEV-005/ADR-009; full regression pass; return to PYP-001 |
| 2026-08-10 | ON PLAN | PYP-216 completed according to DEV-006/ADR-010; M2 phase gate pass; return to PYP-001 |
| 2026-08-10 | ON PLAN | PYP-217 completed according to DEV-007/ADR-011; ENV-002 only affects XCUI rerun; return to PYP-001 |
| 2026-08-11 | ON PLAN | PYP-111 completed according to DEV-008; AppIcon build/bundle validation pass; return to PYP-001 |
| 2026-08-11 | ON PLAN | PYP-112 completed according to DEV-009; menu bar template asset compile/validation pass; return to PYP-001 |
| 2026-08-11 | ON PLAN | PYP-218 completed according to DEV-010; layout, repeat routing and isolated UI visual QA pass; return to PYP-001 |
| 2026-08-11 | ON PLAN | PYP-219 partially implemented according to DEV-011/ADR-012; real TCC verification blocked by ENV-003 |
| 2026-08-12 | ON PLAN | ENV-003 resolved by stable local development signing; PYP-219 continued reset/regrant + real paste verification |
| 2026-08-12 | ON PLAN | PYP-220 starts with DEV-012/ADR-013; PYP-219 transfers to IN REVIEW waiting for manual confirmation |
| 2026-08-12 | ON PLAN | PYP-220 completed according to DEV-012/ADR-013; M2 only has PYP-219 manual review |
| 2026-08-12 | ON PLAN | PYP-220 drag UX correction completed according to DEV-013/ADR-015; counters unchanged |
| 2026-08-13 | ON PLAN | PYP-216 rich URL preview completed according to DEV-021/ADR-017; counters unchanged |
| 2026-08-13 | ON PLAN | PYP-221 loaded-history fuzzy search completed according to DEV-022/ADR-018; FTS5 kept in M3 |
| 2026-08-14 | ON PLAN | PYP-228 runtime bilingual UI completed according to DEV-034/ADR-024; PYP-219 is still IN REVIEW |
| 2026-08-15 | ON PLAN | PYP-229 English repository standard completed according to DEV-035/ADR-025; PYP-219 remains IN REVIEW |

---

## 9. Plan Deviation Log

### DEV-001 — Implement Project Foundation before Product Definition

- Date: 2026-08-09
- Requested change: Users request to deploy the entire Epic 1/M1 immediately.
- Reason: Need a project to run so that new users have a foundation to learn Xcode/Swift.
- Affected tasks/milestones: Change the order of M1 before M0; do not skip task M0.
- Data/privacy impact: No clipboard capture; database only contains empty schema.
- Schedule impact: M1 completed early, then returned to PYP-001.
- Decision: Approved by explicit user request.
- PLAN.md updated: Yes; version 1.1.0.

### DEV-002 — Implement Clipboard Capture Engine before Product Definition

- Date: 2026-08-09
- Requested change: Users request to deploy the entire Epic 2 immediately after M1.
- Reason: Need a real vertical slice to learn and check clipboard on macOS.
- Affected tasks/milestones: PYP-201→212 are done before M0; binary parser is dark
  minor and duplicate policy are basically withdrawn early from M3.
- Data/privacy impact: Clipboard is saved locally in SQLite; payload is not logged and
  network is not sent.
- Schedule impact: M2 completed early; M0 remains unchanged and returns after extension.
- Decision: Approved by explicit user request.
- PLAN.md updated: Yes; version 1.2.0.

### DEV-003 — Add default shortcut Command-Shift-V

- Date: 2026-08-09
- Requested change: Users request `⌘⇧V` to open clipboard manager to select clips.
- Reason: Need quick access to history from the working app.
- Affected tasks/milestones: Add PYP-213 to M2; recorder/custom shortcut,
  preserve target app and auto-paste are still in PYP-504/PYP-508/PYP-512/PYP-610.
- Data/privacy impact: Do not read payload further and do not ask for Accessibility.
- Schedule impact: M2 will reopen for a small task before returning to PYP-001.
- Decision: Approved by explicit user request.
- PLAN.md updated: Yes; version 1.3.0 and ADR-007.

### DEV-004 — Bottom Quick Bar and click-to-paste with Control-Shift-V

- Date: 2026-08-10
- Requested change: Users request `⌃⇧V` to display the bar card at the bottom of the screen;
  Click the item that needs to paste into the working application.
- Reason: Main Window interrupts workflow and does not look like quick clipboard picker.
- Affected tasks/milestones: Add PYP-214 to M2; drag vertical slice narrow of
  PYP-502/503/505/508/511/512/513 go up early. Full keyboard navigation, multi-screen
  matrix, shortcut recorder and paste modes are still in M5/M6.
- Data/privacy impact: No network/log payload added. Synthetic `⌘V` is only
  Sent when the user grants Accessibility; there is always a copy-only fallback.
- Schedule impact: M2 will reopen for PYP-214 before returning to PYP-001.
- Decision: Approved by explicit user request.
- PLAN.md updated: Yes; version 1.4.0 and ADR-008.

### DEV-005 — Correction to Command-Shift-V and visual according to the new image

- Date: 2026-08-10
- Requested change: User corrects shortcut to `⌘⇧V` and provides two photos
  picker bottom with Clipboard History bar and colored header card.
- Reason: Synchronize interaction and visual language with the latest desired UX.
- Affected tasks/milestones: Add PYP-215 to M2; keep the architecture/paste flow unchanged
  PYP-214. The real collection/template still belongs to M4/M5, no fake data is built.
- Data/privacy impact: Schema, payload, logging, network or permission unchanged.
- Schedule impact: M2 reopen for PYP-215 and then return to PYP-001.
- Decision: Approved by explicit user request.
- PLAN.md updated: Yes; version 1.5.0/1.5.1 and ADR-009.

### DEV-006 — Liquid glass, smart previews and keyboard navigation

- Date: 2026-08-10
- Requested change: black-white UI liquid glass; HEX displays real color; card with
  source app; link with preview; `←`/`→` select item and `Esc` close popup.
- Reason: Complete the ability to recognize content and operate keyboard-first.
- Affected tasks/milestones: Add PYP-216 to M2, pull a narrow vertical slice of
  color/URL detection in M3 and keyboard navigation in M5 starts early.
- Data/privacy impact: Schema unchanged. URL preview parses offline, does not call the network.
- Schedule impact: M2 reopen for PYP-216 and then return to PYP-001.
- Decision: Approved by explicit user request.
- PLAN.md updated: Yes; version 1.6.0/1.6.1 and ADR-010.

### DEV-007 — Screenshot automatically into clipboard/history

- Date: 2026-08-10
- Requested change: When the user takes a screenshot, the photo must also be saved to the clipboard.
- Reason: Screenshot must appear in history even though the default macOS shortcut saves the file.
- Affected tasks/milestones: Add PYP-217 to M2; reuse image capture of
  M2 and leave the full thumbnail/parser in PYP-307/PYP-310.
- Data/privacy impact: Track the correct screenshot folder and only read the new photos
  metadata/screenshot name; no Screen Recording permission, network or payload log.
- Schedule impact: M2 reopen for PYP-217 and then return to PYP-001.
- Decision: Approved by explicit user request.
- PLAN.md updated: Yes; version 1.7.0 and ADR-011.

### DEV-008 — Use Py monogram as an AppIcon

- Date: 2026-08-11
- Requested change: Use the logo `Py` selected as the logo for the PyPaste app.
- Reason: Complete application recognition in Finder/Dock/Xcode and macOS bundle.
- Affected tasks/milestones: Add PYP-111 to M1; unchanged behavior/runtime.
- Data/privacy impact: None.
- Schedule impact: M1 will reopen for a branding task and then return to PYP-001.
- Decision: Approved by explicit user request.
- PLAN.md updated: Yes; version 1.7.1; no new ADR required.

### DEV-009 — Use Py monogram for menu bar

- Date: 2026-08-11
- Requested change: Change the default clipboard logo on the navbar/menu bar with the logo
  Application's `Py`.
- Reason: Brand recognition synchronization between AppIcon and the running icon.
Affected tasks/milestones: Add PYP-112 to M1; only change asset and presentation
  of `NSStatusItem`, unchanged clipboard behavior.
- Data/privacy impact: None.
- Schedule impact: M1 will reopen for a branding task and then return to PYP-001.
- Decision: Approved by explicit user request.
- PLAN.md updated: Yes; version 1.7.2; no new ADR required.

### DEV-010 — Fix clipping card and jumping navigation of two items

- Date: 2026-08-11
- Requested change: The front/back card must be in the popup window and each time you press the arrow
  only transfer one item correctly.
- Reason: Six fixed-width cards exceed viewport 60 pt; surplus keyboard routing and
  not consume arrow auto-repeat.
- Affected tasks/milestones: Adding PYP-218 to M2; correcting presentation and event
  routing, unchanged model clip or persistence.
- Data/privacy impact: None.
- Schedule impact: M2 reopen for a correction task and then return to PYP-001.
- Decision: Approved by explicit user request.
- PLAN.md updated: Yes; version 1.7.3; no new ADR required.

### DEV-011 — Accessibility turned on but current build is still untrusted

- Date: 2026-08-11
- Requested change: Users have enabled PyPaste in Accessibility but the app still
  prompt now and no auto-paste.
- Reason: Debug artifact is signing ad-hoc, no TeamIdentifier and designated
  requirement changes according to CDHash after rebuild. At the same time, the old hosted unit test has
  run production lifecycle, create two PyPaste with global shortcut bundle ID.
- Affected tasks/milestones: Add PYP-219 to M2; isolate hosted-test lifecycle and
  Request stable Apple Development signing before confirming real TCC paste.
- Data/privacy impact: No payload, database, network or additional rights change.
  Do not use weak custom ad-hoc requirements to avoid TCC.
- Schedule impact: M2 opens again and PYP-001 waits after PYP-219. The real-device test part is
  block until the user selects Personal Team in Xcode.
- Decision: Approved by direct bug report.
- PLAN.md updated: Yes; version 1.7.4/1.7.5 and ADR-012.

### DEV-012 — Screenshot preview, drag-and-drop order and delete card

- Date: 2026-08-12
- Requested change: Screenshot automatically paste into PyPaste and preview; paste unchanged
  History order; drag and drop cards to reorder; `×` button in the left corner to delete items.
- Reason: The image clip only shows the word `Image`; the display order is attached to
  `lastUsedAt` should paste the card itself to the top and the UI does not have edit actions.
- Affected tasks/milestones: Add PYP-220 to M2; migration v4, repository history
  editor, Quick Bar thumbnail/drag/delete and regression multi-item order.
- Data/privacy impact: Local-only thumbnail derived, without network/log payload;
  delete is soft-delete; original pasteboard representations remain unchanged.
- Schedule impact: PYP-220 is done before manual review of PYP-219 is closed and
  before returning to PYP-001 according to the latest direct request.
- Decision: Approved by explicit user request.
- PLAN.md updated: Yes; version 1.8.0/1.8.1 and ADR-013.

### DEV-013 — Preview the insertion position before dropping the card

- Date: 2026-08-12
- Requested change: When dragging the card, the front/back position is expected to light up or have
  The ball so that users know exactly where the card will be dropped.
- Reason: Old Drag implementation only determines placement after mouse-up, so there is no
  Intuitive feedback while hovering.
- Affected tasks/milestones: Visual/interaction correction of PYP-220 in M2;
  do not add tasks or change critical path.
- Data/privacy impact: No database change, pasteboard payload, permission or network.
- Schedule impact: No change to task counters; PYP-219 is still the manual review left.
- Decision: Approved by explicit user request.
- PLAN.md updated: Yes; version 1.8.4 and ADR-015.

### DEV-014 — Restore drag-and-drop card operation

- Date: 2026-08-13
- Requested change: Drag-and-drop item is lost and must work again.
- Reason: Drag source is attached outside `QuickBarClipCard`, while main card is
  A `Button` receives a mouse gesture first, so AppKit does not initialize the drag session.
- Affected tasks/milestones: Runtime correction of PYP-220 in M2; unchanged
  schema, order semantics, task counters or critical path.
- Data/privacy impact: Clipboard/database unchanged. Provider only carries the UUID of the card;
  external text drop was rejected because there was no PyPaste drag session in memory.
- Schedule impact: unchanged; PYP-219 is still the manual review left.
- Decision: Approved by explicit user request.
- PLAN.md updated: Yes; version 1.8.6, amendment ADR-015.

### DEV-015 — Increase the clarity of drag target

- Date: 2026-08-13
- Requested change: Increase opacity when dragging-dropping because the position preview is a bit difficult to see.
- Reason: Overlay 8% and rail glow 55% are not enough contrast on photo card/bright background.
- Affected tasks/milestones: Visual correction of PYP-220; unchanged interaction,
  persistence, task counters or critical path.
- Data/privacy impact: unchanged.
- Schedule impact: unchanged.
- Decision: Approved by explicit user request.
- PLAN.md updated: Yes; version 1.8.7, visual tuning in ADR-015.

### DEV-016 — Quick Bar always receives keyboard focus

- Date: 2026-08-13
- Requested change: When the PyPaste popup appears, `←`, `→`, `Return` and `Esc` must
  Always control the Quick Bar without clicking the popup first.
- Reason: `.nonactivatingPanel` can focus on the previous app/menu, especially when
  Quick Bar is opened from the status menu, so the keyboard event is unstable.
- Affected tasks/milestones: Runtime correction of PYP-216 in M2; unchanged
  shortcut, paste target snapshot, database, task counters or critical path.
- Data/privacy impact: unchanged.
- Schedule impact: unchanged; PYP-219 is still the manual review left.
- Decision: Approved by explicit user request.
- PLAN.md updated: Yes; version 1.8.8, amendment PYP-216.

### DEV-017 — Pinned Quick Bar can only be closed by × or Esc

- Date: 2026-08-13
- Requested change: Popup PyPaste must always appear and continue to receive `←`, `→`,
  `Return`, `Esc`; only `×`, `Esc` buttons or turn off the app to close the popup.
- Reason: Auto-hide rule when app deactivates and closes after successful paste of DEV-016
  Not suitable for pinned workflow that the user has just confirmed.
- Affected tasks/milestones: Supersede the auto-hide part of DEV-016; runtime
  correction PYP-216 in M2, unchanged shortcut/database/task counters.
- Data/privacy impact: unchanged. Paste will only temporarily activate the target to send `⌘V`.
- Schedule impact: unchanged; PYP-219 is still the manual review left.
- Decision: Approved by explicit user correction.
- PLAN.md updated: Yes; version 1.8.9, amendment PYP-216.

### DEV-018 — Pinned popup does not grab focus from the target app

- Date: 2026-08-13
- Requested change: Popup still appears when clicking on another app; while the popup is open,
  `←`, `→`, `Return`, `Esc` always control PyPaste.
- Reason: Reclaim key focus of DEV-017 makes users unable to set the cursor or
  Choose the paste location in the destination application.
- Affected tasks/milestones: Supersede the focus reclaim part of DEV-017; PYP-216
  Use temporary global command routing and resolve paste target when manipulating.
- Data/privacy impact: Do not read the keystroke sequence; only register four fixed commands in
  popup loop. No database/network change.
- Schedule impact: Do not change counters or critical path.
- Decision: Approved by explicit user correction.
- PLAN.md updated: Yes; version 1.9.0, ADR-016 and amendment PYP-216.

### DEV-019 — Quick Bar 80% wider than the screen

- Date: 2026-08-13
- Requested change: Width popup by 80% of the screen.
- Reason: Keep the bar wide enough but still have breathing gaps on both sides of all displays.
- Affected tasks/milestones: Layout correction of PYP-216; visible calculation
  The frame of the screen contains the cursor and center, does not change the card/database.
- Data/privacy impact: unchanged.
- Schedule impact: Do not change counters or critical path.
- Decision: Approved by explicit user request.
- PLAN.md updated: Yes; version 1.9.0, amendment PYP-216.

### DEV-020 — Quick Bar closes automatically when losing focus

- Date: 2026-08-13
- Requested change: When clicking/focusing outside PyPaste, the popup must automatically close.
- Reason: Pinned behavior of DEV-018 is no longer suitable for the latest workflow.
- Affected tasks/milestones: Supersede the "popup continue to appear when another app
  foreground" of DEV-018. PYP-216 uses `hidesOnDeactivate` and AppDelegate cleanup;
  width 80% of DEV-019 is unchanged.
- Data/privacy impact: unchanged. Cleanup frees up global keys, resets transient
  selection/paste target and do not delete clipboard history.
- Schedule impact: Do not change counters or critical path.
- Decision: Approved by explicit user correction.
- PLAN.md updated: Yes; version 1.9.1, amendment ADR-016/PYP-216.

### DEV-021 — Rich preview when copying web link

- Date: 2026-08-13
- Requested change: Card URL structured like reference image: header `Link`, image
  Website, title and domain representatives.
- Reason: DEV-006 offline preview host/path is not intuitive enough to recognize the link.
- Affected tasks/milestones: Presentation correction of PYP-216; supersede part
  Offline-only URL of DEV-006/ADR-010 with ADR-017. No task counters changed.
- Data/privacy impact: Valid HTTP(S) URL is allowed by LinkPresentation to download metadata when
  display card. Metadata/photos cache memory only up to 128 items, not persist into
  SQLite/pasteboard, timeout 6 seconds and fallback offline; app adds outbound network
  entitlement. Do not send clipboard payload outside the URL and do not log URL/payload.
- Schedule impact: Critical path unchanged; PYP-219 remains a task IN REVIEW.
- Decision: Approved by explicit user request.
- PLAN.md updated: Yes; version 1.9.2, ADR-017/PYP-216 amendment.

### DEV-022 — Fuzzy search on all clip fields that are loading

- Date: 2026-08-13
- Requested change: Relative search by title, app, content and related categories.
- Reason: Users need to quickly find clips from the Quick Bar instead of only navigating sequentially.
- Affected tasks/milestones: Add PYP-221 to M2 as loaded-history vertical slice;
  PYP-311/PYP-312 of M3 is not marked early.
- Data/privacy impact: Normalize/match completely local; query does not persist, no
  network and no log. MainActor only filters up to 200 clips after debounce 120 ms.
- Schedule impact: M2 increases from 20 to 21 tasks; DONE increases by one. PYP-219 is still IN REVIEW.
- Decision: Approved by explicit user request.
- PLAN.md updated: Yes; version 1.10.0, ADR-018/PYP-221.

### DEV-034 — Runtime English/Vietnamese selector

- Date: 2026-08-14
- Requested change: The app supports English and Vietnamese; selector is in the popup
  menu bar PyPaste.
- Reason: Users need to change the language directly at the place where the app/Quick Bar opens and keep
  Choose in the next run.
- Affected tasks/milestones: Adding PYP-228 to M2; SharedUI owns localization
  state, AppKit status menu and SwiftUI views share the same instance.
- Data/privacy impact: Only persist `en`/`vi` in UserDefaults; unchanged SQLite,
clipboard payload, network or logging.
- Schedule impact: M2 increases from 27 to 28 tasks and DONE from 26 to 27; PYP-219 remains unchanged
  IN REVIEW, critical path unchanged.
- Decision: Approved by explicit user request.
- PLAN.md updated: Yes; version 1.14.0, ADR-024/PYP-228.

### DEV-035 — English repository authoring standard

- Date: 2026-08-15
- Requested change: Convert all source authoring and Markdown documentation to English.
- Reason: The user wants one consistent language for implementation, planning, progress
  tracking, and onboarding.
- Affected tasks/milestones: Add PYP-229 to M2 and ADR-025. Runtime Vietnamese
  localization and locale-specific test fixtures remain because they are product data,
  not the repository's authoring language.
- Data/privacy impact: None. Translation ran through the local Apple Translation model;
  project documents were not sent to an external translation service.
- Schedule impact: M2 increases from 28 to 29 tasks and DONE from 27 to 28. PYP-219
  remains IN REVIEW and the critical path is unchanged.
- Decision: Approved by explicit user request.
- PLAN.md updated: Yes; version 1.15.0, ADR-025/PYP-229.

When you need to change the plan, add records according to the template:

```markdown
### DEV-XXX — Title

- Date:
- Requested change:
- Reason:
- Affected tasks/milestones:
- Data/privacy impact:
- Schedule impact:
- Decision: Approved/Rejected/Deferred
- PLAN.md updated: Yes/No
```

| ID | Date | Change | Impact | Decision |
|---|---|---|---|---|
| DEV-001 | 2026-08-09 | Do M1 before M0 | Only change the order, not scope | APPROVED |
| DEV-002 | 2026-08-09 | Do M2 before M0 | Change the order and drag the minimum binary parser into M2 | APPROVED |
| DEV-003 | 2026-08-09 | Add `⌘⇧V` to open Main Window | Add PYP-213; auto-paste is still in M5 | APPROVED |
| DEV-004 | 2026-08-10 | `⌃⇧V` Bottom Quick Bar + click-to-paste | Add PYP-214; pull M5 vertical slice up early | APPROVED |
| DEV-005 | 2026-08-10 | Correction to `⌘⇧V` + new visual | Add PYP-215; do not add fake collections | APPROVED |
| DEV-006 | 2026-08-10 | Liquid glass + preview + keyboard | Add PYP-216; preview URL offline | APPROVED |
| DEV-007 | 2026-08-10 | Screenshot automatically into clipboard | Add PYP-217; monitor file local-only | APPROVED |
| DEV-008 | 2026-08-11 | Use Py monogram as an AppIcon | Add PYP-111; runtime unchanged | APPROVED |
| DEV-009 | 2026-08-11 | Use Py monogram for menu bar | Add PYP-112; only change the presentation of NSStatusItem | APPROVED |
| DEV-010 | 2026-08-11 | Fix Quick Bar card clipping + jump arrow two items | Add PYP-218; layout/event routing only | APPROVED |
| DEV-011 | 2026-08-11 | Accessibility ON but the current build is untrusted | Add PYP-219; stable signing + hosted-test isolation | APPROVED |
| DEV-012 | 2026-08-12 | Screenshot preview + persistent order + delete card | Add PYP-220; migration v4 and Quick Bar edit actions | APPROVED |
| DEV-013 | 2026-08-12 | Preview the position before/after drop | PYP-220 interaction correction; unchanged persistence | APPROVED |
| DEV-014 | 2026-08-13 | Restore drag-and-drop runtime card | Drag source to main Button; unchanged persistence | APPROVED |
| DEV-015 | 2026-08-13 | Increase opacity/glow drag target | PYP-220 visual-only correction | APPROVED |
| DEV-016 | 2026-08-13 | Quick Bar always receives keyboard focus | PYP-216 runtime correction; activating key panel | APPROVED |
| DEV-017 | 2026-08-13 | Pinned popup closes only with ×/Esc | Supersede DEV-016 auto-hide; Return without dismissing | APPROVED |
| DEV-018 | 2026-08-13 | Popup appears when other app focuses + global keys | Supersede DEV-017 focus reclaim; temporary Carbon routing | APPROVED |
| DEV-019 | 2026-08-13 | Popup 80% wider than the screen | PYP-216 layout-only correction | APPROVED |
| DEV-020 | 2026-08-13 | Popup will close automatically when losing focus | Supersede DEV-018 pinned behavior; lifecycle cleanup | APPROVED |
| DEV-021 | 2026-08-13 | Rich preview photo/title/domain for web link | Supersede URL offline-only; bounded network presentation enrichment | APPROVED |
| DEV-022 | 2026-08-13 | Fuzzy search title/app/content/type | Add PYP-221 loaded-history slice; FTS5 kept in M3 | APPROVED |
| DEV-023 | 2026-08-13 | Collection bar + permanent categorized items | Add PYP-222 SQLite v5 slice; full CRUD is still in M4 | APPROVED |
| DEV-024 | 2026-08-14 | Hover `×` and confirm to delete the collection | Add PYP-223/ADR-020; delete membership but keep clip/retention | APPROVED |
| DEV-025 | 2026-08-14 | `Esc` closes the collection dialog before Quick Bar | Add PYP-224/ADR-021; modal state shared for local/global keyboard | APPROVED |
| DEV-026 | 2026-08-14 | `Esc` pop-up collection without delay feeling | Add PYP-225/ADR-022; replace system alert with immediate in-panel modal | APPROVED |
| DEV-027 | 2026-08-14 | The search field is difficult to distinguish from the background | Add PYP-226; shared visual-only correction, unchanged search semantics | APPROVED |
| DEV-028 | 2026-08-14 | Search field does not use border, need soft background and shadow | Supersede visual style DEV-027; retain PYP-226 scope and search semantics | APPROVED |
| DEV-029 | 2026-08-14 | Drag PyPaste card to another application | Add PYP-227/ADR-023; vertical slice from PYP-807, multi-item kept in PYP-808 | APPROVED |
| DEV-030 | 2026-08-14 | The menu bar logo is too fragmented and dull | PYP-112 visual correction; heavy rounded template asset, unchanged AppIcon/runtime | APPROVED |
| DEV-031 | 2026-08-14 | The `Py` menu bar logo is too big compared to other apps | Supersede DEV-030; lowercase `py` 12 pt only for menu bar, AppIcon remains unchanged | APPROVED |
| DEV-032 | 2026-08-14 | Status popup appears far from the `py` icon | PYP-108 correction; explicit button-relative anchor thay implicit item.menu | APPROVED |
| DEV-033 | 2026-08-14 | It looks like there are two popups; the first pop-up is missing `Open PyPaste` | Supersede the coordinate part of DEV-032; use absolute screen anchor + single-presenter guard | APPROVED |
| DEV-034 | 2026-08-14 | Runtime English/Vietnamese with selector in status menu | Add PYP-228/ADR-024; shared observable localization + UserDefaults persistence | APPROVED |
| DEV-035 | 2026-08-15 | English source authoring and Markdown documentation | Add PYP-229/ADR-025; retain Vietnamese only as localization or locale-specific test data | APPROVED |
| DEV-036 | 2026-08-15 | Split progress tracking, publish public source, and create a bilingual preview release | Add PYP-230/ADR-026; keep engineering docs English with an explicit bilingual user-guide exception | APPROVED |
| DEV-037 | 2026-08-15 | Add thank-you and donation options to the public repository | README-only update with PayPal link and repository-hosted MoMo QR; no app/runtime scope change | APPROVED |

---
