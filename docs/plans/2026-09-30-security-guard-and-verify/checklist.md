# Checklist: 공개 레포 보안 가드 + 복원 검증

> Purpose. plan.md 를 체크박스 단위로 분해한 진행 현황. 완료 항목은 지우지 않는다.

## Phase 0. 준비
- [x] 두 레포 구조·드리프트 비교 (2026-09-30 세션 1차 보고)
- [x] `brew install pre-commit detect-secrets`
- [x] Plan / Checklist / Context Notes 작성

## Phase 1. 훅 스크립트
- [x] `claude/bin/pre-commit/check-local-denylist.sh` (리뷰 H2 대안)
- [x] `claude/git-hooks/pre-commit` 전역 래퍼 (core.hooksPath 충돌 회피) + git-hooks/README
- [x] `claude/bin/pre-commit/check-hardcoded-paths.sh`
- [x] `claude/bin/pre-commit/check-sensitive-files.sh`
- [x] `claude/bin/pre-commit/check-settings-sanitized.sh`
- [x] `claude/bin/validate-hooks.sh`
- [x] `.pre-commit-config.yaml`
- [x] `.secrets.baseline` 생성 + 오탐 검토

## Phase 2. 백업·복원 스크립트
- [x] `claude/bin/sanitize-settings.sh`
- [x] `claude/settings/settings.json` sanitize 로 재생성 (agent-viz 제거·statusLine 경로 정정)
- [x] `claude/settings/settings.local.json` 재생성 (구 PC 경로 permission 3줄 제거)
- [x] `claude/statusline/` 백업 + README
- [x] `bootstrap.sh` 단계 추가 (statusline, pre-commit) + 마지막 안내에 verify 추가
- [x] `claude/bin/verify-bootstrap.sh`

## Phase 3. 문서·정리
- [x] `SECURITY.md`, `docs/GITHUB-SECURITY-SETUP.md`
- [x] `.gitignore` 보강 (세션키 생성 파일·백업본·인증서)
- [x] `homebrew/Brewfile` 에 pre-commit, detect-secrets
- [x] `_meta-rule-authoring.md` 절대경로 → `~` 로 정정 + `~/.claude/rules` 동기화
- [x] `README.md`, `docs/GUIDELINE.md`, `AGENTS.md` 갱신
- [x] 토큰 이점 항목 반영 (env 변수 검증 결과 반영) — 공식 문서 근거 없어 env 추가 없음, agent-viz 훅 8개 제거로 갈음

## Phase 4. 검증
- [x] `pre-commit run --all-files` PASS
- [x] `verify-bootstrap.sh` FAIL 0
- [x] reviewer 에이전트 리뷰 (HIGH 3·MEDIUM 7 반영, context-notes 19:50)
- [ ] Codex 교차 리뷰 (`codex review --uncommitted`) ← **차단: gpt-5.5 404, codex login 재인증 필요**
- [ ] 사용자 보고 후 커밋 승인 대기
