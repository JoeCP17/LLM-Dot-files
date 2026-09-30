# statusline 백업

> Purpose. `~/.claude/statusline-command.sh` 와 `statusline-config.txt` 백업. `bootstrap.sh` 18단계가 `~/.claude/` 로 복원한다.

## 구성

| 파일 | 역할 |
|---|---|
| `statusline-command.sh` | `settings.json` 의 `statusLine.command` 가 실행하는 스크립트. 모델·디렉토리·브랜치·컨텍스트 사용률·usage 표시 |
| `statusline-config.txt` | 표시 항목·색상 토글 (`SHOW_*`, `ELEMENT_COLOR_*`) |

## 백업에서 제외한 것

`~/.claude/fetch-claude-usage.swift` 는 **백업하지 않는다**. Claude Usage 앱이 claude.ai 세션 키를 소스에 직접 삽입해 생성하는 파일이라 커밋하면 세션이 탈취된다. `.gitignore` 와 `check-sensitive-files.sh` 가 차단한다.

이 파일이 없으면 `SHOW_USAGE=1` 의 usage 바만 비고 나머지는 정상 동작한다. 새 PC 에서 usage 표시가 필요하면 Claude Usage 앱을 설치해 다시 생성한다.

## 수동 복원

```bash
cp claude/statusline/statusline-command.sh ~/.claude/
cp claude/statusline/statusline-config.txt ~/.claude/
chmod +x ~/.claude/statusline-command.sh
```

`settings.json` 의 `statusLine.command` 는 `bash ~/.claude/statusline-command.sh` 다. 훅 커맨드와 같은 방식으로 셸을 거쳐 실행되므로 `~` 가 확장된다. 복원 후 statusline 이 비어 있으면 `claude/bin/verify-bootstrap.sh` 로 경로를 확인한다.

## 로컬에서 config 를 바꿨을 때

```bash
cp ~/.claude/statusline-config.txt claude/statusline/statusline-config.txt
```
