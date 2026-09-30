# Context Notes: 공개 레포 보안 가드 + 복원 검증

> Purpose. 이 작업에서 내린 결정과 이유의 누적 로그. 결과만 적지 않고 왜 그렇게 했는지, 무엇을 기각했는지 남긴다.

## 2026-09-30 19:20

- **msbaek/dotfiles 의 pre-commit 구성을 거의 그대로 채택.** detect-secrets + pre-commit-hooks(v6.0.0) + 로컬 훅.
  - 이유. 이미 공개 dotfiles 에서 검증된 조합이고, 우리 `AGENTS.md` 의 "TOML 은 파서로 확인" 수동 규칙을 check-toml 이 자동화한다.
  - 기각. gitleaks 단독 사용. baseline 개념이 없어 오탐 관리가 불편하다.
- **로컬 훅은 `git diff --cached` 대신 pre-commit 이 넘겨주는 파일 인자를 쓴다.** dotfiles 원본은 `git diff --cached` 방식이지만, pre-commit 표준 방식이 `--all-files` 와 `files:` 필터에 자연스럽다.
- **개인 경로 패턴은 `/Users/[A-Za-z0-9._-]+` 로 일반화.** 특정 사용자명(구 PC 계정, 현재 계정)만 잡으면 다음 PC 에서 또 새 이름이 새어 들어온다.
  - 허용 예외. `codex/config.toml` 의 `[projects."..."]` 는 Codex trust 설정이라 절대경로가 필수. `claude/plugins/{installed,marketplaces}.json` 은 Claude 가 생성하는 lock 파일이고 `install-plugins.sh` 는 `id`·`name`·`repo` 만 읽으므로 경로 필드는 무해.
- **settings.json sanitize 는 denylist(`del(.autoMode)`) 방식.** allowlist 로 하면 Claude Code 가 새 최상위 키를 추가할 때마다 백업에서 빠진다.
  - `autoMode.environment` 는 Claude Code 의 auto 모드 환경 스캔 결과로 사내 GitLab·레지스트리·dev 백오피스 도메인·prod k8s 네임스페이스·버킷명이 들어 있다. 공개 레포에 절대 올리지 않는다. `soft_deny` 도 같은 블록에 있어 함께 빠지지만, 머신별 자동 재생성되므로 손실 아님.
  - `env`(ECC_GATEGUARD off, ECC_DISABLED_HOOKS) 는 토큰 절약 목적의 사용자 설정이라 유지.
  - `permissions.defaultMode: auto`, `theme` 도 유지. 사용자 선택값이며 민감하지 않다.
- **settings.local.json 의 `/Users/` 포함 permission 은 sanitize 가 버린다.** 구 PC 홈 경로를 가리키는 `cp` 허용 3줄이 그 예. 머신 종속이라 복원 가치가 없다.
- **`fetch-claude-usage.swift` 는 백업 제외 + .gitignore 등록.** Claude Usage 앱이 Keychain 의 claude.ai 세션 키를 소스에 직접 박아 넣는다. 세션 키는 API 키만큼 위험하다. statusline 의 usage 표시(SHOW_USAGE=1)는 이 파일이 있어야 동작하므로, 새 PC 에서는 Claude Usage 앱을 다시 설치해 생성한다. `claude/statusline/README.md` 에 명시.
  - 참고. 이 세션의 tool 출력에 키 값이 노출됐다. 키 자체를 무효화(claude.ai 로그아웃·재로그인)하는 것을 권장.
- **statusline 백업은 `cp -f` 로 복원.** settings 복원과 동일 정책. 사용자가 로컬에서 config 를 바꾸면 `sanitize-settings.sh` 처럼 레포로 되돌려 넣는 방향으로 통일.
- **bootstrap 단계는 17 → 19 로 끝에 추가.** 중간 삽입 시 번호 재정렬 diff 가 커진다. statusline·pre-commit 은 다른 단계에 의존하지 않는다.
- **커밋은 하지 않는다.** 사용자 규칙(푸시·커밋은 매번 명시 승인). end-of-file-fixer·trailing-whitespace 가 기존 md 를 대량 수정하면 별도 커밋으로 분리할지 사용자 판단.

