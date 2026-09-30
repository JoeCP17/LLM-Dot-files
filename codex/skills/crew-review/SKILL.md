---
name: crew-review
description: "Code review mode for Codex. Use when the user says /crew-review, crew-review, 리뷰해줘, review this, or asks for adversarial review of a path, staged diff, working tree, or PR."
---

# Crew Review

Review for bugs, regressions, missing tests, and operational risks. Findings come first.

## Scope Parsing

- `--staged`: review `git diff --cached`
- `--working-tree`: review `git diff`
- path argument: focus on that file or directory
- PR number or base ref: inspect the PR/diff if available
- no argument: review current working tree

## Workflow

1. Gather scope with `git status`, `git diff --stat`, and the relevant diff.
2. Read changed files around each suspicious hunk before making a finding.
3. Prioritize concrete defects over style. Each finding needs file and line reference when possible.
4. Severity order: critical, high, medium, low.
5. If there are no findings, say so and note remaining test gaps.
6. Save a short JSON or markdown summary under `.codex/crew/runs/<run-id>/review.md` when this is part of a crew flow.

## Output Format

Use this shape:

```markdown
**Findings**
- high: path/to/file.ext:123 - ...

**Open Questions**
- ...

**Test Gaps**
- ...
```

Skip empty sections except `Findings`.
