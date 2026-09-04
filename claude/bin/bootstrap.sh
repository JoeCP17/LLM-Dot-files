#!/usr/bin/env bash
# 신규 PC 셋업용 LLM-Dot-files 부트스트랩 — Brewfile + Claude/Codex 설정을 멱등하게 일괄 적용

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="${BASE_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
PKG_SKILLS_DIR="${PKG_SKILLS_DIR:-$HOME/Desktop/claude-package/skills}"
PKG_SKILLS="${PKG_SKILLS:-daily-scrum front-ui-design}"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
CMUX_CONFIG_HOME="${CMUX_CONFIG_HOME:-$HOME/.config/cmux}"
CMUX_APP_SUPPORT="${CMUX_APP_SUPPORT:-$HOME/Library/Application Support/com.cmuxterm.app}"

DRY_RUN=0
SKIP_LIST=()
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --skip=*)  SKIP_LIST+=("${arg#--skip=}") ;;
    -h|--help)
      cat <<EOF
LLM-Dot-files Bootstrap — 신규 PC 셋업 자동화

사용법:
  bash $0 [--dry-run] [--skip=<step>] ...

옵션:
  --dry-run         실제 변경 없이 실행 계획만 출력
  --skip=<step>     특정 단계 건너뛰기 (다중 지정 가능)
  -h, --help        이 도움말

환경변수:
  BASE_DIR          레포 루트 (자동 감지, 현재: $BASE_DIR)
  CLAUDE_HOME       Claude 설정 경로 (기본: ~/.claude)
  CODEX_HOME        Codex 설정 경로 (기본: ~/.codex)
  CMUX_CONFIG_HOME  cmux 설정 경로 (기본: ~/.config/cmux)
  CMUX_APP_SUPPORT  cmux 앱 지원 경로 (기본: ~/Library/Application Support/com.cmuxterm.app)
  PKG_SKILLS_DIR    외부 스킬 패키지 경로 (기본: ~/Desktop/claude-package/skills)
  PKG_SKILLS        링크할 외부 스킬 이름 (공백 구분, 기본: daily-scrum front-ui-design)

단계 ID (--skip 인자로 사용):
  brew, shell, claude-cli, claude-settings, rtk,
  claude-md, claude-rules, claude-agents, claude-skills,
  claude-plugins, claude-mcps,
  codex-config, codex-skills, hedwig-cg, cmux,
  claude-bin, pkg-skills
EOF
      exit 0
      ;;
    *) echo "알 수 없는 인자: $arg" >&2; exit 1 ;;
  esac
done

# 색깔 로그
if [[ -t 1 ]]; then
  RED='\033[0;31m'; GRN='\033[0;32m'; YEL='\033[1;33m'; CYN='\033[0;36m'; NC='\033[0m'
else
  RED=''; GRN=''; YEL=''; CYN=''; NC=''
fi
log()  { echo -e "${CYN}[$(date +%H:%M:%S)]${NC} $*"; }
ok()   { echo -e "${GRN}✓${NC} $*"; }
warn() { echo -e "${YEL}⚠${NC} $*"; }
err()  { echo -e "${RED}✗${NC} $*" >&2; }

run() {
  if (( DRY_RUN )); then
    echo "    [DRY-RUN] $*"
  else
    eval "$@"
  fi
}

skip() {
  local s="$1"
  for sk in "${SKIP_LIST[@]:-}"; do
    [[ "$sk" == "$s" ]] && return 0
  done
  return 1
}

log "BASE_DIR=$BASE_DIR"
log "CLAUDE_HOME=$CLAUDE_HOME  CODEX_HOME=$CODEX_HOME  DRY_RUN=$DRY_RUN"
log "CMUX_CONFIG_HOME=$CMUX_CONFIG_HOME"
echo

# 1. brew bundle
if ! skip brew; then
  log "[1/17 brew] Brewfile 일괄 설치"
  if command -v brew >/dev/null; then
    run "brew bundle install --file=\"$BASE_DIR/homebrew/Brewfile\" || warn 'Brewfile 일부 실패 (위 로그 참고)'"
    ok "brew bundle 완료"
  else
    warn "brew 미설치 — https://brew.sh 참고. 건너뜀."
  fi
fi

# 2. shell/.zshrc 병합 (중복 방지 마커 사용)
if ! skip shell; then
  log "[2/17 shell] .zshrc 병합"
  local_zshrc="$BASE_DIR/shell/.zshrc"
  if [[ -f "$local_zshrc" ]]; then
    if [[ -f "$HOME/.zshrc" ]] && grep -q "# >>> LLM-Dot-files block >>>" "$HOME/.zshrc" 2>/dev/null; then
      ok ".zshrc 이미 병합됨 — skip"
    else
      run "printf '\n# >>> LLM-Dot-files block >>>\n' >> \"$HOME/.zshrc\""
      run "cat \"$local_zshrc\" >> \"$HOME/.zshrc\""
      run "printf '\n# <<< LLM-Dot-files block <<<\n' >> \"$HOME/.zshrc\""
      ok ".zshrc 병합 (source ~/.zshrc 또는 새 셸에서 활성화)"
    fi
  fi
