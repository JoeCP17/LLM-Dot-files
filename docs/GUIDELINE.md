# LLM-Dot-files 관리 가이드라인

## 디렉토리 구조

```
LLM-Dot-files/
├── AGENTS.md                         # 이 레포에서 Codex가 읽는 관리 지시사항
├── homebrew/
│   └── Brewfile                      # brew 설치 패키지 목록
├── shell/
│   └── .zshrc                        # zsh 설정 (alias, function, PATH, source 등)
├── cmux/
│   ├── README.md                     # cmux 설정/테마 복원 가이드
│   ├── cmux.json                     # cmux 앱 설정
│   └── config.ghostty                # cmux 내장 Ghostty 테마
├── claude/
│   ├── settings/
│   │   ├── settings.json             # Claude Code 전역 설정 (sanitize-settings.sh 로만 갱신)
│   │   └── settings.local.json       # Claude Code 권한 설정
│   ├── statusline/                   # statusline 스크립트·config 백업
│   ├── bin/
│   │   ├── bootstrap.sh              # 신규 PC 19단계 복원
│   │   ├── verify-bootstrap.sh       # 복원 결과 자동 판정
│   │   ├── sanitize-settings.sh      # settings 공개용 정제 백업
│   │   ├── validate-hooks.sh         # settings.json hook 참조 검사
│   │   └── pre-commit/               # 커밋 전 가드 스크립트
│   ├── mcp/
│   │   ├── mcp.json                  # MCP 서버 설정 (secrets 제외)
│   │   ├── .env.example              # 환경변수 템플릿
│   │   └── README.md                 # 복원 명령어 모음
│   ├── plugins/
│   │   └── README.md                 # 설치된 플러그인 목록 및 복원 방법
│   └── skills/
│       ├── superpowers/              # superpowers 플러그인 스킬 (자동 제공)
│       │   └── <skill-name>/SKILL.md
│       └── <custom-skill>/           # 직접 만든 커스텀 스킬
│           └── SKILL.md
├── codex/
│   ├── README.md                     # Codex/OMX 설치 및 복원 가이드
│   ├── AGENTS.md                     # Codex 전역 지시사항 백업
│   ├── config.toml                   # Codex 설정 백업
│   ├── bin/install-oh-my-codex.sh    # Homebrew npm으로 OMX 설치
│   ├── mcp/
│   │   └── README.md                 # Codex MCP 복원 명령어
│   ├── prompts/                      # Codex/OMX 역할 프롬프트
│   └── skills/
│       └── <custom-skill>/SKILL.md   # Codex 커스텀 스킬
├── .pre-commit-config.yaml           # 커밋 전 보안 가드 (SECURITY.md)
├── .secrets.baseline                 # detect-secrets 오탐 기록
├── SECURITY.md                       # 공개 레포 보안 원칙·훅 목록·체크리스트
└── docs/
    ├── GUIDELINE.md                  # 이 파일
    ├── GITHUB-SECURITY-SETUP.md      # push protection 설정·시크릿 유출 복구
    └── plans/                        # 이 레포 자체 개선 작업의 Plan/Checklist/Context Notes
```

---

## 항목별 추가 방법

### 1. brew 패키지 추가 시

`homebrew/Brewfile`에 항목 추가 후 커밋:

```bash
# Brewfile에 추가 예시
brew "패키지명"      # CLI 도구
cask "앱이름"        # GUI 앱

# 전체 복원 방법 (새 PC 세팅 시)
brew bundle install --file=~/LLM-Dot-files/homebrew/Brewfile
```

**규칙:**
- 설치 후 Brewfile에 바로 반영
- 주석으로 용도 설명 추가 (한 줄)
- formula / cask 섹션 구분 유지

---

### 2. zsh 설정 추가 시 (alias, function, source, PATH)

`shell/.zshrc`에 추가 후 커밋:

