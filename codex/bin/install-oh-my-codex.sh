#!/usr/bin/env bash
set -euo pipefail

# Install only OMX. Codex itself is managed by Homebrew Cask to avoid
# /opt/homebrew/bin/codex collisions with npm's @openai/codex package.
export PATH="/opt/homebrew/bin:/opt/homebrew/opt/node@20/bin:$PATH"

NPM_BIN="/opt/homebrew/bin/npm"
if [[ ! -x "$NPM_BIN" ]]; then
  echo "npm not found at $NPM_BIN. Run brew bundle install first." >&2
  exit 1
fi

"$NPM_BIN" install -g oh-my-codex
