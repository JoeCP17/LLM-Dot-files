# Plan: 공개 레포 보안 가드 + 복원 검증 (msbaek/dotfiles 비교 반영)

> Purpose. 2026-09-30 두 dotfiles 레포 비교 점검 결과 중 승인된 항목(P0 1~4, P1 5~6, statusline 백업)을 구현하는 계획.

## 목표

LLM-Dot-files 가 PUBLIC 레포로서 시크릿·사내 정보·개인 경로를 커밋하지 못하게 막고, 백업본이 실제로 복원되는지 자동 검증한다.

## 왜

- 레포에 자동 시크릿 검사가 0건. pre-commit·detect-secrets·gitleaks 모두 미설치였다.
- `claude/settings/settings.json` 백업본이 2026-05-11 상태로 멈춰 있었다. 존재하지 않는 agent-viz 훅 8개, 구 PC 홈 경로 statusLine 이 그대로 복원된다.
- 로컬 `~/.claude/settings.json` 의 `autoMode.environment` 에 사내 도메인·prod 네임스페이스·버킷명이 들어 있어 그대로 `cp` 하면 유출된다.
- `~/.claude/fetch-claude-usage.swift` 에 실제 세션 키가 하드코딩돼 있다. 백업 대상에서 반드시 제외해야 한다.
- statusline 스크립트가 백업·복원 어디에도 없어 새 PC 에서 statusline 이 동작하지 않는다.

## 범위

- [ ] P0-1 pre-commit + detect-secrets baseline + check-json/toml/yaml + large-files
- [ ] P0-2 개인 절대경로 차단 훅 + 기존 하드코딩 6파일 정리
- [ ] P0-3 settings.json sanitize 스크립트 + 커밋 전 검사
- [ ] P0-4 SECURITY.md + GitHub push protection 가이드
- [ ] P1-5 verify-bootstrap.sh (복원 후 자동 검증)
- [ ] P1-6 validate-hooks.sh (hook 참조 파일 존재·timeout·절대경로)
- [ ] statusline-command.sh + statusline-config.txt 백업 + bootstrap 단계
- [ ] 토큰 이점 항목 반영 (가이드 에이전트 검증 결과에 따라)

## 비범위 (이번에는 안 함)

- P1-7 `~/.config/git/ignore` 추적, P1-8 .gitignore 대량 보강, P1-9 agf config, P1-10 codex hooks.json 스냅샷 (다음 PR)
- update-brewfile pre-commit (공개 레포 유출 위험으로 보류)
- terminal-notifier 알림 훅 (cmux 사용 중)
- 커밋·푸시 (사용자 명시 승인 후 별도)

## 성공 기준

1. `pre-commit run --all-files` 통과.
2. `claude/bin/validate-hooks.sh --repo . claude/settings/settings.json` exit 0.
3. `claude/bin/verify-bootstrap.sh` 가 현재 머신에서 FAIL 0건.
4. `grep -rn '/Users/' --exclude-dir=.git .` 결과가 허용 목록(codex/config.toml, plugins lock 2개, 훅 스크립트 자체) 뿐.
5. reviewer 에이전트 + Codex 교차 리뷰에서 CRITICAL/HIGH 0건.
