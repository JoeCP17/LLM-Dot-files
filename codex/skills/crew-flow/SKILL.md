---
name: crew-flow
description: "End-to-end plan, work, and review cycle. Use when the user says /crew-flow, crew-flow, Plan → Work → Review, or asks Codex to plan, implement, and review in one loop."
---

# Crew Flow

Run a complete plan -> work -> review cycle and iterate when review finds critical or high issues.

## Arguments

- `-r N` or `--rounds N`: max internal rounds per phase. Allowed `1`, `2`, `3`; default `3`.
- `--max-cycles N`: max work/review cycles. Allowed `1`, `2`, `3`; default `2`.
- remaining text: task description.

If the task description is empty, ask what to build and stop.

## Workflow

1. Create `.codex/crew/cycles/<cycle-id>/cycle.json` with task, round limit, and max cycles.
2. Run the Crew Plan workflow. If the plan is ambiguous, ask the user whether to proceed, refine, or stop.
3. Run the Crew Work workflow.
4. Run the Crew Review workflow against the working tree.
5. If review has critical or high findings and max cycles is not reached, return to Crew Work with the review findings as input.
6. Stop when review has no critical/high findings, max cycles is reached, or the user chooses to stop.
7. Summarize cycle id, changed files, verification, review result, and next action.

## State

Store state under `.codex/crew/`:

```text
.codex/crew/
├── cycles/<cycle-id>/cycle.json
├── runs/<run-id>/
├── seed-<timestamp>.md
└── seed-latest.md
```

Do not delete state during the flow. Use `crew-cleanup` for cleanup.
