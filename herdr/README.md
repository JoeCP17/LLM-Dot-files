# herdr 설정

> cmux 에서 옮겨 온 Herdr 앱 설정(테마, 개인 설정)과 cmux 세션 이관 스크립트를 보관한다.

2026-11-26 부터 기본 터미널을 cmux 에서 Herdr 로 바꿨다. cmux 디렉터리는 원복용으로 남겨 둔다.

## 백업 대상

| 파일 | 복원 위치 | 설명 |
|------|-----------|------|
| `settings.json` | `~/.config/herdr-app/settings.json` | 개인 설정. 테마는 dark 에서 `catppuccin-mocha`, light 에서 `paper` |
| `themes/catppuccin-mocha.json` | `~/.config/herdr-app/themes/catppuccin-mocha.json` | cmux 에서 쓰던 Ghostty `Catppuccin Mocha` 팔레트를 Herdr 테마 형식으로 옮긴 것 |
| `migrate-from-cmux.py` | (복원 안 함, 직접 실행) | cmux 워크스페이스와 Claude 세션을 Herdr 스페이스로 옮기는 스크립트 |

`keys.json`, `layouts/` 는 기본값 그대로라 백업하지 않는다. 바꾸게 되면 그때 여기에 추가한다.

## 제외 대상

- `view.json`, `shared.json`, `window.json`, `seen.json`, `data/` — Herdr 가 쓰는 런타임 상태
- `AGENTS.md`, `*.d.ts`, `frame/`, `icons/` — 앱이 시작할 때마다 다시 쓰는 파일
- `herdr-app.sock`, `telemetry/`, `update-notes*` — 소켓, 사용 통계, 업데이트 기록

## 수동 복원

```bash
mkdir -p ~/.config/herdr-app/themes
cp ~/Documents/GitHub/LLM-Dot-files/herdr/settings.json ~/.config/herdr-app/settings.json
cp ~/Documents/GitHub/LLM-Dot-files/herdr/themes/catppuccin-mocha.json ~/.config/herdr-app/themes/
```

Herdr 는 파일을 바로 다시 읽는다. 잘못된 파일이면 `~/.config/herdr-app/settings.error` 에 이유가 남는다.

## cmux 세션 이관

cmux 의 워크스페이스 1개를 Herdr 스페이스 1개로 만들고, 분할 구조를 같은 방향으로 재현한 뒤 각 칸에서 `claude --resume <session>` 을 실행한다.

```bash
# 1. cmux 를 먼저 종료한다. 같은 세션을 두 앱에서 resume 하면 대화 기록이 꼬인다.
# 2. 만들 내용 확인
python3 -I ~/Documents/GitHub/LLM-Dot-files/herdr/migrate-from-cmux.py --dry-run
# 3. 실행 (Herdr 가 켜져 있어야 한다)
python3 -I ~/Documents/GitHub/LLM-Dot-files/herdr/migrate-from-cmux.py
```

- 읽는 파일은 `~/Library/Application Support/cmux/session-com.cmuxterm.app.json` 이다.
- 같은 이름의 스페이스가 이미 있으면 건너뛰므로 다시 실행해도 중복으로 만들지 않는다.
- 분할 비율은 복원하지 않는다. Herdr 는 화면에 보이는 칸만 크기를 바꿀 수 있어서 백그라운드로 만든 스페이스는 균등 분할로 열린다.

### 이관 직후 할 일 — 폴더 신뢰 확인

홈 폴더에서 새로 띄운 Claude 는 매번 "Yes, I trust this folder" 확인에서 멈춘다(`herdr-app ls` 의 status 가 `blocked`). 기본 선택이 "No, exit" 라서 Enter 만 보내면 Claude 가 종료된다.

```bash
hc keys <t> down        # "Yes, I trust this folder" 로 커서 이동
hc read <t> --lines 30  # '❯ Yes, I trust' 인지 확인한 뒤
hc keys <t> enter
```

`hc send <t> "2"` 는 쓰지 않는다. `hc send` 는 에이전트에게 보내는 메시지라 붙여 넣기와 `<hc from=...>` 표시가 붙어 선택지 입력이나 셸 명령으로 동작하지 않는다.

### 스페이스 재배치 — 실행 중인 Claude 를 그대로 옮기기

cmux 의 워크스페이스 단위보다 업무 영역 스페이스, 작업별 탭으로 묶는 편이 Herdr 사이드바와 에이전트 목록(`스페이스 · 탭` 으로 표시)에 맞는다. 프로세스를 다시 띄우지 않고 옮기는 방법은 다음과 같다.

```bash
herdr-app do terminal.park --terminal <t>                 # 칸만 떼어 냄, 프로세스는 계속 실행
hc label <t> herdr.space=<space id> herdr.tab=<tab id>    # 처음 보는 tab id 면 새 탭이 생김
herdr-app do tab.rename --id <tab id> --name "작업 이름"
herdr-app do tab.move --id <tab id> --index 1             # 라벨로 붙인 탭은 역순으로 들어가므로 정렬
```

화면에 있는 칸의 라벨만 바꾸면 이동하지 않는다. 반드시 `terminal.park` 다음에 라벨을 바꾼다.

## cmux 와 다른 점

| 항목 | cmux | Herdr |
|------|------|-------|
| 링크, `open` 명령 | 앱 내장 브라우저가 가로채서 `defaults write` 로 꺼야 했음 | 가로채지 않음. macOS 기본 브라우저(Dia)로 바로 열림 |
| Claude 상태 표시 | `--settings` 로 훅 주입 | 별도 설정 없이 인식 (`herdr-app ls` 의 `status`) |
| 터미널 유지 | 앱 종료 시 세션 파일로 resume | herdr-core(`hc`) 가 앱을 닫아도 터미널을 계속 실행 |
| 설정 조작 | GUI, `defaults` | `~/.config/herdr-app` 파일, `herdr-app do <command>` |

자주 쓰는 명령은 다음과 같다.

```bash
herdr-app ls                      # 스페이스, 탭, 터미널 목록
herdr-app status                  # 화면 상태와 설정 파일 오류
herdr-app commands                # 명령과 인자 전체
herdr-app do space.new --name "BALCONY-0000 작업" --argv '["claude"]'
hc ls                             # herdr-core 가 돌리는 터미널 목록
```

## 안티패턴

- ❌ cmux 를 켜 둔 채 이관 스크립트 실행 → 같은 Claude 세션을 두 프로세스가 동시에 씀
- ❌ `~/.config/herdr-app/AGENTS.md` 에 개인 메모 작성 → 앱이 시작할 때마다 덮어씀. 개인 메모는 `AGENTS.local.md`
- ❌ 기본 레이아웃(`layouts/main.json`)을 직접 수정 → `layout.clone` 으로 복제한 뒤 수정
