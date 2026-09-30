#!/usr/bin/env bash
# bootstrap 복원 결과를 자동 판정 — CLI·CLAUDE.md import·rules/agents/skills 동기화·hook 참조·statusline·플러그인·MCP·Codex

# Usage: verify-bootstrap.sh [--quick]
#   --quick  claude plugin list / claude mcp list 호출(수 초) 생략
# Exit: 0 FAIL 없음 / 1 FAIL 1건 이상. WARN 은 exit 에 영향 없음.
# Reference: msbaek/dotfiles bin/verify-fresh-clone.sh 의 "복원 후 자동 판정" 개념을 cp 기반 복원에 맞게 어댑테이션

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="${BASE_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
QUICK=0; [[ "${1:-}" == "--quick" ]] && QUICK=1

if [[ -t 1 ]]; then RED='\033[0;31m'; GRN='\033[0;32m'; YEL='\033[1;33m'; NC='\033[0m'; else RED=''; GRN=''; YEL=''; NC=''; fi
n_pass=0; n_fail=0; n_warn=0
pass() { n_pass=$((n_pass+1)); echo -e "${GRN}PASS${NC} $*"; }
fail() { n_fail=$((n_fail+1)); echo -e "${RED}FAIL${NC} $*"; }
warn() { n_warn=$((n_warn+1)); echo -e "${YEL}WARN${NC} $*"; }
section() { echo; echo "## $*"; }

section "1. CLI 도구"
for c in claude jq python3; do command -v "$c" >/dev/null && pass "$c" || fail "$c 없음"; done
for c in rtk agf hedwig-cg-auto codex pre-commit detect-secrets; do command -v "$c" >/dev/null && pass "$c" || warn "$c 없음 (선택)"; done

section "2. CLAUDE.md 와 @import"
if [[ -f "$CLAUDE_HOME/CLAUDE.md" ]]; then
  pass "CLAUDE.md 존재"
  while read -r imp; do
    [[ -f "$CLAUDE_HOME/$imp" ]] && pass "@$imp" || fail "@$imp 파일 없음"
  done < <(grep -oE '^@[^[:space:]]+' "$CLAUDE_HOME/CLAUDE.md" | sed 's/^@//')
else
  fail "CLAUDE.md 없음"
fi

section "3. rules / agents 동기화"
for d in rules agents; do
  for f in "$BASE_DIR"/claude/$d/*.md; do
    name="$(basename "$f")"
    if [[ ! -f "$CLAUDE_HOME/$d/$name" ]]; then fail "$d/$name 미복원"
    elif ! cmp -s "$f" "$CLAUDE_HOME/$d/$name"; then warn "$d/$name 레포와 다름"
    else n_pass=$((n_pass+1)); fi
  done
  echo "  $d: 레포 $(ls "$BASE_DIR"/claude/$d/*.md | wc -l | tr -d ' ')개 대조"
done

section "4. skills 동기화 (superpowers 제외)"
for d in "$BASE_DIR"/claude/skills/*/; do
  name="$(basename "$d")"; [[ "$name" == "superpowers" ]] && continue
  [[ -e "$CLAUDE_HOME/skills/$name" ]] && n_pass=$((n_pass+1)) || fail "skills/$name 미복원"
done
echo "  skills: $(ls -d "$BASE_DIR"/claude/skills/*/ | wc -l | tr -d ' ')개 대조"