## 2026-09-30 19:40

- **토큰 관련 env 변수는 반영하지 않음.** claude-code-guide 에이전트로 공식 문서 확인. `ENABLE_TOOL_SEARCH` 는 기본값이 이미 `auto`(MCP 도구 스키마 지연 로딩) 라 추가 설정 이점 없음. `ENABLE_LSP_TOOL`·`CLAUDE_CODE_MAX_OUTPUT_TOKENS`·`CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD` 는 공식 문서에 없어 근거 없이 넣지 않음. `MAX_THINKING_TOKENS` 는 문서화돼 있으나 품질 트레이드오프라 기본값 유지. 실질 토큰 이득은 백업본에 남아 있던 agent-viz 훅 8개(매 tool 호출마다 실행) 제거.
- **hook `timeout` 기본값은 600초** (공식 hooks 문서). validate-hooks 의 timeout 미지정 경고는 정보성. 우리 훅은 모두 수 초 내 종료되므로 값을 강제하지 않음.
- **statusLine 의 `~` 확장은 공식 문서에 명시 없음.** 훅 커맨드가 `~/.claude/hooks/...` 로 동작하는 실측을 근거로 같은 실행 경로라 판단. 복원 후 statusline 이 비면 `verify-bootstrap.sh` 6절이 경로를 확인.
- **sanitize 의 두 가지 함정.** (1) jq `.value |= map(A) | map(B)` 는 `(.value |= map(A)) | map(B)` 로 파싱돼 entry 객체에 B 가 적용됨 → 괄호 필수. (2) `set -e` + `pipefail` 에서 `diff | head -20` 은 head 가 먼저 닫히면 SIGPIPE 로 실패 처리돼 이후 `cp` 가 실행되지 않음 → `{ ...; } || true`. 첫 실행이 "변경:" 을 출력하고도 파일을 안 바꾼 원인.
- **로컬 settings.json 에는 orca 앱 훅 9개가 홈 절대경로로 주입돼 있음.** 도구가 설치 시 다시 넣으므로 sanitize 가 `.orca/agent-hooks` 참조 훅을 제거. 제거 후 백업본 훅은 3개(hedwig 업데이트·rtk 재작성·md-rule-guard).
- **`pre-commit install` 은 전역 `core.hooksPath` 와 충돌.** hedwig-cg 자동 최신화용 전역 훅 디렉토리가 잡혀 있어 pre-commit 이 `.git/hooks` 설치를 거부. 해결은 전역 훅 디렉토리에 `pre-commit` 래퍼를 두어 `.pre-commit-config.yaml` 이 있는 레포에서만 `pre-commit run` 을 실행하는 방식. `pre-commit install` 없이 모든 레포에 일괄 적용된다.
- **whitespace 훅이 기존 파일 18개를 손댔다.** superpowers 벤더 복사본·codex crew 스킬 등. 기능 변경 없음. 커밋 시 `chore: normalize whitespace` 로 분리 권장.
- **superpowers 벤더 복사본은 절대경로 검사 제외.** 원저자 예시 경로(업스트림 작성자 홈 경로)라 우리 정보가 아니고, 업스트림 갱신 시 diff 가 다시 생긴다.

## 2026-09-30 19:50 — reviewer 반영

