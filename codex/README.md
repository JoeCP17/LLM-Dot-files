# Codex 설정

이 디렉터리는 Codex CLI와 oh-my-codex(OMX) 설정을 백업하고 복원하기 위한 공간이다.

## 설치

Codex 본체는 Homebrew Cask로 설치한다.

```bash
brew install --cask codex
```

OMX는 npm global package로 설치한다. 먼저 Brewfile로 Codex CLI와 Homebrew Node/npm을 복원한다.

```bash
brew bundle install --file=~/LLM-Dot-files/homebrew/Brewfile
```

현재 환경처럼 `/opt/homebrew/bin/codex`가 이미 Homebrew Cask 설치본이면 `npm install -g @openai/codex oh-my-codex`를 그대로 실행하지 않는다. npm이 `codex` 바이너리를 덮어쓰려다 `EEXIST`로 실패할 수 있다. 수동 설치가 필요하면 `oh-my-codex`만 설치한다.

```bash
~/LLM-Dot-files/codex/bin/install-oh-my-codex.sh
```

## 복원

```bash
mkdir -p ~/.codex/skills
cp ~/LLM-Dot-files/codex/AGENTS.md ~/.codex/AGENTS.md
cp ~/LLM-Dot-files/codex/config.toml ~/.codex/config.toml
cp -r ~/LLM-Dot-files/codex/skills/* ~/.codex/skills/
cp -r ~/LLM-Dot-files/codex/prompts ~/.codex/prompts
```

## 세션 저장

Codex 대화 기록은 자동 저장되지만, Claude `/wrap`처럼 다음 세션에서 바로 읽기 쉬운 작업 요약이 필요하면 `wrap` 스킬을 사용한다. 이 스킬은 현재 세션의 완료 작업, 결정, 검증 결과, 다음 작업을 프로젝트 로컬 `.codex/session-notes/`에 저장하고, OMX 프로젝트에서는 `.omx/notepad.md`에도 짧은 링크를 남긴다.

MCP 환경변수는 [mcp/.env.example](mcp/.env.example)을 참고해 개인 shell profile이나 비공개 env 파일에 설정한다.

## OMX 초기화

OMX 설치 후 한 번 실행한다.

```bash
omx setup --scope user --merge-agents --mcp none
omx doctor
codex login status
omx exec --skip-git-repo-check -C . "Reply with exactly OMX-EXEC-OK"
```

기본 실행:

```bash
omx --madmax --high
```

tmux/HUD 없이 현재 터미널에서 직접 실행하려면:

```bash
omx --direct --yolo
```

## 주요 명령

- `$deep-interview "..."`: 요구사항과 경계가 모호할 때 명확화
- `$ralplan "..."`: 구현 계획과 tradeoff 승인
- `$ralph "..."`: 승인된 계획을 끝까지 수행
- `$team 3:executor "..."`: 병렬 실행이 필요한 작업 수행
- `omx update`: npm 업데이트 확인 후 setup refresh
- `omx doctor`: OMX 설치 상태 점검

## 가져온 agent-workbench 설정

`~/Desktop/ktown4u-project/agent-workbench`에서 검증된 Codex 설정을 참고해 다음을 반영했다.

- `codex/prompts/`: OMX/Codex 역할 프롬프트
- `codex/skills/`: commit, PR, Jira kickoff, Java/Spring workflow, MySQL read 등 custom skills
- `codex/config.toml`: MCP 서버 정의와 high-reasoning 기본값
- `codex/mcp/.env.example`: 토큰과 DB 접속 정보를 커밋하지 않기 위한 환경변수 템플릿
