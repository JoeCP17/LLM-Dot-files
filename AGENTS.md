# Repository Instructions

이 레포는 Claude Code와 Codex 설정을 백업하고 새 환경에 복원하기 위한 dotfiles 레포다.

## 편집 원칙

- 항목별 추가/수정 규칙은 `docs/GUIDELINE.md`를 먼저 확인한다.
- Claude 전용 설정은 `claude/` 아래에 둔다.
- Codex 전용 설정은 `codex/` 아래에 둔다.
- 전역 Codex 지시사항 백업은 `codex/AGENTS.md`에 유지한다.
- 실제 토큰, API 키, 인증 파일, 세션 DB, 로그, 캐시는 커밋하지 않는다. 원칙과 훅 목록은 `SECURITY.md`.
- `~/.claude/settings*.json` 은 `claude/bin/sanitize-settings.sh` 로만 백업한다. 직접 `cp` 하지 않는다.
- 개인 홈 절대경로(`/Users/<name>`) 대신 `$HOME` 또는 `~` 를 쓴다.
- Homebrew로 설치되는 도구는 `homebrew/Brewfile`에 반영한다.
- shell alias/function/PATH 변경은 `shell/.zshrc`에 반영한다.

## 검증

- Markdown 변경은 링크와 복원 명령이 현재 구조와 맞는지 확인한다.
- TOML·JSON·YAML 문법은 `pre-commit run --all-files` 가 검사한다. 커밋 시에는 전역 훅 래퍼가 자동 실행한다.
- 복원 스크립트(`bootstrap.sh`, `claude/bin/*`)를 바꿨으면 `claude/bin/verify-bootstrap.sh` 가 FAIL 0 인지 확인한다.
- 스킬 추가 시 각 `SKILL.md`에 `name`과 `description` frontmatter가 있는지 확인한다.