- **Codex 교차 리뷰 불가.** 계정 models_cache 에 `gpt-5.5`·`codex-auto-review` 뿐이고 `gpt-5.5` 가 404. MCP 연결 로그에 `invalid_token`. `codex login` 재인증 또는 플랜 확인 후 `codex review --uncommitted -c sandbox_mode="read-only"` 재실행 필요. 이번 리뷰는 Claude reviewer 단독.
- **reviewer 결과 CRITICAL 0 · HIGH 3 · MEDIUM 7 · LOW 9.** HIGH 전부, MEDIUM 전부, LOW 중 L1·L2·L3·L4(일부)·L5·L6·L7·L8 반영.
  - H1 심볼릭 링크 우회 → `types_or: [text, symlink]` + `readlink` 검사. 사내 claude-package 로 향하는 링크를 백업하면 사용자명·사내 스킬명이 blob 으로 새는 경로였음.
  - H2 denylist 한계 → sanitize 에 env 값 redact·directory 마켓플레이스 제거 추가. permissions.allow 의 사내 도메인은 자동으로 못 거르므로 **레포 밖 로컬 denylist**(`~/.config/llm-dotfiles/denylist.txt`) 를 grep 하는 훅 추가. 목록 자체가 사내 정보라 레포에 두지 않음. allowlist 방식은 기각 — Claude Code 가 permission 형식을 바꿀 때마다 백업이 비게 됨.
  - H3 fail-open → 설정 파일의 `# require-pre-commit` 마커가 있는 레포는 CLI 없으면 exit 1, `PRE_COMMIT_DISABLE_HOOK` 도 무시. 다른 레포는 여전히 fail-open(다른 레포 커밋을 막지 않기 위해). bootstrap 19단계가 전역 hooksPath 일치를 확인.
  - M3 → 설정 파일 없는 레포에서는 레포 로컬 `.git/hooks/pre-commit` 을 exec. 전역 hooksPath 때문에 무시되던 lefthook 등을 되살림.
  - M5 → `codex/config.toml` 파일 단위 예외를 줄 단위로 축소. 홈 루트·이 레포 경로 trust 줄만 허용. 새 프로젝트를 열어 trust 가 늘면 커밋이 막히므로 그때 항목을 정리한다.
  - M1 → validate-hooks 정규식에 앞뒤 경계·`${HOME}`·`$CLAUDE_PROJECT_DIR` 스킵·확장자 확대. `--repo` 모드는 `~/.claude/*` 를 레포 매핑으로만 판정(로컬에만 있는 훅은 실패). 리뷰어가 제시한 오탐 6종 회귀 케이스 0건 확인.
  - M7 → `gitkraken` 마켓플레이스(`source: directory`)와 `gitkraken-hooks@gitkraken` 을 백업본에서 제거. `~` 확장 여부와 무관하게 새 PC 에 디렉터리가 없음.
  - L2 → `$HOME` 치환을 `$HOME/`·`$HOME"` 경계로 한정하고 치환을 먼저 한 뒤 `/Users/` 잔존 항목 삭제.
- **반영하지 않은 것.** L4 비ASCII 사용자명·바이너리 plist(현재 레포에 해당 파일 없음). L9 이전 커밋 히스토리의 구 PC 사용자명(`git filter-repo` 여부는 사용자 판단, 사용자명 수준이라 낮은 위험).
- **로컬 드리프트 2건(코드 변경 아님).** `~/.claude/settings.json` 의 `enabledPlugins` 에 `anthropic-agent-skills@anthropic-agent-skills`·`everything-claude-code@everything-claude-code` 가 true 인데 `claude plugin list` 에 없음(ecc 로 대체된 잔재). verify 가 WARN 으로 계속 알려줌. 정리는 사용자 몫.
- **MCP 스코프.** `register-mcps.sh` 가 `-s user` 없이 등록해 현재 머신에서 MCP 12개가 홈 디렉터리 프로젝트 스코프에만 있음. 새 PC 에서 bootstrap 을 다른 디렉터리에서 돌리면 MCP 가 안 보임. 이번 범위 밖, 다음 PR 후보.

## 2026-09-30 20:05

- **`pre-commit run --all-files` 는 추적 파일만 검사한다.** 신규(untracked) 파일은 빠져서 sanitize 주석·context-notes 의 예시 경로가 첫 커밋 시도에서 잡혔다. 커밋 전 전체 검사는 `pre-commit run --files $(git ls-files -c -o --exclude-standard)` 로 해야 신규 파일까지 포함된다. SECURITY.md 체크리스트에 반영.
