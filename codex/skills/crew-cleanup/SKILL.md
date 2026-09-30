---
name: crew-cleanup
description: "Clean Codex crew state. Use when the user says /crew-cleanup, crew-cleanup, crew 정리, or asks to remove old .codex/crew seed/run/cycle files."
---

# Crew Cleanup

Clean old `.codex/crew/` state. Default is dry-run.

## Rules

- No argument: dry-run only.
- `--apply`: delete files after the user has seen dry-run output or explicitly requested apply.
- Any other argument: print supported arguments and stop.

## Cleanup Targets

- `seed-*.md` older than 30 days, except the file targeted by `seed-latest.md`
- `runs/<run-id>/` older than 30 days
- `cycles/<cycle-id>/` older than 30 days
- history files over 200 lines, keeping the newest 200 lines

## Workflow

1. Print what would be deleted.
2. If not applying, stop and ask the user to rerun with `--apply` if they want deletion.
3. If applying, delete only the listed targets and report counts.
