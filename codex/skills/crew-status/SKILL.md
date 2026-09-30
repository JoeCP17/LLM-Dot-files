---
name: crew-status
description: "Summarize Codex crew state. Use when the user says /crew-status, crew-status, crew 상태, or asks for current plan/work/review run status."
---

# Crew Status

Summarize `.codex/crew/` state without modifying it.

## Workflow

1. If `.codex/crew/` does not exist, report that there is no crew state.
2. With `--run <run-id>`, show only that run.
3. With `--cycle <cycle-id>`, show only that cycle.
4. Otherwise list recent cycles, runs, `seed-latest.md`, and stale files.
5. Treat state older than 10 minutes as stale for active work, but do not delete it.

## Output

Include:

- latest plan seed
- active or recent cycle ids
- review result if present
- verification result if present
- cleanup suggestion when old state is present
