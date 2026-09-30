---
name: octo-patch
description: "Patch the Claude Octo plugin timeout and Gemini provider behavior. Use when the user says /octo-patch, octo-patch, Octo 타임아웃 패치, or asks to reapply the Octo plugin patch."
---

# Octo Patch

Patch the Claude Octo plugin cache so timeout values can be overridden by environment variables.
This edits files under `~/.claude/plugins/cache/nyldn-plugins/octo/<version>/`.

## Options

- no argument: apply patch
- `--dry-run`: show target files and intended replacements only
- `--status`: report current patch state
- `--revert`: restore `.orig` backups

Reject any other argument.

## Targets

- `scripts/lib/review.sh`
  - replace the hard-coded 300 second round-1 polling timeout with `${OCTOPUS_REVIEW_R1_TIMEOUT:-900}`
  - gate Gemini detection with `${OCTOPUS_DISABLE_GEMINI:-false}`
- `scripts/lib/quality.sh`
  - replace `TIMEOUT=600` with `${OCTOPUS_AGENT_TIMEOUT:-900}`
- `scripts/lib/agents.sh`
  - guard `PROGRESS_TRACKING_ENABLED` and `PROGRESS_FILE` with default values for `set -u`

## Safety

1. Detect the latest Octo version directory.
2. Verify all target files exist.
3. Before applying, create `.orig` backups only if missing.
4. Patch idempotently.
5. Verify expected strings exist after patching.
6. If verification fails, revert from backups and report the failure.

## Environment Variables

```bash
export OCTOPUS_REVIEW_R1_TIMEOUT=1200
export OCTOPUS_AGENT_TIMEOUT=1200
export OCTOPUS_DISABLE_GEMINI=true
```