section "5. settings.json 과 hook 참조"
if jq empty "$CLAUDE_HOME/settings.json" 2>/dev/null; then
  pass "settings.json 파싱"
  vh="$("$SCRIPT_DIR/validate-hooks.sh" "$CLAUDE_HOME/settings.json" 2>&1)"; vh_rc=$?
  echo "$vh" | grep -E '✗' | sed 's/^/  /'
  case $vh_rc in
    0) pass "hook 참조 파일 존재 ($(echo "$vh" | head -1))" ;;
    1) fail "hook 참조 파일 누락" ;;
    *) fail "validate-hooks 실행 실패: $(echo "$vh" | head -1)" ;;
  esac
  shopt -s nullglob
  for h in "$CLAUDE_HOME"/hooks/*.sh; do [[ -x "$h" ]] && n_pass=$((n_pass+1)) || warn "$(basename "$h") 실행 권한 없음"; done
  shopt -u nullglob
else
  fail "settings.json 파싱 실패 또는 없음"
fi

section "6. statusline"
sl="$(jq -r '.statusLine.command // empty' "$CLAUDE_HOME/settings.json" 2>/dev/null | grep -oE '(~|\$HOME|/)[^ ]+\.sh' | head -1)"
if [[ -z "$sl" ]]; then warn "statusLine 미설정"
else
  slp="${sl/#\~/$HOME}"; slp="${slp/#\$HOME/$HOME}"
  [[ -f "$slp" ]] && pass "statusline 스크립트 $sl" || fail "statusline 스크립트 없음: $sl"
  [[ -f "$CLAUDE_HOME/statusline-config.txt" ]] && pass "statusline-config.txt" || warn "statusline-config.txt 없음 (기본값 표시)"
  [[ -f "$CLAUDE_HOME/fetch-claude-usage.swift" ]] || warn "fetch-claude-usage.swift 없음 — usage 바 비어 있음 (Claude Usage 앱으로 생성, 백업 대상 아님)"
fi

section "7. 플러그인 / MCP"
if (( QUICK )); then warn "--quick: 플러그인·MCP 조회 생략"
else
  installed="$(claude plugin list --json 2>/dev/null | jq -r '.[] | select(.enabled) | .id' 2>/dev/null || true)"
  while read -r id; do
    echo "$installed" | grep -qx "$id" && n_pass=$((n_pass+1)) || warn "플러그인 $id 미설치/비활성"
  done < <(jq -r '.enabledPlugins | to_entries[] | select(.value) | .key' "$CLAUDE_HOME/settings.json" 2>/dev/null)
  # claude mcp list 는 cwd 프로젝트 스코프에 따라 결과가 달라지므로 ~/.claude.json 을 직접 읽는다 (user + 모든 project 스코프)
  registered="$(jq -r '[(.mcpServers // {} | keys[]), (.projects // {} | .[] | .mcpServers // {} | keys[])] | unique[]' "$HOME/.claude.json" 2>/dev/null || true)"
  while read -r name; do
    echo "$registered" | grep -qx "$name" && n_pass=$((n_pass+1)) || warn "MCP $name 미등록 (register-mcps.sh)"
  done < <(jq -r '.mcpServers | keys[]' "$BASE_DIR/claude/mcp/mcp.json")
  echo "  플러그인 $(jq '.enabledPlugins | map_values(select(.)) | length' "$CLAUDE_HOME/settings.json")개 · MCP $(jq '.mcpServers | length' "$BASE_DIR/claude/mcp/mcp.json")개 대조"
fi

section "8. Codex"
if [[ -f "$CODEX_HOME/config.toml" ]]; then
  if python3 -c "import tomllib,sys; tomllib.load(open(sys.argv[1],'rb'))" "$CODEX_HOME/config.toml" 2>/dev/null; then pass "codex config.toml 파싱"
  else warn "codex config.toml 파싱 실패 또는 python3<3.11"; fi
else warn "codex config.toml 없음"; fi
[[ -f "$CODEX_HOME/AGENTS.md" ]] && pass "codex AGENTS.md" || warn "codex AGENTS.md 없음"

section "9. pre-commit 가드"
hooks_path="$(git config --global --type=path --get core.hooksPath 2>/dev/null || true)"
if [[ -n "$hooks_path" ]]; then
  [[ -x "$hooks_path/pre-commit" ]] && pass "전역 훅 래퍼 $hooks_path/pre-commit" || fail "전역 core.hooksPath($hooks_path)에 pre-commit 래퍼 없음 — 레포 로컬 훅도 무시되는 상태"
elif [[ -x "$BASE_DIR/.git/hooks/pre-commit" ]]; then pass "레포 로컬 pre-commit 훅"
else warn "pre-commit 훅 없음 — bootstrap 14·19단계 확인"; fi

echo
echo "PASS $n_pass · WARN $n_warn · FAIL $n_fail"
(( n_fail == 0 )) || exit 1
