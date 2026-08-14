# PyPaste Progress — Dashboard

> Start here for the current project status. The complete tracker index is in
> [README.md](./README.md), and [PLAN.md](../PLAN.md) remains the source of truth.

## 0. Current snapshot

| Property | Status |
|---|---|
| Latest update date | 2026-08-15 |
| Project status | PYP-230 public repository and preview release completed; PYP-219 remains in manual review |
| Current milestone | M2 — Clipboard Core Vertical Slice |
| Task is being performed | No — PYP-219 is IN REVIEW |
| Next ready task | Confirm PYP-219; then PYP-001 |
| Task completed recently | PYP-230 — public source and GitHub prerelease 0.1.0 |
| Current blocker | No code blocker; PYP-219 waiting for manual TCC; ENV-007 blocking XCUI runtime collection |
| Plan alignment | ON PLAN — bilingual branded README follows DEV-039; product scope is unchanged |
| MVP progress | 41/124 tasks — 33.1% |
| Full roadmap progress | 41/150 tasks — 27.3% |

### Quick conclusion

- Clipboard polls every 350 ms and monitoring stops when sleep/session inactive.
- Capture keeps all item/UTType, app source, representation order and processing
  hash/payload on actor background.
- SHA-256 canonical hash, feedback suppression, race retry and two duplicates
  Policies have been activated.
- SQLite migration v5, live history UI, pause/resume, collections and recopy many
  The item has been connected end-to-end.
- `⌘⇧V` toggle Bottom Quick Bar in horizontal card shape at the bottom edge of the screen; click card
  Save clipboard, go back to the previous application and send `⌘V` when Accessibility is available.
- Quick Bar uses black-white liquid glass; valid HEX code only displays real color.
  HTTP(S) URL has rich preview image/title/domain; if download error or timeout, try again
  About offline host/path. All cards still have consistent app source.
- Quick Bar and Main History have fuzzy search on a maximum of 200 clips loading: title,
  content, app/bundle and type; skip the common punctuation marks/flowers, support small typos, relevance
  ranking and debounce 120 ms. Search field without border, adaptive
  background, smooth shadow and soft focus transition. Query does not persist or log.
- Quick Bar has a bar collection with `Clipboard` always selected by default, four names
  Seed section, category creation button and menu to add items on the card. Membership/custom
  collection is stored in SQLite v5; items belonging to collection have retention protection
  After restart/reboot, it disappears only when the user actively deletes it.
- Create/Delete dialog stands on the Quick Bar in the modal stack keyboard: `Esc` first
  Close the dialog, `Esc` next will close the Quick Bar; Return/arrow does not affect the card
  Behind the dialog is still open. The dialog is directly in the panel, there is no exit
  animation should disappear in the same update UI when `Esc` is pressed.
- `←`/`→` change the selected item, `Return` paste and `Esc` close popup. Popup will close by itself
  when PyPaste loses focus; lifecycle cleanup simultaneously frees temporary global
  keys to avoid keeping the keys of other applications.
- The popup is centered and width right 80% of the current available screen area.
- Quick Bar calculates card width according to viewport: up to six cards are placed in the popup window with
  inset the two edges; arrow auto-repeat is consumed, so each press only goes one item.
- Screenshots saved by macOS in files will automatically be placed in the clipboard and captured
  Enter history; PyPaste does not import old photos or normal photos in the same folder.
- Destination/custom screenshot name can be read from macOS; identification metadata support
  Native localization helper and writer maintain the original byte/UTType image, without decoding on the main thread.
- Screenshot/image render real thumbnail via ImageIO actor/downsampling; preview
  paste still uses the original data because it cannot be inserted into representations.
- Quick Bar divides the card into header 35 pt, preview 99 pt and footer 28 pt; photos used
  fill/crop but always clip in preview slot, do not hide metadata or title.
- Header card uses the identification color of the source app: override for popular apps, segment
  dominant color accumulation from the local icon for other apps and deterministic fallback. Letters,
  icon, progress and `×` button, black/white optional with enough contrast; accent does not call the network.
- Workspace tracking keeps the external application close to the latest time when PyPaste auto-activates to
  Open Quick Bar, avoid assigning the wrong source app/color if users open popups very quickly.
- Paste/copy keeps the card position unchanged. Drag-and-drop updates `sort_rank` sustainably;
  The soft-delete button `×` deletes the clip correctly and does not save pasteboard.
