---
name: crew-work
description: "Implement a task with a review loop. Use when the user says /crew-work, crew-work, 구현하고 검증, or asks Codex to implement work with self-review and tests."
---

# Crew Work

Implement the requested change, verify it, and run a focused review loop before finishing.

## Workflow

1. Parse optional round count: `-r 1`, `-r 2`, or `-r 3`. Default is `3`.
2. If `.codex/crew/seed-latest.md` exists, read it and use it as planning context. Ignore it if `mode` is not `plan`.
3. Check `git status --short --untracked-files=all`. If unrelated user changes are present, keep them intact and avoid staging them.
4. Read the relevant code before editing.
5. Make the smallest coherent change.
6. Run the narrowest meaningful verification command. Broaden tests when shared behavior changed.
7. Review the diff:
   - correctness and edge cases
   - compatibility with existing patterns
   - security or secret exposure
   - missing tests
8. Fix critical or high-confidence issues, then repeat verification/review up to the round limit.
9. Write `.codex/crew/runs/<run-id>/accepted.md` summarizing accepted changes and verification.

## Output

Report changed files, verification commands and results, and any residual risk. Do not claim tests passed unless they actually ran.
