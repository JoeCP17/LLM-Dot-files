---
name: crew-plan
description: "Multi-pass implementation planning for Codex. Use when the user says /crew-plan, crew-plan, 합의 기반 계획, multi-agent plan, or asks for a plan that should be stress-tested before implementation."
---

# Crew Plan

Create a plan, critique it, then revise it until the risks and next steps are clear.

## Workflow

1. Parse optional round count: `-r 1`, `-r 2`, or `-r 3`. Default is `3`; stop early when the plan is stable.
2. If the task is empty, ask what to plan and stop.
3. Inspect only the files needed to understand the request.
4. Draft the plan with:
   - goal
   - ordered steps
   - assumptions with evidence
   - risks and verification
5. Critique the draft yourself. If the user explicitly requested multi-agent debate and subagents are available, delegate one bounded skeptic/reviewer pass.
6. Revise the plan. Repeat up to the round limit only if material issues remain.
7. Save the accepted plan to `.codex/crew/seed-<timestamp>.md` and update `.codex/crew/seed-latest.md`.

## Seed Format

```markdown
---
mode: plan
created_at: <UTC ISO timestamp>
rounds_used: <1|2|3>
convergence: converged
---

## Goal
...

## Plan
1. ...

## Assumptions
- ...

## Verification
- ...
```

## Output

Return the final plan and the seed path. Do not implement unless the user asked to continue.