- The card can be dragged to another macOS app with original representations. Custom clip
  The marker is visible only in the process to reorder; the app does not receive internal UUID
  and plain text dragged from the outside cannot activate reorder.
- During pulling, the target card is highlighted and the glowing rail appears on the edge
  before/after; hysteresis around the vibration-proof midpoint, and only commit when drop.
- AppIcon retains the monogram `Py`; the menu bar uses the `py` font in SF Rounded lowercase
  Bold 12 pt, transparent and customizable 18 pt canvas template Light/Dark.
- Status menu change button bounds to absolute screen frame and anchor at
  bottom-leading of `py`; single-presenter guard prevents repeated opening, available
  `Open PyPaste` is not cut at the edge of the screen.
- The status menu has a `Language` submenu with English and Vietnamese. The selected
  language has a checkmark, persists through restart, and updates Quick Bar, Main History,
  Settings, collection dialogs, feedback and accessibility text.
- English is the canonical source and documentation language. Vietnamese is retained
  only as runtime localization data or a narrowly scoped locale-specific test fixture.
- If Accessibility is not available, the click will still copy securely, call the system prompt and
  display clear instructions for users to authorize and then click again.
- Debug app and test targets using Apple Development/Personal Team stably; grant
  For closing PYP-219, the old ad-hoc still requires reset/regrant and manual real paste.
- Hosted unit test does not start production coordinator, clipboard anymore
  monitor, status item or global shortcut; the two old PyPaste processes have been stopped.
- 88/88 package tests pass on the real macOS environment, including 8 drag-session, 1
  pixel-render rail/glow, 16 source-app accent and 3 external-app tracking tests;
  rich-link provider/cache pass 4/4 and bounded image/caption render pass 1/1;
  blur-dismiss correction pass 3/3 app unit and 1/1 targeted XCUI. Signed
  Xcode app build pass with outbound network entitlement; SwiftLint reports 0 violation
  on 75 Swift files. Search-specific matcher/model tests pass 6/6.
- Real Accessibility auto-paste cannot conclude PASS until ad-hoc grant
  The old one was deleted, the Apple Development-signed version was issued again and survived rebuild.
- ENV-002/ENV-004 incidents have been resolved; signed XCUI runner is now starting
  and complete the end-to-end normal keyboard test.
- Visual QA from XCUI screenshot confirming that six cards are located in the panel 1320×238, with
  safe inset two edges, liquid glass, preview link, HEX swatch and source app footer.
- Runtime smoke on the final build confirms PNG preview, drag persistence and delete
  pasteboard unchanged. The XCUI run is new build/sign pass but macOS test worker is waiting
  private runner approval; this is a verification environment blocker, not a code blocker.
- Visual renderer uses the production card/overlay to confirm the white-green rail and
  glow lies right on the leading/trailing edge, does not reflow the card or cover the content.

---

## 1. State convention

| Status | Meaning |
|---|---|
| `NOT STARTED` | Not started yet and dependency may not be completed |
| `READY` | You can start right away, no more dependency blocking |
| `IN PROGRESS` | It is being done |
| `BLOCKED` | Unable to continue because there is a specific blocker |
| `IN REVIEW` | Done, checking or reviewing |
| `DONE` | Has reached Definition of Done in PLAN.md |
| `DEFERRED` | It was proactively postponed and the reason was recorded |

### Update rules

1. Only leave a maximum of one main task in `IN PROGRESS` state, unless the recording plan
   Obviously, it can be done in parallel.
2. When starting the task, add `Current Work` and write the start time.
3. When completed, you must write the build/test evidence before transferring to `DONE`.
4. Simultaneously mark `[x]` for the correct task in `PLAN.md`.
5. After each task, update the count and percentage in `Current Snapshot` and
   `Milestone Dashboard`.
6. If the new task does not exist in PLAN.md, it has not been started until completed
   all `Plan Change Check`.
7. If plan deviation is detected, transfer `Plan alignment` to `DRIFT DETECTED` and write
   clearly in `Plan Deviation Log`.
8. Phase gate does not include percentage of task, but must be completed before changing
   milestone.

### Progress formula

```text
Milestone progress = DONE tasks / total milestone tasks
MVP progress       = DONE tasks in M0–M7 / 124
Roadmap progress   = DONE tasks in M0–M9 / 150
```

---

## 2. Milestone Dashboard