```bash
# 예시: 새 alias 추가
alias ll='ls -la'

# 예시: 새 source 추가
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# 예시: 새 PATH 추가
export PATH="$PATH:/new/path"
```

**규칙:**
- 섹션 주석(`# ---------------------------------------------------------------------------`) 유지
- 업무 관련 환경변수(DB 주소, 비밀번호 등)는 절대 포함하지 않음
- 변경 후 `source ~/.zshrc` 로 테스트 먼저

---

### 3. cmux 설정 변경 시

`cmux/cmux.json` 또는 `cmux/config.ghostty`에 반영 후 커밋:

```bash
# 실제 파일 위치
~/.config/cmux/cmux.json
~/Library/Application Support/com.cmuxterm.app/config.ghostty
```

**규칙:**
- 세션 상태, socket, 브라우저 히스토리, posthog/cache/log/plist 파일은 커밋하지 않음
- 테마는 `cmux/config.ghostty`에 저장
- cmux 앱 설정은 file-managed 값만 `cmux/cmux.json`에 명시하고 나머지는 앱 기본값 사용

---

### 4. MCP 서버 추가 시

**Step 1**: `claude/mcp/mcp.json`에 서버 항목 추가 (secrets는 `${ENV_VAR}` 형태로)

**Step 2**: 토큰이 필요하면 `claude/mcp/.env.example`에 변수명만 추가

**Step 3**: `claude/mcp/README.md`의 복원 명령어 섹션에 `claude mcp add ...` 명령 추가

```bash
# 예시: 토큰 없는 서버
claude mcp add <name> -s user -- npx -y <package>

# 예시: 토큰 필요한 서버
claude mcp add <name> -s user -e TOKEN=<your_token> -- npx -y <package>
```

**규칙:**
- 실제 토큰/API 키는 절대 커밋하지 않음 (`${PLACEHOLDER}` 사용)
- `.env.example`에 변수명과 설명만 기록

---

### 5. Claude 플러그인 추가 시

`claude/plugins/README.md`의 설치 플러그인 표에 항목 추가:

```bash
# 플러그인 설치
claude plugins install <plugin-name>
```

**규칙:**
- 공식 플러그인은 README에 기록만 (파일 복사 불필요)
- 플러그인이 제공하는 스킬 목록도 함께 업데이트

---

### 6. Claude 커스텀 스킬 추가 시

`claude/skills/<skill-name>/SKILL.md` 파일 추가 후 커밋:

```bash
# 실제 스킬 파일 위치: ~/.claude/skills/<skill-name>/SKILL.md
# LLM-Dot-files 레포에도 동일하게 복사

cp -r ~/.claude/skills/<new-skill> ~/LLM-Dot-files/claude/skills/
```

**규칙:**
- `claude/skills/superpowers/`는 플러그인 업데이트 시에만 갱신 (직접 수정 금지)
- 커스텀 스킬은 `claude/skills/<skill-name>/` 하위에 직접 추가
- 스킬 파일에 업무 기밀 정보 포함 금지

---

### 7. Claude 설정 변경 시

`~/.claude/settings*.json` 을 직접 `cp` 하지 않는다. 로컬 파일에는 `autoMode`(사내 도메인·prod 네임스페이스 포함) 와 앱이 주입한 절대경로 훅이 들어 있어 공개 레포에 올리면 안 된다.

```bash
claude/bin/sanitize-settings.sh --check   # 정제 결과와 백업본 차이만 확인
claude/bin/sanitize-settings.sh           # 정제 후 claude/settings/ 에 반영
```

정제 규칙과 이유는 `SECURITY.md` 3절, 커밋 시 `check-settings-sanitized`·`validate-hooks` 훅이 재검사한다.

statusline 을 바꿨으면 `claude/statusline/` 에 복사한다. `fetch-claude-usage.swift` 는 세션 키가 박힌 생성 파일이라 백업하지 않는다.

---

### 8. Codex 설정 변경 시

