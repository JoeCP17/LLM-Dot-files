#!/usr/bin/env bash
# ~/.claude/settings*.json 을 공개 레포용으로 정제해 claude/settings/ 에 백업

# Usage: sanitize-settings.sh [--check]
#   기본: 정제 후 claude/settings/settings.json, settings.local.json 덮어쓰기 + diff 요약
#   --check: 파일을 쓰지 않고 차이만 출력. 차이가 있으면 exit 1 (드리프트 감지용)
# 정제 규칙 (denylist — Claude Code 가 새 키를 추가해도 백업에서 빠지지 않게):
#   settings.json       del(.autoMode)               머신 스캔 결과. 사내 도메인·prod 네임스페이스·버킷명 포함
#   settings.json       .orca/agent-hooks 참조 훅 제거   orca 앱이 설치 시 홈 절대경로로 다시 주입함
#   settings.json       env 값 중 키 이름이 KEY|TOKEN|SECRET|PASSWORD|CREDENTIAL 에 걸리면 "<redacted>"
#   settings.json       source=="directory" 인 marketplace 와 그 플러그인 제거   로컬 디렉터리라 새 PC 에 없음
#   settings*.json      $HOME 절대경로 → ~   (경계 있는 치환: $HOME/ 또는 $HOME" 만)
#   settings.local.json ~ 치환 후에도 /Users/ 가 남는 permissions.allow 항목 제거   다른 머신 잔재
# 여기서 못 거르는 것: permissions.allow 의 사내 도메인·명령 인자. check-local-denylist.sh 가 커밋 시 재검사.
# Exit: 0 / 1 (--check 에서 차이 있음, jq 없음, 입력 없음)
# Reference: claude/bin/pre-commit/check-settings-sanitized.sh, docs/plans/2026-09-30-security-guard-and-verify/context-notes.md

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="${BASE_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
OUT_DIR="$BASE_DIR/claude/settings"
CHECK=0; [[ "${1:-}" == "--check" ]] && CHECK=1
changed=0

command -v jq >/dev/null || { echo "jq 미설치 — brew install jq" >&2; exit 1; }

# 경계 있는 $HOME → ~ 치환. 홈 경로가 다른 사용자명(예. <name> 과 <name>2)의 앞부분에 매칭되지 않게 뒤에 / 또는 " 가 와야 한다.
tilde() { sed -e "s#${HOME}/#~/#g" -e "s#${HOME}\"#~\"#g"; }

sanitize_one() {
  local src="$1" dst="$2" pre_filter="$3" post_filter="$4"
  [[ -f "$src" ]] || { echo "⚠ $src 없음 — 건너뜀"; return 0; }
  local tmp; tmp="$(mktemp)"; trap 'rm -f "$tmp"' RETURN
  jq "$pre_filter" "$src" | tilde | jq "$post_filter" > "$tmp"
  if [[ -f "$dst" ]] && cmp -s "$tmp" "$dst"; then
    echo "= $(basename "$dst") 변경 없음"
  else
    changed=1
    echo "~ $(basename "$dst") 변경:"
    # head 가 먼저 닫히면 SIGPIPE 로 pipefail 이 실패를 돌려주므로 || true 로 set -e 중단 방지
    { diff <(jq -S . "$dst" 2>/dev/null || echo "{}") <(jq -S . "$tmp") | grep -E '^[<>]' | head -20 | sed 's/^/    /'; } || true
    (( CHECK )) || cp -f "$tmp" "$dst"
  fi
}

SETTINGS_PRE='del(.autoMode)
  | if .hooks then .hooks |= (
      with_entries(.value |= (map(.hooks |= map(select((.command // "") | test("\\.orca/agent-hooks") | not)))
                              | map(select((.hooks | length) > 0))))
      | with_entries(select((.value | length) > 0)))
    else . end
  | if .env then .env |= with_entries(if (.key | test("KEY|TOKEN|SECRET|PASSWORD|CREDENTIAL"; "i")) then .value = "<redacted>" else . end) else . end
  | (.extraKnownMarketplaces // {} | to_entries | map(select(.value.source.source == "directory") | .key)) as $local_mp
  | if .extraKnownMarketplaces then .extraKnownMarketplaces |= with_entries(select(.key as $k | $local_mp | index($k) | not)) else . end
  | if .enabledPlugins then .enabledPlugins |= with_entries(select((.key | split("@")[1]) as $m | $local_mp | index($m) | not)) else . end'
LOCAL_POST='if .permissions.allow then .permissions.allow |= map(select(test("/Users/") | not)) else . end'

sanitize_one "$CLAUDE_HOME/settings.json"       "$OUT_DIR/settings.json"       "$SETTINGS_PRE" '.'
sanitize_one "$CLAUDE_HOME/settings.local.json" "$OUT_DIR/settings.local.json" '.'            "$LOCAL_POST"

if (( CHECK )); then
  (( changed )) && { echo "(--check: 백업본과 차이 있음)"; exit 1; } || echo "(--check: 백업본 최신)"
else
  echo "완료 → $OUT_DIR"
fi
