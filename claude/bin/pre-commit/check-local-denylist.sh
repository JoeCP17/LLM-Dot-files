#!/usr/bin/env bash
# pre-commit 훅 — 레포 밖 로컬 denylist(사내 도메인·네임스페이스·버킷명 등)에 있는 문자열이 스테이징 파일에 있으면 차단

# Usage: pre-commit 이 스테이징 파일 목록을 인자로 넘김.
# Denylist: $LLM_DOTFILES_DENYLIST (기본 ~/.config/llm-dotfiles/denylist.txt). 한 줄에 한 문자열, # 주석·빈 줄 무시.
#   레포에는 절대 넣지 않는다 — 목록 자체가 사내 정보다. 파일이 없으면 경고 없이 통과(새 PC 에서 다른 레포 커밋을 막지 않기 위해).
# Exit: 0 없음 / 1 발견
# Reference: SECURITY.md 1절

set -uo pipefail

LIST="${LLM_DOTFILES_DENYLIST:-$HOME/.config/llm-dotfiles/denylist.txt}"
[[ -f "$LIST" ]] || exit 0

patterns="$(grep -vE '^\s*(#|$)' "$LIST" || true)"
[[ -n "$patterns" ]] || exit 0

status=0
for f in "$@"; do
  [[ -f "$f" && ! -L "$f" ]] || continue
  hits="$(grep -nFi -f <(echo "$patterns") "$f" 2>/dev/null || true)"
  [[ -z "$hits" ]] && continue
  echo "✗ $f — 로컬 denylist 문자열 발견 ($LIST)"
  echo "$hits" | head -3 | sed 's/^/    /'
  status=1
done
exit $status
