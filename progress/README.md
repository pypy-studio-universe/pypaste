# PyPaste Progress Tracker

This directory is the operational record for PyPaste development. The files are split by
purpose so that daily updates remain small and easy to review. [PLAN.md](../PLAN.md) is the
source of truth for scope, architecture, dependencies, and task order.

## Tracker map

| File | Purpose | Update timing |
|---|---|---|
| [01-dashboard.md](./01-dashboard.md) | Current snapshot, milestone counters, functional status | Start and end of every work session |
| [02-work-queue.md](./02-work-queue.md) | Active task details and ordered next queue | Whenever work starts, pauses, or changes state |
| [03-completed-work.md](./03-completed-work.md) | Completed task summaries | After Definition of Done is met |
| [04-blockers-and-alignment.md](./04-blockers-and-alignment.md) | Blockers, plan checks, decisions, and deviations | Before changing scope or when blocked |
| [05-verification-evidence.md](./05-verification-evidence.md) | Build, test, lint, signing, and runtime evidence | After every verification run |
| [06-session-log.md](./06-session-log.md) | Chronological handoff notes | End of every work session |
| [07-process-and-next-action.md](./07-process-and-next-action.md) | Update protocol and immediate continuation point | When workflow rules or next action change |

## Update protocol

1. Read this file, [01-dashboard.md](./01-dashboard.md), and
   [07-process-and-next-action.md](./07-process-and-next-action.md).
2. Confirm the next task and dependencies against [PLAN.md](../PLAN.md).
3. Mark exactly one task `IN PROGRESS` in [02-work-queue.md](./02-work-queue.md).
4. Record scope changes in [04-blockers-and-alignment.md](./04-blockers-and-alignment.md)
   before implementing them.
5. Put reproducible commands and results in
   [05-verification-evidence.md](./05-verification-evidence.md).
6. When the task meets its Definition of Done, move its summary to
   [03-completed-work.md](./03-completed-work.md), update the dashboard counters, and append
   a handoff entry to [06-session-log.md](./06-session-log.md).

## Rules

- Do not mark a task `DONE` without evidence.
- Do not silently reorder the queue or expand scope.
- Keep secrets, credentials, personal signing identifiers, and machine-specific paths out of
  the tracker.
- Keep runtime localization strings in localization resources, not in engineering notes.
