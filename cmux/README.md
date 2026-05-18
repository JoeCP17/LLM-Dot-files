# cmux 설정

cmux 앱 설정과 Ghostty 터미널 테마를 백업한다.

## 백업 대상

| 파일 | 복원 위치 | 설명 |
|------|-----------|------|
| `cmux.json` | `~/.config/cmux/cmux.json` | cmux JSONC 설정. file-managed 값만 명시하고 나머지는 앱 기본값 사용 |
| `config.ghostty` | `~/Library/Application Support/com.cmuxterm.app/config.ghostty` | cmux 내장 Ghostty 터미널 테마 |

## 제외 대상

- `~/Library/Application Support/cmux/session-*.json` — 런타임 세션 상태
- `~/Library/Application Support/cmux/cmux.sock` — 런타임 socket
- `~/Library/Application Support/com.cmuxterm.app/browser_history.json` — 브라우저 히스토리
- `posthog.*`, cache, log, plist — 사용자/런타임 상태

## 수동 복원

```bash
mkdir -p ~/.config/cmux
cp ~/LLM-Dot-files/cmux/cmux.json ~/.config/cmux/cmux.json

mkdir -p ~/Library/Application\ Support/com.cmuxterm.app
cp ~/LLM-Dot-files/cmux/config.ghostty ~/Library/Application\ Support/com.cmuxterm.app/config.ghostty
```

## 현재 테마

```text
theme = dark:Catppuccin Mocha
```

## OAuth 인증 시 외부 브라우저 사용 (Dia 등)

cmux 는 `PATH` 맨 앞에 `/Applications/cmux.app/Contents/Resources/bin` 을 주입해 `open` 명령을 자체 in-app 브라우저로 가로챈다. MCP OAuth (datadog-mcp, atlassian, 등) 처럼 인증 URL 을 시스템 브라우저에서 받아야 할 때 cmux pane 으로 빠져 들어가 인증 흐름이 끊긴다.

cmux 공식 escape hatch (open wrapper 스크립트에 내장되어 있음) 를 켜면 `open` 호출이 `/usr/bin/open` 으로 통과돼 시스템 default browser 로 열린다.

### 신규 PC 세팅 시 1회 실행

```bash
# 1. 패키지 (Brewfile 에 포함됨 — `brew bundle install` 했다면 skip)
brew install defaultbrowser duti

# 2. macOS default browser 를 Dia 로 설정
defaultbrowser dia
duti -s company.thebrowser.dia http
duti -s company.thebrowser.dia https
duti -s company.thebrowser.dia public.url
duti -s company.thebrowser.dia public.html

# 3. cmux 의 open wrapper 가로채기 해제 (앱 재시작 불필요)
defaults write com.cmuxterm.app browserInterceptTerminalOpenCommandInCmuxBrowser -bool false
defaults write com.cmuxterm.app browserOpenTerminalLinksInCmuxBrowser -bool false

# 4. 검증 — Dia 에서 열려야 정상
open https://example.com/test-dia
```

### 원복 (cmux in-app 브라우저로 되돌리기)

```bash
defaults delete com.cmuxterm.app browserInterceptTerminalOpenCommandInCmuxBrowser
defaults delete com.cmuxterm.app browserOpenTerminalLinksInCmuxBrowser
```

### 동작 원리 (참고)

cmux 의 `open` wrapper (`/Applications/cmux.app/Contents/Resources/bin/open`) 는 shell script 이며 다음 조건 중 하나라도 만족하면 `/usr/bin/open` 으로 통과시킨다.

- `CMUX_SOCKET_PATH` 가 unset (cmux 터미널 밖에서 실행)
- `defaults read com.cmuxterm.app browserDisabledOverride` = true
- `defaults read com.cmuxterm.app browserInterceptTerminalOpenCommandInCmuxBrowser` = false
- `defaults read com.cmuxterm.app browserOpenTerminalLinksInCmuxBrowser` = false

위 3번 단계는 마지막 두 키를 false 로 박아 in-app 가로채기를 끄는 방식.
