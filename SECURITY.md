# Security Policy

> Purpose. 이 레포는 PUBLIC 이다. Claude Code·Codex 설정을 공개 저장소에 안전하게 유지하기 위한 원칙과 도구, 커밋 전 체크리스트.

## Tradeoff

가드가 늘수록 커밋이 번거로워진다. 대신 세션 키·사내 도메인·개인 경로가 한 번이라도 공개되면 되돌릴 수 없다. 오탐은 `.secrets.baseline` 에 기록해 관리하고, 가드를 우회(`--no-verify`)하는 일은 없어야 한다.

---

## 1. 커밋하지 않는 것

| 분류 | 예시 | 대체 방법 |
|---|---|---|
| 시크릿 | API 키, PAT, 세션 키, `auth.json`, `.credentials.json` | `claude/mcp/.env.example` 처럼 템플릿만. 실제 값은 `.env` |
| 사내 정보 | 사내 도메인·레지스트리·prod 네임스페이스·버킷명·DB 엔드포인트 | `settings.json` 의 `autoMode` 블록은 `sanitize-settings.sh` 가 제거. 그 외 위치(permissions.allow 의 도메인·명령 인자 등)는 자동으로 못 거르므로 **로컬 denylist**(아래 2절)에 등록 |
| 개인 경로 | `/Users/<name>/...` | `$HOME` 또는 `~`. 구조상 불가피한 파일은 `check-hardcoded-paths.sh` 허용 목록에 명시 |
| 생성 파일 | `fetch-claude-usage.swift` (Claude Usage 앱이 세션 키를 소스에 삽입) | `.gitignore` 등록. 새 PC 에서는 앱 재설치로 생성 |
| 런타임 상태 | 세션 DB, 로그, 캐시, `*.bak` | `.gitignore` |

## 2. 자동 가드

`pre-commit` 이 커밋마다 실행한다. 전역 `core.hooksPath` 의 `claude/git-hooks/pre-commit` 래퍼가 호출하므로 `pre-commit install` 은 하지 않는다(전역 훅과 충돌해 거부됨).

```bash
brew install pre-commit detect-secrets   # Brewfile 에 포함
pre-commit run --all-files               # 최초 1회 전체 검사
```

| 훅 | 역할 |
|---|---|
| `detect-secrets` | 고엔트로피 문자열·알려진 토큰 패턴 탐지. 오탐은 baseline 에 기록 |
| `detect-private-key` | PEM 등 개인키 본문 |
| `check-hardcoded-paths` | `/Users/<name>`·`/home/<name>` 절대경로 차단. 심볼릭 링크 대상 경로 포함. `codex/config.toml` 은 홈 루트·이 레포 trust 줄만 허용 |
| `check-sensitive-files` | 인증서·키 확장자, 실제 `.env`, `.netrc`/`.npmrc`/`.envrc`, SSH 개인키, 세션키 생성 파일 |
| `check-local-denylist` | `~/.config/llm-dotfiles/denylist.txt` 의 문자열(사내 도메인·네임스페이스·버킷명)이 있으면 차단. 목록은 레포 밖에만 둔다 |
| `check-settings-sanitized` | `claude/settings/*.json` 에 `autoMode` 잔존 여부 |
| `validate-hooks` | `settings.json` 훅이 가리키는 스크립트가 **레포 안에** 존재하는지 (로컬에만 있으면 실패) |
| `check-json` / `check-toml` / `check-yaml` | 설정 파일 문법 |

로컬 denylist 만들기. 한 줄에 한 문자열, `#` 주석 가능. 이 파일은 커밋하지 않는다.

```bash
mkdir -p ~/.config/llm-dotfiles
cat > ~/.config/llm-dotfiles/denylist.txt <<'EOT'
# 사내 도메인·레지스트리·prod 네임스페이스·버킷명을 여기에
EOT
```

오탐 처리.

```bash
detect-secrets scan --baseline .secrets.baseline      # baseline 갱신
detect-secrets audit .secrets.baseline                 # 항목별 true/false 표기
```

## 3. settings 백업 절차

`~/.claude/settings.json` 을 직접 `cp` 하지 않는다.

```bash
claude/bin/sanitize-settings.sh --check   # 차이만 보기 (차이 있으면 exit 1)
claude/bin/sanitize-settings.sh           # 정제 후 claude/settings/ 에 반영
```

정제 규칙(denylist 방식이라 Claude Code 가 새 키를 추가해도 백업에서 빠지지 않는다).

| 대상 | 규칙 | 이유 |
|---|---|---|
| `autoMode` | 삭제 | 머신 스캔 결과. 사내 도메인·prod 네임스페이스·버킷명 포함 |
| `.orca/agent-hooks` 참조 훅 | 삭제 | orca 앱이 설치 시 홈 절대경로로 다시 주입 |
| `env` 값 | 키 이름에 KEY/TOKEN/SECRET/PASSWORD/CREDENTIAL 이 있으면 `<redacted>` | 시크릿 유입 방지 |
| `source: directory` 마켓플레이스와 그 플러그인 | 삭제 | 로컬 디렉터리라 새 PC 에 없음 |
| `$HOME` | `~` 로 치환 | 개인 경로 제거 |
| `permissions.allow` 중 `/Users/` 잔존 항목 | 삭제 | 다른 머신 잔재 |

자동으로 못 거르는 것. `permissions.allow` 에 쌓이는 사내 도메인·명령 인자. 커밋 시 `check-local-denylist` 가 재검사하므로 denylist 를 채워 두어야 한다.

## 4. 커밋 전 체크리스트

- [ ] 새 파일에 토큰·도메인·경로가 없는가.
- [ ] 설정 파일이면 `.example` 템플릿이 필요한가.
- [ ] `pre-commit run --files $(git ls-files -c -o --exclude-standard)` 통과. `--all-files` 는 추적 파일만 검사해 신규 파일이 빠진다.
- [ ] `claude/bin/verify-bootstrap.sh` 가 FAIL 0 인가 (복원 스크립트를 건드렸을 때).

## 5. 이미 푸시된 시크릿 발견 시

1. 즉시 해당 키를 무효화한다. 세션 키는 claude.ai 로그아웃·재로그인.
2. `git filter-repo` 로 히스토리에서 제거 후 `--force-with-lease` 푸시. 절차는 `docs/GITHUB-SECURITY-SETUP.md`.
3. GitHub Security 탭의 알림을 닫는다.

## 다른 룰과의 관계

| 룰 | 관계 |
|---|---|
| `claude/rules/security.md` | 코드 작성 시 보안 원칙. 본 문서는 레포 운영 측 가드 |
| `claude/rules/prompt-injection-defense.md` | 데이터 영역의 exfiltration 요구 거부. 본 문서는 커밋 경로 차단 |
| `docs/GITHUB-SECURITY-SETUP.md` | GitHub 측 push protection 설정 |

## 안티패턴

- ❌ `SKIP=detect-secrets git commit`, `--no-verify`, `PRE_COMMIT_DISABLE_HOOK=1` 로 가드 우회 (이 레포는 require 마커라 마지막 것은 무시됨)
- ❌ `bootstrap.sh --skip=hedwig-cg` 로 전역 `core.hooksPath` 를 건너뛰기 (pre-commit 래퍼도 같이 꺼짐. 19단계가 경고함)
- ❌ `cp ~/.claude/settings.json claude/settings/` 직접 복사 (autoMode 유출)
- ❌ `fetch-claude-usage.swift` 를 "statusline 에 필요하니까" 백업
- ❌ 오탐을 baseline 에 넣지 않고 exclude 정규식으로 파일째 제외
