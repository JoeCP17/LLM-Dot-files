# LLM-Dot-files

Claude Code를 효과적으로 사용하기 위한 개인 설정, 스킬, 환경 구성을 관리하는 dotfiles 레포지토리입니다.

## Special Thanks 
[29CM 최현웅님](https://github.com/choi1204)
<br> 

[Ktown4u 백명석님](https://github.com/msbaek)

## 구조

```
LLM-Dot-files/
├── AGENTS.md                         # 이 레포에서 Codex가 읽는 관리 지시사항
├── homebrew/
│   └── Brewfile                      # brew 설치 패키지 목록
├── shell/
│   └── .zshrc                        # zsh 설정 (NVM, claude-squad 등)
├── cmux/
│   ├── README.md                     # cmux 설정/테마 복원 가이드
│   ├── cmux.json                     # ~/.config/cmux/cmux.json 백업
│   └── config.ghostty                # cmux 내장 Ghostty 테마
├── claude/
│   ├── CLAUDE.md                     # 글로벌 Claude 지시사항
│   ├── RTK.md                        # RTK 메타 커맨드 레퍼런스
│   ├── agents/                       # 커스텀 서브 에이전트 정의
│   │   ├── planner.md               # 설계/계획 수립
│   │   ├── coder.md                 # 구현/리팩토링
│   │   ├── debugger.md              # 버그 분석/수정
│   │   ├── researcher.md            # 조사/분석/문서화
│   │   └── reviewer.md              # 코드 리뷰/품질 검증
│   ├── rules/                        # 글로벌 규칙 (CLAUDE.md에서 @import)
│   │   ├── _meta-rule-authoring.md  # 룰 작성 골격·중복 점검·sync 절차 (메타 품질 게이트)
│   │   ├── behavioral-principles.md # Karpathy 1·2·3·4·10 — Think/Simplicity/Surgical/Goal/Read-errors
│   │   ├── korean-output-style.md   # Karpathy 5·6 — 콜론 종결 금지 + 신규 파일 한국어 헤더
│   │   ├── artifact-discipline.md   # Karpathy 7 — Plan + Checklist + Context Notes 3종 산출물
│   │   ├── agents.md                # 에이전트 자동 위임 결정 트리
│   │   ├── session-memory-search.md # 세션/메모리 검색 시 agf 강제 사용
│   │   ├── java-lsp-exploration.md  # Java 탐색 시 jdtls LSP 강제 사용
│   │   ├── hedwig-cg.md             # 로컬 코드 그래프 + 5-signal 하이브리드 검색
│   │   ├── token-optimization.md    # 출력 분리/결정론적 위임/U-curve 등 토큰 절약
│   │   ├── development-workflow.md  # 기능 개발 파이프라인 (Karpathy 8 — Run tests)
│   │   ├── git-workflow.md          # 커밋/PR 워크플로우 (Karpathy 9 — Semantic commits)
│   │   ├── performance.md           # 모델 선택/컨텍스트 전략
│   │   ├── coding-style.md          # 코딩 스타일 가이드
│   │   ├── patterns.md              # 공통 패턴
│   │   ├── security.md              # 보안 가이드
│   │   ├── testing.md               # 테스트 가이드
│   │   └── hooks.md                 # 훅 사용 가이드
│   ├── bin/
│   │   ├── bootstrap.sh             # 신규 PC 셋업 — Brewfile + Claude/Codex/cmux 일괄 적용 (15단계 멱등)
│   │   ├── register-mcps.sh         # claude/mcp/mcp.json → claude mcp add-json 일괄 등록
│   │   ├── install-plugins.sh       # claude/plugins/{installed,marketplaces}.json → 일괄 설치
│   │   ├── hedwig-cg-auto           # 중앙 DB 라우팅 래퍼 (per-repo 흔적 없음)
│   │   ├── rule-loop.sh             # 룰 검증 + 자동 fix 루프 (test→fix→test, 최대 3회)
│   │   ├── test-rule-harness.sh     # 룰 5단계 통합 검증 (정적/sync/import/hook end-to-end)
│   │   ├── check-md-rule.sh         # 룰 정적 검증 (골격·종결부호, warning-only)
│   │   └── fix-rule.sh              # 룰 자동 수정 (콜론 종결·골격 스텁)
│   ├── hooks/
│   │   └── rtk-rewrite.sh           # RTK 자동 재작성 훅
│   ├── settings/
│   │   ├── settings.json            # 플러그인, 훅 설정
│   │   └── settings.local.json      # 권한 화이트리스트
│   ├── mcp/                          # MCP 서버 설정 (secrets 제외)
│   ├── plugins/                      # 설치된 플러그인 lock (installed.json + marketplaces.json)
│   └── skills/
│       ├── superpowers/              # superpowers 플러그인 스킬 백업
│       ├── datadog-error-report/     # Datadog 에러 리포트 스킬
│       ├── daily-upgrade/            # brew/rtk 일일 업그레이드 스킬
│       ├── wrap/                     # 세션 작업 내용 메모리 저장 스킬
│       ├── commit/                   # Conventional Commits 자동 생성
│       ├── commit-push/              # 커밋 + 푸시 원스텝
│       ├── pr/                       # rebase + PR 생성
│       ├── obsidian-vault/           # Obsidian/마크다운 작업, markdown-oxide LSP 가이드
│       └── code-search-efficient/    # ast-grep/fd/rg/LSP 도구 선택 결정 트리
├── codex/
│   ├── README.md                     # Codex/OMX 설치 및 복원 가이드
│   ├── AGENTS.md                     # 글로벌 Codex 지시사항 백업
│   ├── config.toml                   # ~/.codex/config.toml 백업
│   ├── bin/install-oh-my-codex.sh    # Homebrew npm으로 OMX 설치
│   ├── mcp/README.md                 # Codex MCP 복원 명령어
│   ├── prompts/                      # Codex/OMX 역할 프롬프트
│   └── skills/                       # Codex 커스텀 스킬
│       ├── crew-plan/                # 계획 + 비판 + seed 저장
│       ├── crew-work/                # 구현 + 검증 + 리뷰 루프
│       ├── crew-review/              # 코드 리뷰 모드
│       ├── crew-flow/                # plan → work → review 통합 플로우
│       ├── crew-status/              # .codex/crew 상태 요약
│       ├── crew-cleanup/             # .codex/crew 상태 정리
│       ├── wrap/                     # Codex 세션 요약 저장
│       └── octo-patch/               # Claude Octo 플러그인 타임아웃 패치
└── docs/
    └── GUIDELINE.md                  # 항목 추가 가이드라인
```

## cmux 설정

`cmux/` 디렉터리는 cmux 앱 설정과 내장 Ghostty 터미널 테마를 백업합니다. 현재 테마는 `dark:Catppuccin Mocha`입니다.

```bash
# 수동 복원
mkdir -p ~/.config/cmux
cp ~/LLM-Dot-files/cmux/cmux.json ~/.config/cmux/cmux.json

mkdir -p ~/Library/Application\ Support/com.cmuxterm.app
cp ~/LLM-Dot-files/cmux/config.ghostty ~/Library/Application\ Support/com.cmuxterm.app/config.ghostty
```

상세 제외 대상은 [cmux/README.md](cmux/README.md)를 참고합니다. 런타임 세션, socket, 브라우저 히스토리, cache, plist는 백업하지 않습니다.

## 행동 원칙 룰 (Karpathy 10원칙 기반)

[Andrej Karpathy 스타일 CLAUDE.md](https://github.com/datajuny/andrej-karpathy-skills/blob/main/CLAUDE.md) 의 10원칙을 한국어 컨텍스트로 흡수해 4개 룰로 분리, 모든 세션에 자동 적용됩니다.

| 룰 | Karpathy 매핑 | 핵심 |
|----|--------------|------|
| `behavioral-principles.md` | 1·2·3·4·10 | Think Before Coding / Simplicity / Surgical Changes / Goal-Driven / Read Errors |
| `korean-output-style.md` | 5·6 | 한국어 문장 콜론 종결 금지 + 신규 소스 파일 한국어 헤더 |
| `artifact-discipline.md` | 7 | 비-trivial 작업은 Plan + Checklist + Context Notes 3종 산출물 먼저 |
| `_meta-rule-authoring.md` | (메타) | 새 룰 작성 시 골격·중복·sync 절차의 품질 게이트 |

추가로 `development-workflow.md` 4단계가 Karpathy 8(Run Tests Before Marking Complete) 를, `git-workflow.md` 가 Karpathy 9(Semantic Commits — 1 logical change per commit) 를 흡수합니다.

### 설치 — bootstrap.sh 가 자동 적용

별도 명령 불필요. `bootstrap.sh` 7단계 `[claude-rules]` 가 `rsync -a --delete` 로 `~/.claude/rules/` 에 일괄 동기화하며, `claude/CLAUDE.md` 의 `@import` 체인이 모든 룰을 자동 로드합니다.

```bash
# 새 PC — 부트스트랩 한 번이면 자동 적용
bash claude/bin/bootstrap.sh

# 기존 환경 — rules 만 즉시 다시 동기화하려면
bash claude/bin/bootstrap.sh --skip=brew --skip=shell --skip=claude-cli \
  --skip=claude-settings --skip=rtk --skip=claude-md \
  --skip=claude-agents --skip=claude-skills --skip=claude-plugins \
  --skip=claude-mcps --skip=codex-config --skip=codex-skills --skip=hedwig-cg

# 또는 수동
rsync -a --delete claude/rules/ ~/.claude/rules/
```

### 새 룰 추가 시 — 검증 하네스 5단

`claude/bin/` 의 4개 스크립트가 정적 검증부터 sync·import·hook end-to-end 까지 한 번에 점검합니다.

```bash
# 1. 룰 작성
vim claude/rules/my-new-rule.md

# 2. 통합 검증 + 자동 수정 (가장 흔한 진입점)
bash claude/bin/rule-loop.sh claude/rules/my-new-rule.md
#   ↳ 내부적으로 test-rule-harness.sh → fix-rule.sh → 재검증을 최대 3회 루프

# 3. (선택) 정적 검증만
bash claude/bin/check-md-rule.sh claude/rules/my-new-rule.md
```

자동 수정 범위 — 콜론 종결(`...:` → `....`), 골격 스텁(`> Purpose`, `## Tradeoff`, `## 안티패턴`) 삽입까지. 본문 내용은 절대 건드리지 않으므로 작성자가 `TODO:` 자리를 채워야 합니다. 검증 항목·면제 대상 등 상세는 `claude/rules/_meta-rule-authoring.md` 참고.

## 멀티 에이전트 리뷰 — Claude 작성 + Codex 교차 리뷰

**구도**. Claude(Opus) 가 코드/구성을 작성·수정하고 **Codex CLI(GPT-5.5)** 가 독립 모델로 교차 리뷰합니다. 두 모델은 학습 데이터·편향·맹점이 다르므로, 한 모델이 자기 출력을 자가리뷰할 때 빠지는 false-PASS 위험을 낮춥니다.

### 동작 흐름

```
[Claude Opus] coder 구현 → reviewer 자체 리뷰
                                │
                                ├─ production-bound? multi-file? 보안/결제? → YES
                                │
                                ▼
[Codex GPT-5.5] codex review --uncommitted -c sandbox_mode="read-only"
                                │
                                ▼
   양측 Findings 비교 → 합의/불일치 사용자에게 보고
                                │
                                ▼
   둘 다 PASS → push    /    한쪽 FAIL → 사용자 판단 후 fix → 재리뷰
```

자동 트리거 룰은 `claude/rules/agents.md` 의 "Cross-Agent Review" 섹션 — production-bound · multi-file · 보안 키워드 매치 · 사용자 명시 요청 중 하나라도 해당되면 Claude 가 **선제적으로** Codex 호출.

### 두 가지 사용 방식

**1. 자동 (룰 기반)** — Claude 가 트리거 조건 판단해서 알아서 호출. 사용자 명령 불필요.

**2. 슬래시 커맨드 (`/santa-loop`)** — `everything-claude-code` 플러그인 제공. dual-review convergence loop 까지 자동화 (둘 다 PASS 할 때까지 fix 사이클 최대 3회).

```
/santa-loop                    # uncommitted changes 대상
/santa-loop src/Payment.java   # 특정 파일
```

### 수동 호출 (Codex 단독)

```bash
# uncommitted 전체
codex review --uncommitted -c sandbox_mode="read-only"

# 특정 commit
codex review --commit <SHA> -c sandbox_mode="read-only"

# 브랜치 전체 (base 대비)
codex review --base main -c sandbox_mode="read-only"

# free-form prompt (특정 관심사)
codex exec --sandbox read-only "claude/bin/bootstrap.sh 의 멱등성·에러처리만 리뷰"
```

원칙 — 반드시 `sandbox_mode="read-only"` (또는 `--sandbox read-only`) 로 Codex 가 working tree 를 변경하지 않게 격리.

### 설치 — bootstrap.sh 가 자동 처리

별도 셋업 불필요. `bootstrap.sh` 가 다음을 모두 적용합니다.

| 단계 | 처리 내용 |
|------|----------|
| `[brew]` Brewfile | Codex CLI 본체 (`cask "codex"`) 설치 |
| `[claude-md]` + `[claude-rules]` | `agents.md` 의 Cross-Agent Review 룰을 `~/.claude/rules/` 에 동기화 |
| `[claude-plugins]` | `everything-claude-code` 플러그인 (`/santa-loop` 포함) 설치 |
| `[codex-config]` + `[codex-skills]` | `~/.codex/config.toml` (gpt-5.5 high reasoning), `~/.codex/AGENTS.md` (Claude 룰 import), reviewer 프롬프트 7개 복원 |

새 PC 후속 작업은 `codex login` 한 번뿐입니다.

### 설치 검증

```bash
which codex && codex --version              # codex-cli 0.130.0 이상
codex login status                           # "Logged in using ..." 출력
ls ~/.codex/skills/crew-review/SKILL.md      # crew-review 스킬 정상
ls ~/.codex/prompts/code-reviewer.md         # reviewer 프롬프트 정상

# 한 번 dry-run (작은 commit 으로 동작 확인)
codex review --commit HEAD -c sandbox_mode="read-only"
```

### 모델 독립성 보장

`codex/config.toml` 의 핵심 설정.

```toml
model = "gpt-5.5"
model_reasoning_effort = "high"

[profiles.fast]
model = "gpt-5.4-mini"

[profiles.default]
model = "gpt-5.5"
```

→ Claude Opus 와 **완전 다른 모델 패밀리** 이므로 동일 편향을 공유하지 않습니다 (santa-method 원칙).

### Codex 가 사용하는 리뷰 자산

`~/.codex/prompts/` 의 도메인별 reviewer 프롬프트 7개를 Codex 가 컨텍스트에 함께 로드합니다.

| 프롬프트 | 용도 |
|---------|------|
| `code-reviewer.md` | 일반 코드 리뷰 |
| `api-reviewer.md` | API 호환성·breaking change |
| `java-spring-reviewer.md` | Java/Spring 도메인 |
| `security-reviewer.md` | OWASP Top 10·secret leakage |
| `performance-reviewer.md` | N+1, 메모리 누수, hot path |
| `quality-reviewer.md` | 가독성·테스트 커버리지 |
| `style-reviewer.md` | 컨벤션·네이밍 |

추가로 `~/.codex/AGENTS.md` 가 `claude/rules/coding-style.md`, `git-workflow.md`, `security.md`, `java-lsp-exploration.md`, `token-optimization.md`, `korean-output-style.md` 를 import — **Codex 가 Claude 와 같은 코딩 기준으로 리뷰**합니다.

## RTK (Rust Token Killer)

LLM 토큰 소비를 **60-90% 절감**하는 CLI 프록시. PreToolUse 훅으로 Claude Code의 모든 Bash 커맨드를 자동 재작성합니다.

| 작업 | 절감률 |
|------|--------|
| git status/log/diff | -75~80% |
| cat/read 파일 | -70% |
| grep/rg 검색 | -80% |
| test/build | -80~90% |
| git add/commit/push | -92% |

```bash
rtk gain          # 토큰 절약 통계
rtk discover      # 놓친 절약 기회 분석
```

## agf (AI Agent Session Finder)

`agf`는 Claude Code / Codex / Gemini 등 로컬에 있는 **모든 에이전트 세션을 fuzzy 검색·재개**하는 CLI입니다. `claude/rules/session-memory-search.md`에 등록되어 있어, **"세션 찾아줘", "메모리 검색", "지난 대화 찾아줘"** 같은 요청이 들어오면 Claude가 자동으로 `agf`를 호출합니다.

```bash
agf <keyword>                      # fuzzy TUI 검색
agf resume <keyword>               # 최고 매치 세션 바로 재개
agf list --agent claude --limit 20 # 스크립트용 plain text 목록
agf list --format json             # JSON 파싱용
agf stats                          # 에이전트·프로젝트별 통계
agf watch                          # 실시간 세션 대시보드
```

설치: `brew install agf` (Brewfile에 포함). 자세한 트리거/안티패턴은 [session-memory-search.md](claude/rules/session-memory-search.md) 참고.

## Java LSP 기반 코드 탐색 (jdtls)

Claude Code 2.0.74+ 의 LSP 지원을 활용해 **Java 코드 탐색 시 `grep`/`find` 대신 Eclipse JDT Language Server**를 직접 호출합니다. `claude/rules/java-lsp-exploration.md` 규칙으로 강제되며, 정의/참조/호출 계층/심볼 검색이 IDE 수준 정확도로 수행됩니다.

### 제공 기능

| LSP 함수 | 용도 |
|----------|------|
| `workspaceSymbol` | 워크스페이스 전체에서 클래스/메서드 검색 |
| `documentSymbol` | 파일 내 심볼 트리 (Read 대체) |
| `goToDefinition` | 심볼 정의 위치 점프 |
| `goToImplementation` | 인터페이스/추상 메서드 → 구현체 |
| `findReferences` | 심볼의 모든 참조 찾기 |
| `incomingCalls` / `outgoingCalls` | 메서드 호출 계층 추적 |
| `hover` | 타입·시그니처·Javadoc 조회 |

### 설치

```bash
# 1. jdtls 바이너리 (Brewfile에 포함됨)
brew install jdtls

# 2. claude-code-lsps 마켓플레이스 등록
claude plugin marketplace add Piebald-AI/claude-code-lsps

# 3. jdtls 플러그인 설치 (반드시 claude-code-lsps 마켓플레이스 선택)
claude plugin install jdtls@claude-code-lsps

# 4. Claude Code 재시작 후 검증
claude plugin list | grep jdtls            # enabled 확인
```

> ⚠️ `jdtls-lsp@claude-plugins-official` 은 README만 있고 LSP 설정이 없으므로 **설치 금지**. 반드시 `@claude-code-lsps` 마켓플레이스 버전을 사용하세요.

### 다른 언어 LSP 추가

`claude-code-lsps` 마켓플레이스는 TypeScript(`vtsls`), Rust(`rust-analyzer`), Go(`gopls`), Python(`basedpyright`), Kotlin(`kotlin-lsp`) 등 다수 LSP를 제공합니다. 필요 시 `claude plugin install <name>@claude-code-lsps` 로 추가.

## hedwig-cg (로컬 코드 그래프 검색)

[`hedwig-cg`](https://github.com/hedwig-ai/hedwig-code-graph) 는 레포지토리에서 **5-signal 하이브리드 검색**(code vector + text vector + graph expansion + FTS5 keyword + community → RRF fusion → Cross-Encoder rerank)을 **100% 로컬**로 제공합니다. 수천 파일 규모 레포에서 Claude가 grep 루프 대신 먼저 "어느 파일부터 읽어야 하는지" 지도를 얻어 **토큰·시간을 절감**합니다.

### 중앙 DB 아키텍처 (per-repo `.hedwig-cg/` 없음)

`claude/bin/hedwig-cg-auto` 래퍼가 모든 호출을 **중앙 경로** (`$HEDWIG_CG_DB_ROOT`, 기본 `~/.hedwig-cg/dbs/<repo>/`) 로 라우팅합니다. 레포 작업 디렉토리는 그대로 깨끗하게 유지되고, 새 레포는 첫 검색 시 자동 빌드됩니다.

```bash
hedwig-cg-auto search "payment event consumer"   # 필요 시 자동 빌드 후 검색
hedwig-cg-auto where                             # 현재 레포 DB 경로/상태
hedwig-cg-auto list                              # 인덱싱된 모든 레포 목록
hedwig-cg-auto update                            # 증분 재빌드
hedwig-cg-auto rebuild                           # 풀 재빌드
hedwig-cg-auto clean                             # 이 레포 DB 삭제
```

환경변수:
- `HEDWIG_CG_DB_ROOT` — DB 저장 루트 (기본 `~/.hedwig-cg/dbs`)
- `HEDWIG_CG_AUTO_BUILD=0` — 자동 빌드 비활성
- `HEDWIG_CG_BUILD_ARGS` — 빌드 추가 인자 (e.g. `--max-file-size 200000`)

### 역할 분담

| 상황 | 1순위 |
|------|-------|
| Java 심볼 정확 탐색 (정의/참조/호출) | **LSP (jdtls)** |
| 아키텍처·도메인 탐색 (의미 기반) | **hedwig-cg-auto search** |
| 다중 모듈 기능 매핑 | **hedwig-cg-auto search** |
| 문자열·로그 | **rg** |
| 비-Java 레포 탐색 | **hedwig-cg-auto** + LSP |

상세: [claude/rules/hedwig-cg.md](claude/rules/hedwig-cg.md)

### 자동 최신화

`pull`/`checkout`/`rebase` 시 DB를 알아서 증분 갱신합니다 (기존 DB 있는 레포 한정, 백그라운드 ~4초).

- **전역 git 훅**: `claude/git-hooks/` (`post-merge`/`post-checkout`/`post-rewrite`) + `git config --global core.hooksPath`
- **Claude Code SessionStart 훅**: 세션 시작 시 동일 업데이트

임시 비활성화: `HEDWIG_CG_DISABLE_HOOK=1 git pull ...`

### 설치

```bash
brew install pipx                                          # 파이썬 격리 설치 도구
pipx install hedwig-cg                                      # 본체
pipx inject hedwig-cg mcp                                   # MCP 서버 옵셔널 의존성
ln -sf ~/LLM-Dot-files/claude/bin/hedwig-cg-auto ~/.local/bin/hedwig-cg-auto

# 자동 최신화 훅 활성화
git config --global core.hooksPath ~/LLM-Dot-files/claude/git-hooks

# 공식 Claude 통합 (Skill + 훅) — 전역
hedwig-cg claude install --scope user
```

## 토큰 최적화 (msbaek/dotfiles 패턴 차용)

[msbaek/dotfiles](https://github.com/msbaek/dotfiles) 의 `.claude/CLAUDE.md` 에서 검증된 토큰·컨텍스트 절약 패턴을 `claude/rules/token-optimization.md` 와 `claude/skills/code-search-efficient/`, `claude/skills/obsidian-vault/` 로 분리해 적용했습니다. RTK 훅이 **명령어 출력 단계**에서 토큰을 깎는 반면, 이 규칙/스킬은 **Claude의 행동·도구 선택 단계**에서 토큰을 깎습니다.

### 핵심 원칙 (rules/token-optimization.md)

| 원칙 | 효과 |
|------|------|
| **Output Offloading** | 2KB 이상 결과는 `/tmp/` 파일로 빼고 컨텍스트엔 경로+요약만 |
| **Deterministic Offload** | 카운트/파싱/반복 작업은 AI 대신 셸 스크립트로 |
| **U-shaped attention** | 중요 정보는 응답 시작/끝 (가운데 묻지 말 것) |
| **File Reading Safety** | 1000줄 이상 파일은 `offset/limit` 강제 |
| **Subagent Multiplier** | 멀티에이전트 ≈ 15× 토큰. 단일 에이전트+도구(~4×) 우선 |
| **Telephone-game 방지** | 서브에이전트 결과 재요약 금지 (50% 정보 손실) |
| **Anchored Compaction** | 80% 컨텍스트 도달 시 5섹션 증분 요약 (전체 재요약 금지) |

### 도구 우선순위 (skills/code-search-efficient)

```
Java 심볼     → jdtls LSP        (rules/java-lsp-exploration.md)
구조 패턴     → sg (ast-grep)   ← AST 매칭, 정규식보다 정확
텍스트 검색   → rg (Grep tool)
파일명        → fd / Glob
큰 파일 구조  → LSP documentSymbol → Read offset/limit fallback
백링크/마크다운 → markdown-oxide LSP / obsidian-vault skill
```

### 새로 설치된 CLI

| 도구 | 용도 |
|------|------|
| `fd` | `find` 대체. 빠르고 `.gitignore` 자동 존중 |
| `ast-grep` (`sg`) | AST 패턴 매칭. `sg --lang java -p '$x.foo($$$)'` 같은 구문 인식 검색·일괄 변환 |

Brewfile에 포함되어 새 PC에서 자동 설치됩니다.

### Obsidian/마크다운 (skills/obsidian-vault)

`markdown-oxide` LSP 우선, 미설치 시 `rg` fallback. Zettelkasten 폴더 구조(000-SLIPBOX/001-INBOX/...), Hierarchical tags, 토큰 절약 작업 패턴을 명문화했습니다. 실제 vault가 있을 때 자동으로 적용됩니다.

## 설치된 MCP 서버

| 서버 | 용도 |
|------|------|
| jetbrains | JetBrains IDE 연동 |
| github | GitHub 이슈/PR 조회 |
| atlassian | Jira, Confluence 연동 |
| mysql-mcp-server | AWS RDS MySQL 읽기 전용 |
| taskmaster-ai | AI 태스크 관리 |
| mcp-installer | MCP 설치 도우미 |
| sequential-thinking | 단계적 사고 지원 |
| browsermcp | 브라우저 자동화 |
| playwright | Playwright 브라우저 테스트 |
| context7 | 라이브러리 최신 문서 조회 |
| notion | Notion 연동 |
| datadog-mcp | Datadog 모니터링 조회 |

Codex MCP 복원 명령어는 [codex/mcp/README.md](codex/mcp/README.md)에 별도 정리했습니다.

## 설치된 플러그인

| 플러그인 | 설명 |
|----------|------|
| superpowers | TDD, 디버깅, 코드리뷰 등 개발 워크플로우 스킬 |
| msbaek-tdd | TDD Red/Green/Blue 사이클 관리 |

## 커스텀 스킬

| 스킬 | 설명 |
|------|------|
| datadog-error-report | Datadog 에러 현황 종합 리포트 생성 |
| daily-upgrade | brew 패키지 및 Claude Code 일일 업그레이드 |
| wrap | 세션 작업 내용을 메모리에 저장하여 다음 세션에서 컨텍스트 복원 |
| commit | Conventional Commits 형식의 커밋 메시지 자동 생성 |
| commit-push | 커밋 + 원격 푸시를 원스텝으로 처리 |
| pr | 현재 브랜치를 base에 rebase 후 GitHub PR 생성 |
| obsidian-vault | Obsidian/마크다운 작업, markdown-oxide LSP 우선, 토큰 절약 패턴 |
| code-search-efficient | 코드 탐색 시 ast-grep/fd/rg/LSP 도구 선택 결정 트리 |

## Codex 설정

`codex/` 디렉터리는 Claude 설정과 같은 목적의 Codex 백업입니다.

| 항목 | 설명 |
|------|------|
| `codex/README.md` | Codex CLI와 oh-my-codex(OMX) 설치/복원 가이드 |
| `codex/AGENTS.md` | `~/.codex/AGENTS.md`로 복원하는 전역 Codex 지시사항 |
| `codex/config.toml` | 모델, reasoning effort, trusted project 설정 백업 |
| `codex/bin/install-oh-my-codex.sh` | Homebrew Node/npm으로 `oh-my-codex`만 전역 설치 |
| `codex/prompts/` | `agent-workbench`에서 가져온 Codex/OMX 역할 프롬프트 |
| `codex/skills/crew-*` | 제공받은 `crew-*.md` 명령 문서를 Codex skill 형식으로 변환 |
| `codex/skills/wrap` | Codex 세션의 결정·검증·다음 작업을 `.codex/session-notes/`와 `.omx/notepad.md`에 저장 |
| `codex/skills/java-spring-workflow` | Java/Spring 구현·리뷰 규칙 기반 workflow |
| `codex/skills/jira-kickoff`, `mysql-read`, `pull-request` | Jira, DB read-only 조회, PR 자동화 workflow |
| `codex/skills/octo-patch` | 제공받은 `octo-patch.md`를 Codex skill 형식으로 변환 |

현재 로컬 `codex`는 Homebrew Cask(`/opt/homebrew/Caskroom/codex/0.130.0`)로 설치되어 있습니다. 따라서 `npm install -g @openai/codex oh-my-codex`는 `/opt/homebrew/bin/codex`와 충돌할 수 있으니 새 PC에서도 `brew install --cask codex`를 우선 사용하고, OMX는 `codex/bin/install-oh-my-codex.sh`로 `oh-my-codex`만 설치합니다.

## 커스텀 서브 에이전트

`claude/agents/`에 정의된 5개 에이전트는 `claude/rules/agents.md`의 결정 트리를 통해 **자동 위임**됩니다.

| 에이전트 | 역할 | 트리거 |
|----------|------|--------|
| **planner** | 설계/계획 수립 | 설계, 계획, PRD, ADR, 아키텍처, 이관 전략 |
| **coder** | 구현/리팩토링 | 구현, 추가, 만들어, 리팩토링, implement, refactor |
| **debugger** | 버그 분석/수정 | 왜 안 돼, 에러, CS, 장애, 배송ID 기반 조사 |
| **researcher** | 조사/분석/문서화 | 조사, 분석, 비교, 리포트, Datadog 트래픽 분석 |
| **reviewer** | 코드 리뷰/품질 검증 | 리뷰, PR 리뷰, 품질 검증, 보안 검토 (코드 변경 직후 자동) |

## 빠른 시작 (새 PC 세팅)

레포 clone 후 `bootstrap.sh` 한 번이면 15단계가 자동·멱등으로 적용됩니다 (Brewfile → shell → Claude CLI 검증 → settings → RTK 훅 → CLAUDE.md/rules/agents/skills → plugins → MCP → Codex → hedwig-cg → git 전역 훅 → cmux 설정/테마).

```bash
# 1. 레포 clone (원하는 경로로, 기본 추천 ~/Desktop)
git clone git@github.com:JoeCP17/LLM-Dot-files.git ~/Desktop/LLM-Dot-files

# 2. Claude Code CLI 네이티브 설치 (brew가 아닌 공식 스크립트)
curl -fsSL https://claude.ai/install.sh | sh

# 3. 부트스트랩 — 15단계 일괄 적용 (먼저 dry-run으로 계획 확인 권장)
bash ~/Desktop/LLM-Dot-files/claude/bin/bootstrap.sh --dry-run
bash ~/Desktop/LLM-Dot-files/claude/bin/bootstrap.sh
```

### bootstrap.sh 주요 옵션

```bash
bash claude/bin/bootstrap.sh --help            # 단계 ID 전체 목록 + 환경변수
bash claude/bin/bootstrap.sh --dry-run         # 실행 계획만 출력
bash claude/bin/bootstrap.sh --skip=brew       # 특정 단계 제외 (다중 지정 가능)
BASE_DIR=/path/to/repo bash …/bootstrap.sh     # repo 위치를 명시 (기본 자동 감지)
```

### 부분 실행 (개별 스크립트)

```bash
bash claude/bin/install-plugins.sh   # marketplace 6개 + plugin 5개 일괄 등록
bash claude/bin/register-mcps.sh     # MCP 서버 12개 일괄 등록 (누락 env 변수 사전 경고)
```

### secrets 환경변수 (MCP 호출 전 필요)

`register-mcps.sh` 가 사전 점검하지만 누락돼도 등록 자체는 성공합니다 — 실제 호출 시 실패. `~/.zshrc` 또는 1Password CLI 등에서 export 하세요.

| MCP 서버 | 필요 env |
|---------|---------|
| github | `GITHUB_PERSONAL_ACCESS_TOKEN` |
| notion | `NOTION_TOKEN` |
| datadog-mcp | `DD_API_KEY`, `DD_APPLICATION_KEY` |
| mysql-mcp-server | `MYSQL_HOSTNAME`, `MYSQL_SECRET_ARN`, `MYSQL_DATABASE`, `AWS_REGION` |

### 셋업 후 검증

```bash
source ~/.zshrc                # 새 셸 환경 적용
claude doctor                  # Claude 설정 정상 확인
claude plugin list             # 플러그인 5개 확인
claude mcp list                # MCP 서버 12개 확인
omx doctor                     # (선택) Codex/OMX 확인
```

### OMX 설치 (선택)

부트스트랩과 별도로, Codex 본체는 brew cask 로 깔고 OMX 만 npm 으로 설치합니다.

```bash
bash ~/Desktop/LLM-Dot-files/codex/bin/install-oh-my-codex.sh
omx setup --scope user --merge-agents --mcp none
```

## 가이드라인

항목별 추가 방법 → [docs/GUIDELINE.md](docs/GUIDELINE.md)
