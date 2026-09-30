#!/usr/bin/env bash
# settings.json 의 hook 설정을 검증 — 참조 스크립트 존재·timeout 누락·개인 절대경로

# Usage: validate-hooks.sh [--repo <레포 루트>] <settings.json>
#   --repo 지정 시(백업본 검증) ~/.claude/<x> 참조는 <레포>/claude/<x> 에 있어야만 통과. 로컬 $HOME 에만 있으면 실패
#   미지정 시(복원된 실제 설정 검증) $HOME 기준으로 확인
# Exit: 0 통과 / 1 참조 파일 누락 / 2 인자·환경 오류
# Reference: msbaek/dotfiles harness roadmap Action 8 (validate-hooks) 어댑테이션

set -uo pipefail

REPO=""
if [[ "${1:-}" == "--repo" ]]; then
  [[ -n "${2:-}" && -d "$2" ]] || { echo "--repo 경로가 없거나 디렉터리가 아님: ${2:-}" >&2; exit 2; }
  REPO="$(cd "$2" && pwd)"; shift 2
fi
SETTINGS="${1:-}"
[[ -f "$SETTINGS" ]] || { echo "settings 파일 없음: $SETTINGS" >&2; exit 2; }
command -v python3 >/dev/null || { echo "python3 필요" >&2; exit 2; }

REPO="$REPO" python3 - "$SETTINGS" <<'PY'
import json, os, re, sys

path = sys.argv[1]
repo = os.environ.get("REPO") or None
home = os.path.expanduser("~")

with open(path) as f:
    data = json.load(f)

hooks = data.get("hooks", {}) or {}
errors, warnings, total = [], [], 0
EXTS = r"(?:sh|bash|py|js|mjs|cjs|ts|rb|swift)"
# 앞 경계: 단어·}·:·/ 뒤가 아닌 위치에서 시작. 뒤 경계: 확장자 뒤에 영숫자가 오면 다른 확장자.
token_re = re.compile(
    r'(?<![\w}:/])((?:~|\$HOME|\$\{HOME\}|\$CLAUDE_HOME|\$\{CLAUDE_HOME\}|/Users/[A-Za-z0-9._-]+)/[^\s"\'|;&<>()]+?\.' + EXTS + r')(?![A-Za-z0-9])'
)
skip_re = re.compile(r'\$\{?CLAUDE_PROJECT_DIR\}?|\$\{[^}]*\}')

def candidates(tok):
    """토큰을 실제 파일 경로 후보로 변환. --repo 모드에서 ~/.claude/* 는 레포 매핑만 인정."""
    t = re.sub(r'\$\{?(HOME|CLAUDE_HOME)\}?', '~' if 'CLAUDE_HOME' not in tok else '~/.claude', tok)
    t = t.replace('~/.claude/.claude/', '~/.claude/')
    if t.startswith("~/.claude/") and repo:
        return [os.path.join(repo, "claude", t[len("~/.claude/"):])]
    if t.startswith("~/"):
        return [os.path.join(home, t[2:])]
    return [t]

for event, groups in hooks.items():
    for g in groups or []:
        for h in g.get("hooks", []) or []:
            if h.get("type") != "command":
                continue
            total += 1
            cmd = h.get("command", "")
            label = f"{event}" + (f"[{g.get('matcher')}]" if g.get("matcher") else "")
            if "timeout" not in h:
                warnings.append(f"{label}: timeout 미지정 (기본 600s) — {cmd[:60]}")
            if re.search(r"/Users/[A-Za-z0-9._-]+", cmd):
                warnings.append(f"{label}: 개인 절대경로 사용 — {cmd[:60]}")
            for tok in token_re.findall(cmd):
                if skip_re.search(tok):
                    continue
                if any(os.path.exists(c) for c in candidates(tok)):
                    continue
                where = "레포" if (repo and tok.replace("$HOME", "~").startswith(("~/.claude/", "$CLAUDE_HOME"))) else "파일"
                errors.append(f"{label}: {where}에 참조 파일 없음 — {tok}")

print(f"hooks {total}개 검사 ({path})")
for w in warnings:
    print(f"  ⚠ {w}")
for e in errors:
    print(f"  ✗ {e}")
if not errors:
    print("  ✓ 참조 파일 모두 존재")
sys.exit(1 if errors else 0)
PY