`codex/config.toml`, `codex/AGENTS.md`, `codex/skills/`를 수정 후 커밋:

```bash
# 실제 파일 위치
~/.codex/config.toml       → codex/config.toml
~/.codex/AGENTS.md         → codex/AGENTS.md
~/.codex/skills/<skill>/   → codex/skills/<skill>/
```

**규칙:**
- `auth.json`, 세션 DB, 로그, 캐시 파일은 절대 커밋하지 않음
- 전역 설정 복원은 명시적으로 `cp`할 때만 수행
- `codex/skills/<skill>/SKILL.md`는 Codex skill frontmatter(`name`, `description`)를 포함
- Claude slash command 문서를 가져올 때는 Claude hook 전용 경로를 그대로 복사하지 말고 Codex가 실행 가능한 workflow로 변환
- 세션 저장용 Codex 스킬은 `.codex/session-notes/`와 `.omx/notepad.md`처럼 프로젝트 로컬에 남는 경로를 우선 사용한다
- Codex 본체는 `cask "codex"`로 관리하고, `oh-my-codex`는 `codex/bin/install-oh-my-codex.sh`로 관리한다
- `@openai/codex` npm global 설치는 Homebrew Cask의 `/opt/homebrew/bin/codex`와 충돌할 수 있으므로 Brewfile에 추가하지 않는다
- MCP 토큰, DB endpoint, Secret ARN은 `codex/config.toml`에 직접 쓰지 않고 `codex/mcp/.env.example` 변수명으로만 남긴다

---

## 커밋 컨벤션

```
<type>: <what changed>

type:
  brew     - Brewfile 변경
  shell    - .zshrc 변경
  mcp      - MCP 서버 추가/변경
  plugin   - 플러그인 추가/변경
  skill    - Claude 스킬 추가/수정
  settings - Claude 설정 변경
  codex    - Codex 설정/스킬 변경
  docs     - 문서 변경
```

**예시:**
```
brew: add gh (GitHub CLI)
shell: add cs function for claude-squad
mcp: add notion MCP server
plugin: add superpowers v4.3.1
skill: add datadog-error-report skill
settings: allow mcp__github__get_file_contents permission
codex: add crew workflow skills
```

---

## 새 PC 세팅 시 복원 순서

```bash
# 1. 레포 클론
git clone https://github.com/JoeCP17/LLM-Dot-files.git ~/LLM-Dot-files

# 2. brew 패키지 일괄 설치
brew bundle install --file=~/LLM-Dot-files/homebrew/Brewfile

# 3. zshrc 적용
cat ~/LLM-Dot-files/shell/.zshrc >> ~/.zshrc && source ~/.zshrc

# 4. Claude 설정 복원 (bootstrap.sh 가 4·18단계에서 settings + statusline 을 함께 복원)
cp ~/LLM-Dot-files/claude/settings/settings.json ~/.claude/settings.json
cp ~/LLM-Dot-files/claude/settings/settings.local.json ~/.claude/settings.local.json

# 5. Claude 커스텀 스킬 복원 (superpowers 제외 - 플러그인 설치로 자동 제공)
cp -r ~/LLM-Dot-files/claude/skills/datadog-error-report ~/.claude/skills/

# 6. Claude 플러그인 설치
claude plugins install superpowers

# 7. Codex 설정 복원
mkdir -p ~/.codex/skills
cp ~/LLM-Dot-files/codex/AGENTS.md ~/.codex/AGENTS.md
cp ~/LLM-Dot-files/codex/config.toml ~/.codex/config.toml
cp -r ~/LLM-Dot-files/codex/skills/* ~/.codex/skills/

# 8. MCP 서버 등록
# claude/mcp/README.md의 복원 명령어 참고
# codex/mcp/README.md의 복원 명령어 참고
# 환경변수는 claude/mcp/.env.example을 복사해 실제 값 입력 후 사용
```