fi

# 3. Claude Code CLI 설치 검증
if ! skip claude-cli; then
  log "[3/17 claude-cli] Claude Code CLI 확인"
  if command -v claude >/dev/null; then
    ok "claude CLI 사용 가능"
  else
    warn "Claude Code CLI 미설치 — 다음 명령으로 설치 후 재실행하세요."
    echo "    curl -fsSL https://claude.ai/install.sh | sh"
  fi
fi

# 4. Claude settings 복원
if ! skip claude-settings; then
  log "[4/17 claude-settings] settings.json + settings.local.json 복원"
  run "mkdir -p \"$CLAUDE_HOME\""
  [[ -f "$BASE_DIR/claude/settings/settings.json" ]] && \
    run "cp -f \"$BASE_DIR/claude/settings/settings.json\" \"$CLAUDE_HOME/settings.json\""
  [[ -f "$BASE_DIR/claude/settings/settings.local.json" ]] && \
    run "cp -f \"$BASE_DIR/claude/settings/settings.local.json\" \"$CLAUDE_HOME/settings.local.json\""
  ok "settings 복원 완료"
fi

# 5. RTK 글로벌 훅
if ! skip rtk; then
  log "[5/17 rtk] 글로벌 훅 초기화"
  if command -v rtk >/dev/null; then
    run "rtk init --global --auto-patch 2>/dev/null || warn 'rtk init 실패 — 이미 초기화된 상태일 수 있음'"
    ok "RTK 초기화 시도 완료"
  else
    warn "rtk 미설치 — Brewfile 단계 확인 후 재시도"
  fi
fi

# 6. CLAUDE.md + RTK.md
if ! skip claude-md; then
  log "[6/17 claude-md] CLAUDE.md + RTK.md 전역 동기화"
  run "cp -f \"$BASE_DIR/claude/CLAUDE.md\" \"$CLAUDE_HOME/CLAUDE.md\""
  run "cp -f \"$BASE_DIR/claude/RTK.md\" \"$CLAUDE_HOME/RTK.md\""
  ok "CLAUDE.md/RTK.md 동기화"
fi

# 7. rules/*.md
if ! skip claude-rules; then
  log "[7/17 claude-rules] rules/*.md 동기화 (rsync --delete)"
  run "mkdir -p \"$CLAUDE_HOME/rules\""
  run "rsync -a --delete \"$BASE_DIR/claude/rules/\" \"$CLAUDE_HOME/rules/\""
  ok "rules 동기화 완료"
fi

# 8. agents/*.md
if ! skip claude-agents; then
  log "[8/17 claude-agents] agents/*.md 동기화"
  run "mkdir -p \"$CLAUDE_HOME/agents\""
  run "rsync -a \"$BASE_DIR/claude/agents/\" \"$CLAUDE_HOME/agents/\""
  ok "agents 동기화 완료"
fi

