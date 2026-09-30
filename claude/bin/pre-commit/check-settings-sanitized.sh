#!/usr/bin/env bash
# pre-commit 훅 — claude/settings/*.json 백업본이 sanitize 를 거쳤는지 검사

# Usage: check-settings-sanitized.sh <settings.json> [...]
# 규칙: (1) 유효한 JSON (2) autoMode 키 없음 — 사내 도메인·네임스페이스가 들어가는 머신 스캔 결과
# Exit: 0 통과 / 1 위반
# Reference: claude/bin/sanitize-settings.sh

set -uo pipefail
command -v jq >/dev/null || { echo "jq 미설치 — brew install jq"; exit 1; }

status=0
for f in "$@"; do
  if ! jq empty "$f" 2>/dev/null; then
    echo "✗ $f — JSON 파싱 실패"
    status=1
    continue
  fi
  if [[ "$(jq 'has("autoMode")' "$f")" == "true" ]]; then
    echo "✗ $f — autoMode 블록이 남아 있습니다. claude/bin/sanitize-settings.sh 로 다시 생성하세요."
    status=1
  fi
done
exit $status
