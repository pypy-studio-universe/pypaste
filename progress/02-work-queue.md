# PyPaste Progress — Work Queue

> Active work and the ordered queue. See [README.md](./README.md) for all tracker parts.

## 4. Current Work

PYP-230 is `IN PROGRESS`. PYP-219 remains in `IN REVIEW` for manual real-paste
confirmation before PYP-001.

#### PYP-230 — Public repository and version 0.1.0 preview release

- Status: IN PROGRESS
- Started: 2026-08-15
- Plan reference: PLAN.md → M2 → PYP-230; ADR-026
- Dependencies verified: Yes — source and current signed build are available
- Acceptance criteria:
  - [x] The progress tracker is split into focused files under `progress/` with an index.
  - [x] A Vietnamese-first, English-second installation and feature guide exists.
  - [x] Personal signing identifiers, local Xcode state, caches, and secret-like files are
    excluded from the public source tree.
  - [ ] Build and verify a universal macOS 0.1.0 archive.
  - [ ] Publish the source on the `main` branch of the configured GitHub repository.
  - [ ] Publish the archive, release notes, and checksum through GitHub Releases.
- Work completed:
  - Split the former monolithic tracker into seven purpose-specific files and an index.
  - Added the complete bilingual end-user guide and release notes.
  - Removed the committed Personal Team setting and expanded `.gitignore` security rules.
- Files changed:
  - `progress/`, `docs/USER_GUIDE.md`, `.gitignore`
  - `release/`, `PLAN.md`, `PyPaste.xcodeproj/project.pbxproj`
- Verification:
  - Secret filename/content-pattern scan: PASS — no credential payload found.
- Remaining:
  - Build, test, staged-tree audit, push, and GitHub Release creation.
- Blocked by: None

#### PYP-219 — Developer Accessibility/TCC verification stabilization

- Status: IN REVIEW
- Started: 2026-08-11
- Plan reference: PLAN.md → M2 → PYP-219; ADR-012
- Dependencies verified: Yes — code/test lifecycle and stable signing are complete
- Acceptance criteria:
  - [x] Hosted unit test does not start production lifecycle/global shortcut.
  - [x] There is regression test for hosted-unit-test and UI-test launch context.
  - [x] Clearly note the stable signing, reset/regrant process and identity verification.
  - [x] System Accessibility prompt is only requested once in each app session.
  - [x] Debug app has `Authority=Apple Development` and `TeamIdentifier`.
  - [ ] Grant Accessibility is valid after rebuild/relaunch.
  - [ ] Click/Return from Quick Bar paste the correct target application on the real machine.
- Work completed:
  - The current build diagnosis is `Signature=adhoc`, without TeamIdentifier and machine
    There is no valid code-signing identity.
  - Detect and stop two PyPaste with bundle ID, including one hosted old test process.
  - Add `AppLaunchContext` to hosted unit test do not start `AppCoordinator`.
  - Add one-shot permission request to repeat clicking without continuously opening the system prompt.
  - Supplementing unit/UI regression and signing instructions/Accessibility for newcomers.
  - A local Personal Team is selected; strict codesign verification passes.
- Files changed:
  - `App/AppDelegate.swift`
  - `Tests/PyPasteTests/FoundationTests.swift`
  - `Tests/PyPasteUITests/PyPasteUITests.swift`
  - `DEVELOPMENT.md`, `PLAN.md`, and `progress/`
- Verification:
  - Package tests: PASS — 30/30, including one-shot permission prompt regression.
  - App unit tests: PASS — 4/4; log no longer has production lifecycle.
  - Isolated UI menu test: PASS — 1/1.
  - Format/lint: PASS — 48 Swift files, 0 violations.
  - Process audit after test: PASS — no longer PyPaste test-host running in the background.
- Remaining:
  - Delete old grants, build signed app, grant permissions, relaunch/rebuild and test paste.
- Blocked by: None

### Current task checklist template

When starting a task, replace the template below with the actual task:

```markdown
#### PYP-XXX — Task name

- Status: IN PROGRESS
- Started: YYYY-MM-DD HH:mm
- Plan reference: PLAN.md → Mx → PYP-XXX
- Dependencies verified: Yes/No
- Acceptance criteria:
  - [ ] Condition 1
  - [ ] Condition 2
- Work completed:
  - ...
- Files changed:
  - ...
- Verification:
  - Command: `...`
  - Result: ...
- Remaining:
  - ...
- Blocked by: None
```

---

## 5. Next Queue

Do not ignore this order without intentionally if you have not recorded Plan Deviation.

| Order | Task | Status | Dependency | Goal |
|---:|---|---|---|---|
| 1 | PYP-230 | IN PROGRESS | Local build and GitHub access | Public source + version 0.1.0 preview release |
| 2 | PYP-219 | IN REVIEW | User confirmation | Reset/regrant + real Accessibility paste verification |
| 3 | PYP-001 | READY AFTER M2 | PYP-219 | Lock target, distribution and temporary bundle ID |
| 4 | PYP-002 | NOT STARTED | PYP-001 | One-page MVP PRD |
| 5 | PYP-003 | NOT STARTED | PYP-002 | Main History wireframe |
| 6 | PYP-004 | NOT STARTED | PYP-002 | Bottom Quick Bar wireframe |
| 7 | PYP-005 | NOT STARTED | PYP-002 | Settings and Onboarding wireframe |

---