# 9. skills/* (superpowers 제외 — 플러그인으로 따로 설치)
if ! skip claude-skills; then
  log "[9/17 claude-skills] skills/* 동기화 (superpowers 제외)"
  run "mkdir -p \"$CLAUDE_HOME/skills\""
  if [[ -d "$BASE_DIR/claude/skills" ]]; then
    for d in "$BASE_DIR"/claude/skills/*/; do
      [[ -d "$d" ]] || continue
      name=$(basename "$d")
      [[ "$name" == "superpowers" ]] && continue
      run "rsync -a \"$d\" \"$CLAUDE_HOME/skills/$name/\""
    done
  fi
  ok "skills 동기화 완료"
fi

# 10. 플러그인 일괄 설치 (install-plugins.sh 위임)
if ! skip claude-plugins; then
  log "[10/17 claude-plugins] 플러그인 일괄 설치"
  if (( DRY_RUN )); then
    echo "    [DRY-RUN] bash $SCRIPT_DIR/install-plugins.sh"
  else
    bash "$SCRIPT_DIR/install-plugins.sh" || warn "install-plugins.sh 일부 실패 (위 로그 확인)"
  fi
fi

# 11. MCP 서버 일괄 등록 (register-mcps.sh 위임)
if ! skip claude-mcps; then
  log "[11/17 claude-mcps] MCP 서버 일괄 등록"
  if (( DRY_RUN )); then
    echo "    [DRY-RUN] bash $SCRIPT_DIR/register-mcps.sh"
  else
    bash "$SCRIPT_DIR/register-mcps.sh" || warn "register-mcps.sh 일부 실패 (위 로그 확인)"
  fi
fi

# 12. Codex config.toml + AGENTS.md
if ! skip codex-config; then
  log "[12/17 codex-config] config.toml + AGENTS.md 복원"
  run "mkdir -p \"$CODEX_HOME\""
  [[ -f "$BASE_DIR/codex/config.toml" ]] && \
    run "cp -f \"$BASE_DIR/codex/config.toml\" \"$CODEX_HOME/config.toml\""
  [[ -f "$BASE_DIR/codex/AGENTS.md" ]] && \
    run "cp -f \"$BASE_DIR/codex/AGENTS.md\" \"$CODEX_HOME/AGENTS.md\""
  ok "Codex 설정 복원"
fi

# 13. Codex skills + prompts
if ! skip codex-skills; then
  log "[13/17 codex-skills] skills + prompts 동기화"
  run "mkdir -p \"$CODEX_HOME/skills\" \"$CODEX_HOME/prompts\""
  [[ -d "$BASE_DIR/codex/skills" ]] && \
    run "rsync -a \"$BASE_DIR/codex/skills/\" \"$CODEX_HOME/skills/\""
  [[ -d "$BASE_DIR/codex/prompts" ]] && \
    run "rsync -a \"$BASE_DIR/codex/prompts/\" \"$CODEX_HOME/prompts/\""
  ok "Codex skills/prompts 동기화"
fi

# 14. hedwig-cg 래퍼 + git 전역 훅
if ! skip hedwig-cg; then
  log "[14/17 hedwig-cg] 래퍼 심볼릭 링크 + git 전역 훅"
  if [[ -f "$BASE_DIR/claude/bin/hedwig-cg-auto" ]]; then
    run "mkdir -p \"$HOME/.local/bin\""
    run "ln -sf \"$BASE_DIR/claude/bin/hedwig-cg-auto\" \"$HOME/.local/bin/hedwig-cg-auto\""
    ok "hedwig-cg-auto 심볼릭 링크"
  fi
  if [[ -d "$BASE_DIR/claude/git-hooks" ]]; then
    run "git config --global core.hooksPath \"$BASE_DIR/claude/git-hooks\""
    ok "git 전역 훅 (core.hooksPath) 등록"
  fi
fi

# 15. cmux 설정 + Ghostty 테마
if ! skip cmux; then
  log "[15/17 cmux] cmux 설정 + Ghostty 테마 복원"
  if [[ -f "$BASE_DIR/cmux/cmux.json" ]]; then
    run "mkdir -p \"$CMUX_CONFIG_HOME\""
    run "cp -f \"$BASE_DIR/cmux/cmux.json\" \"$CMUX_CONFIG_HOME/cmux.json\""
    ok "cmux.json 복원"
  fi
  if [[ -f "$BASE_DIR/cmux/config.ghostty" ]]; then
    run "mkdir -p \"$CMUX_APP_SUPPORT\""
    run "cp -f \"$BASE_DIR/cmux/config.ghostty\" \"$CMUX_APP_SUPPORT/config.ghostty\""
    ok "cmux Ghostty 테마 복원"
  fi
fi

# 16. bin/* 룰 검증 스크립트 링크 (md-rule-guard 훅이 $CLAUDE_HOME/bin 에서 찾음)
if ! skip claude-bin; then
  log "[16/17 claude-bin] 룰 검증 스크립트 링크"
  run "mkdir -p \"$CLAUDE_HOME/bin\""
  for f in check-md-rule.sh _check-korean-colon.py; do
    if [[ -f "$BASE_DIR/claude/bin/$f" ]]; then
      run "ln -sfn \"$BASE_DIR/claude/bin/$f\" \"$CLAUDE_HOME/bin/$f\""
    else
      warn "claude/bin/$f 없음 — 건너뜀"
    fi
  done
  ok "검증 스크립트 링크 완료 (md-rule-guard 훅 활성화)"
fi

# 17. 외부 스킬 패키지 링크 (별도 레포로 관리 — 없으면 건너뜀)
if ! skip pkg-skills; then
  log "[17/17 pkg-skills] 외부 스킬 패키지 링크"
  if [[ -d "$PKG_SKILLS_DIR" ]]; then
    run "mkdir -p \"$CLAUDE_HOME/skills\""
    linked=0; missing=0
    for name in $PKG_SKILLS; do
      if [[ -d "$PKG_SKILLS_DIR/$name" ]]; then
        run "ln -sfn \"$PKG_SKILLS_DIR/$name\" \"$CLAUDE_HOME/skills/$name\""
        linked=$((linked + 1))
      else
        warn "$name 없음 — 건너뜀"
        missing=$((missing + 1))
      fi
    done
    ok "외부 스킬 ${linked}개 링크 (누락 ${missing}개)"
  else
    warn "$PKG_SKILLS_DIR 없음 — 건너뜀 (선택 사항)"
  fi
fi

echo
log "셋업 완료. 다음 명령으로 검증하세요."
echo "    source ~/.zshrc                   # 새 셸 환경 적용"
echo "    claude doctor                     # Claude 설정 정상 확인"
echo "    claude plugin list                # 플러그인 5개 확인"
echo "    claude mcp list                   # MCP 서버 확인"
echo "    omx doctor                        # (선택) Codex/OMX 확인"
