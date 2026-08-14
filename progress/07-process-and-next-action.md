# PyPaste Progress — Process and Next Action

> Update rules and the immediate continuation point. See [README.md](./README.md).

## 12. Mechanism to ensure that it does not go astray

The two files have different roles:

| File | Role | When will it be updated |
|---|---|---|
| `PLAN.md` | Scope, architecture, task order, acceptance criteria | When there is a decision or task completed |
| `progress/` | Actual status, current task, evidence, blocker | The beginning and end of every working session |

Mandatory procedure for each session:

1. Read Snapshot and Next Queue in this file.
2. Match the task with Execution Backlog in `PLAN.md`.
3. Check dependency and phase gate.
4. Transfer a correct task to `IN PROGRESS`.
5. Implement within the scope of the recorded acceptance criteria.
6. Build/test and save proof.
7. If Definition of Done is reached, mark the task in both files.
8. Update the percentage and next task.
9. Run End-of-session check.

If the above process is maintained, it is possible to clearly track the completed part, the part that is
done, the unfinished parts and early detection when implementation starts deviating from the plan.

---

## 13. Next Action

**Current task: `PYP-219` — IN REVIEW; no task `IN PROGRESS`.**
Code/test-lifecycle and stable signing are complete; there is still the old reset grant step and check
true TCC:

1. Stop all PyPaste, delete old Accessibility entries, build/run the correct app, and grant permissions again.
2. Quit/relaunch and rebuild once; confirm the trusted rights and click/Return
   paste from `⌘⇧V` correctly into TextEdit or the destination application.
3. Write the proof in real paste and
   The completion of the PYP-219/M2 phase gate mark.

After PYP-219, return to `PYP-001` to finalize the product definition before M3. Recorder
advanced shortcut, paste modes, sandbox folder permission and multi-screen hardening
The picture still belongs to M5/M6.
