#!/usr/bin/env bash
# pre-commit 훅 — 스테이징 파일에 개인 홈 절대경로(/Users/<name>, /home/<name>)가 있으면 커밋 차단

# Usage: pre-commit 이 스테이징 파일 목록을 인자로 넘김. 수동 실행은 파일 경로 나열.
# 검사 대상: 텍스트 파일 본문 + 심볼릭 링크의 대상 경로 (types_or: [text, symlink])
# Exit: 0 없음 / 1 발견
# Reference: SECURITY.md, docs/plans/2026-09-30-security-guard-and-verify/context-notes.md

set -uo pipefail

# 파일 단위 예외. Claude 플러그인 lock 파일(install-plugins.sh 는 id·name·repo 만 읽음), 이 스크립트 자신,
# claude/skills/superpowers/ 는 업스트림 플러그인 벤더 복사본이라 원저자 예시 경로를 그대로 둔다.
ALLOW_FILE_RE='^(claude/plugins/(installed|marketplaces)\.json|claude/bin/pre-commit/check-hardcoded-paths\.sh|claude/skills/superpowers/.*)$'
# 줄 단위 예외. codex/config.toml 의 trust 항목은 절대경로가 필수지만, 홈 루트와 이 레포 경로만 허용한다.
CODEX_TRUST_LINE_RE='^\[projects\."/Users/[A-Za-z0-9._-]+(/Documents/GitHub/LLM-Dot-files)?"\]$'
# /Users/<name>, /home/<name>, JSON 이스케이프(\/Users\/name) 모두 포착. /Users/Shared 는 시스템 경로라 제외.
PATTERN='(/|\\/)(Users|home)(/|\\/)[A-Za-z0-9._-]+'

status=0
for f in "$@"; do
  [[ "$f" =~ $ALLOW_FILE_RE ]] && continue
  if [[ -L "$f" ]]; then
    target="$(readlink "$f")"
    if grep -qE "$PATTERN" <<<"$target"; then
      echo "✗ $f — 심볼릭 링크 대상이 개인 절대경로입니다: $target"
      status=1
    fi
    continue
  fi
  [[ -f "$f" ]] || continue
  hits="$(grep -nE "$PATTERN" "$f" 2>/dev/null | grep -vE '(/|\\/)Users(/|\\/)Shared(/|\\/|$)' || true)"
  if [[ "$f" == "codex/config.toml" && -n "$hits" ]]; then
    hits="$(echo "$hits" | { grep -vE "^[0-9]+:${CODEX_TRUST_LINE_RE#^}" || true; })"
  fi
  [[ -z "$hits" ]] && continue
  echo "✗ $f — 개인 절대경로 발견. \$HOME 또는 ~ 로 바꾸세요."
  echo "$hits" | head -5 | sed 's/^/    /'
  status=1
done
exit $status
