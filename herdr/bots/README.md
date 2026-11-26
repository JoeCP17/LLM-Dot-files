# herdr-bots 개인 설정

> [herdr-bots](https://github.com/meengi07/herdr-bots) 설치부터 봇 생성, 권한, MCP, 예약까지 다른 PC 에서도 한 번에 같은 환경으로 맞추는 템플릿과 스크립트.

## 파일

| 파일 | 역할 |
|---|---|
| `setup.sh` | 한 번에 적용. herdr-bots 를 고정 커밋으로 받아 설치하고, `profiles/` 의 봇마다 아래를 모두 적용 |
| `apply.sh` | 공통 규칙과 기본 권한만 적용 (`setup.sh` 가 호출) |
| `RULES.local.md` | 모든 봇 공통 개인 규칙. `~/.herdr-bots/RULES.md` 끝 표시 구간에 들어감 |
| `settings.local.json` | 봇 기본 권한. 읽기 허용, 외부로 나가는 행동(push, MR 승인, Jira 쓰기, curl 등) 차단 |
| `profiles/<봇>/SOUL.md` | 봇 역할. 사내 값은 `${VAR}` 로 비워 둔 템플릿 |
| `profiles/<봇>/profile.env` | 이름, 에이전트, 모델, effort, 예약 |
| `profiles/<봇>/settings.extra.json` | 그 봇에만 더할 권한 (선택) |
| `values.example.env` | 템플릿에 채울 값의 예시 |

현재 봇은 두 개다.

| 봇 | 하는 일 | 예약 |
|---|---|---|
| `briefing` (브리핑 봇) | Datadog 운영 알림 요약, GitLab 리뷰 대기 목록 | 평일 10:00 |
| `weekly` (위클리 작성 봇) | Jira, Confluence 를 읽어 주간보고 작성용 md 를 vault 에 저장 | 없음 (요청할 때) |

## 새 PC 에서

```sh
# 1. 사내 값 파일 (레포 밖, 권한 600). 기존 PC 의 파일을 옮기거나 예시를 복사해 채운다
mkdir -p ~/.config/herdr-bots
cp herdr/bots/values.example.env ~/.config/herdr-bots/values.env && chmod 600 ~/.config/herdr-bots/values.env

# 2. bootstrap 이 herdr-bots 단계에서 setup.sh 를 실행한다. 따로 돌릴 때는
sh herdr/bots/setup.sh

# 3. 직접 할 일
claude auth login
pbpaste | glab auth login --hostname <GitLab 호스트> --stdin   # read_api 토큰을 복사해 둔 상태로
```

봇마다 처음 한 번은 채팅 창에서 폴더 신뢰 확인에 Yes 로 답한다.

## setup.sh 가 하는 일

1. herdr-bots 를 `~/.local/share/herdr-bots` 에 받아 고정 커밋(`HERDR_BOTS_REF`, 전체 SHA)으로 맞추고 `install.sh` 실행. 이미 받은 커밋이면 fetch 하지 않는다. 직접 고친 mod 는 `FORCE_MODS=1` 일 때만 덮어쓴다.
2. 봇마다 다음을 적용.
   - `herdr-bot new` (없을 때만), `apply.sh`. `settings.local.json` 이 있으면 템플릿 deny 만 합집합으로 더한다 (`FORCE_SETTINGS=1` 로 통째 교체, 누적 승인도 지워짐)
   - SOUL.md 렌더링. 마지막 렌더링 이후 직접 고치지 않았으면 새 템플릿으로 바꾸고, 고쳤으면 그대로 둔다 (`FORCE_SOUL=1` 로 덮어쓰기)
   - `settings.extra.json` 병합
   - 홈 폴더(`HERDR_BOTS_MCP_FROM`)에 local 범위로 등록된 MCP 를 봇 폴더에도 등록. 이미 있는 서버는 건드리지 않고, 원본이 0개면 경고
   - 이름, 모델, 예약. 프로필에서 예약을 비우면 해제
3. 레이아웃을 `bots` 로 전환 (앱이 꺼져 있으면 건너뜀).

여러 번 실행해도 결과가 같다. 봇 설정을 바꾼 뒤에는 `profiles/` 를 고치고 다시 실행한다.

## 봇 추가

`profiles/<새 봇>/` 에 `SOUL.md`, `profile.env` (필요하면 `settings.extra.json`) 를 만들고 `sh setup.sh <새 봇>`. 사내 값은 `${VAR}` 로 쓰고 `values.env` 와 `values.example.env` 에 키를 추가한다.

## 왜 이렇게 했나

- 레포가 공개 저장소라 GitLab 호스트, 계정, Confluence 스페이스, 이름, vault 경로는 `~/.config/herdr-bots/values.env` 에만 둔다.
- 권한은 `settings.json` 이 아니라 `settings.local.json` 에 둔다. `herdr-bot new`, `herdr-bot hooks`, `install.sh` 재실행이 봇 폴더의 `settings.json` 을 통째로 덮어쓰기 때문.
- `deny` 는 `auto` 권한 모드에서도 적용된다. 프롬프트 규칙이 뚫려도 막히는 실제 장치는 이쪽.
- MCP 는 요청대로 홈 폴더 것을 모두 복사하되, 외부로 내보낼 수 있는 서버(브라우저, IDE, MCP 설치기, Gmail, Slack, Google 문서류 등)와 쓰기 도구는 `deny` 로 막는다. 거부 목록 방식이라 새 MCP 를 추가하면 `settings.local.json` 의 deny 도 함께 검토한다.
- MCP 는 홈 폴더 전용(local 범위)으로 등록되어 있어 봇 폴더에서는 보이지 않는다. 그래서 봇 폴더마다 복사한다.

## 한계

- 봇이 `hc run` 으로 띄운 worker 는 worktree 에서 돌아서 봇 폴더의 `settings.local.json` 을 읽지 않는다.
- 봇 세션은 전역 `~/.claude` 규칙, 훅을 그대로 읽는다.
- 홈 폴더에 MCP 를 새로 추가하면 `setup.sh` 를 다시 실행해야 봇에도 들어간다.
- MCP 를 처음 복사할 때 설정 JSON 이 `claude mcp add-json` 인자로 넘어가 잠깐 프로세스 목록에 보인다. 이미 등록된 서버는 다시 넘기지 않는다.
- 권한이나 MCP 를 바꾼 뒤에는 `~/.herdr-bots/bin/herdr-bot restart <봇>` 으로 재시작해야 반영된다.

## 안티패턴

- ❌ 사내 값을 `profiles/` 에 그대로 쓰기 (공개 레포)
- ❌ 권한 설정을 봇 폴더 `settings.json` 에 직접 쓰기 (재설치 때 사라짐)
- ❌ `RULES.md` 의 금지 문구만 믿고 `deny` 를 비워 두기
- ❌ 검증하지 않은 upstream 커밋으로 `HERDR_BOTS_REF` 를 올리기