| Milestone | Scope | Done | Total | Progress | Status | Phase Gate |
|---|---|---:|---:|---:|---|---|
| M0 | Product Definition and UX | 0 | 10 | 0% | READY | Not checked |
| M1 | Project Foundation | 12 | 12 | 100% | DONE | Passed |
| M2 | Clipboard Core + Quick Bar Extension | 29 | 30 | 96.7% | IN REVIEW | PYP-219 manual review |
| M3 | Persistence, Search and Content Types | 0 | 15 | 0% | NOT STARTED | Not checked |
| M4 | Main History and Organization | 0 | 12 | 0% | NOT STARTED | Not checked |
| M5 | Menu Bar, Quick Bar and Paste | 0 | 15 | 0% | NOT STARTED | Not checked |
| M6 | Privacy, Settings and Lifecycle | 0 | 15 | 0% | NOT STARTED | Not checked |
| M7 | MVP Hardening and Beta Release | 0 | 15 | 0% | NOT STARTED | Not checked |
| M8 | PyPaste 1.0 Advanced Features | 0 | 13 | 0% | NOT STARTED | Not checked |
| M9 | Peer Share | 0 | 13 | 0% | NOT STARTED | Not checked |

### Release status

| Release | Milestone | Progress | Status |
|---|---|---:|---|
| MVP Beta | M0–M7 | 41/124 — 33.1% | IN PROGRESS |
| PyPaste 1.0 | M8 | 0/13 — 0% | NOT STARTED |
| PyPaste 1.1 Peer Share | M9 | 0/13 — 0% | NOT STARTED |

---

## 3. Functional Area Dashboard

| Area | Priority | Milestone | Status | Note |
|---|---|---|---|---|
| Product definition and wireframe | P0 | M0 | NOT STARTED | Starting from PYP-001 |
| Project scaffold and CI | P0 | M1 | DONE | Xcode workspace + CI workflow |
| Clipboard observation | P0 | M2 | DONE | Polling 350 ms + sleep/session awareness |
| Screenshot capture | P0 | M2 | DONE | File destination → clipboard → history; direct clipboard is still captured |
| Source application tracking | P0 | M2 | DONE | Best effort through NSWorkspace |
| Text capture and round-trip | P0 | M2 | DONE | Capture → persist → UI → recopy |
| Database and migrations | P0 | M1–M3 | IN PROGRESS | Migration v1–v5 DONE; Blob Store/FTS5 at M3 |
| Loaded-history fuzzy search | P0 | M2 | DONE | Title/content/app/bundle/type on up to 200 clips; FTS5 is still in M3 |
| Full-text search and pagination | P0 | M3 | NOT STARTED | Wait for the schema to stabilize |
| Smart content detection | P0/P1 | M2/M3 | IN PROGRESS | HEX + HTTP(S) URL vertical slice DONE; full parser in M3 |
| Main History Window | P0 | M1/M4 | IN PROGRESS | M1 window skeleton DONE; M4 left |
| Favorites and Collections | P0 | M2/M4 | IN PROGRESS | Quick Bar persistent collection slice DONE; full CRUD in M4 |
| Menu bar and shortcuts | P0 | M1/M2/M5 | IN PROGRESS | Menu + fixed `⌘⇧V` DONE; recorder in M5 |
| Bottom Quick Bar | P0 | M2/M5 | IN PROGRESS | Bottom bar + click + basic keyboard DONE; multi-screen hardening at M5 |
| Copy/Paste coordinator | P0 | M2/M5 | IN PROGRESS | Basic copy/paste DONE; paste modes in M5 |
| Accessibility auto-paste | P0 optional | M2/M6 | IN PROGRESS | Stable signing DONE; waiting for reset/regrant + real paste, onboarding in M6 |
| Privacy rule engine | P0 | M6 | NOT STARTED | Run ahead of persistence |
| Settings and onboarding | P0 | M1/M6 | IN PROGRESS | M1 Settings scene skeleton DONE |
| Performance/release hardening | P0 | M7 | NOT STARTED | Wait M0–M6 |
| Four-edge Quick Bar | P1 | M8 | NOT STARTED | Not included in MVP |
| Preview and drag-and-drop | P1 | M2/M8 | IN PROGRESS | M2 image thumbnail/card reorder DONE; richer preview/file DnD at M8 |
| Quick Mode | P1 | M8 | NOT STARTED | Wait for Quick Bar/Paste to stabilize |
| Paste Stack | P1 | M8 | NOT STARTED | Wait for core actions |
| Peer Share | P2 | M9 | NOT STARTED | Network off by default |

---
