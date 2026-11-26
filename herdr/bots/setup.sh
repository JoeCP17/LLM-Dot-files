#!/bin/sh
# herdr-bots 설치부터 봇 생성, 권한, MCP, 예약까지 한 번에 맞추는 스크립트 (여러 번 실행해도 같은 결과)
#   ./setup.sh                 설치와 profiles/ 의 모든 봇 적용
#   ./setup.sh <봇> ...        지정한 봇만 적용
#   FORCE_SOUL=1               직접 고친 SOUL.md 도 템플릿으로 덮어씀
#   FORCE_SETTINGS=1           settings.local.json 을 템플릿으로 통째로 덮어씀 (누적된 승인도 지워짐)
#   FORCE_MODS=1               직접 고친 Herdr mod, 레이아웃도 upstream 으로 덮어씀
set -eu

here=$(cd "$(dirname "$0")" && pwd)
values=${HERDR_BOTS_VALUES:-$HOME/.config/herdr-bots/values.env}
src=${HERDR_BOTS_SRC:-$HOME/.local/share/herdr-bots}
ref=${HERDR_BOTS_REF:-b1c48e98ea6d46ebebb7f1933453131115169a13}   # 동작을 확인한 upstream 커밋 (전체 SHA)
mcp_from=${HERDR_BOTS_MCP_FROM:-$HOME}   # 이 폴더에 local 범위로 등록된 MCP 를 봇 폴더로 복사
bots_home=$HOME/.herdr-bots
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
log=$(mktemp)
trap 'rm -f "$log"' EXIT

# 1. 준비물
for c in herdr-app hc claude git /usr/bin/python3; do
  command -v "$c" >/dev/null 2>&1 || { echo "없음: $c" >&2; exit 1; }
done
if [ ! -f "$values" ]; then
  mkdir -p "$(dirname "$values")"
  cp "$here/values.example.env" "$values"; chmod 600 "$values"
  echo "값 파일을 만들었습니다. 실제 값으로 고친 뒤 다시 실행하세요: $values" >&2
  exit 1
fi

# 2. herdr-bots 받기. 고정 커밋이 없을 때만 fetch 하고, 체크아웃 뒤 실제 커밋을 확인한다
[ -d "$src/.git" ] || git clone -q https://github.com/meengi07/herdr-bots.git "$src"
git -C "$src" cat-file -e "$ref^{commit}" 2>/dev/null || git -C "$src" fetch -q origin
git -C "$src" checkout -q --detach "$ref^{commit}"
[ "$(git -C "$src" rev-parse HEAD)" = "$ref" ] || { echo "herdr-bots 커밋 불일치: $ref" >&2; exit 1; }
force_mods=; [ "${FORCE_MODS:-}" = 1 ] && force_mods=--force
if ! "$src/install.sh" $force_mods > "$log" 2>&1; then
  cat "$log" >&2; echo "herdr-bots install.sh 실패" >&2; exit 1
fi
grep -E '^(skip|note)' "$log" || true

# 3. 봇별 적용
if [ $# -gt 0 ]; then bots=$*; else bots=$(ls "$here/profiles"); fi
for bot in $bots; do
  case $bot in *[!a-z0-9-]*|'') echo "봇 이름이 아님, 건너뜀: $bot" >&2; continue ;; esac
  prof=$here/profiles/$bot
  [ -f "$prof/profile.env" ] || { echo "프로필 없음, 건너뜀: $bot" >&2; continue; }
  BOT_TITLE=; BOT_AGENT=claude; BOT_MODEL=; BOT_EFFORT=; SCHEDULE_AT=; SCHEDULE_DAYS=; SCHEDULE_PROMPT=
  . "$prof/profile.env"
  [ -f "$bots_home/$bot/CLAUDE.md" ] || "$bots_home/bin/herdr-bot" new "$bot" "$BOT_AGENT" >/dev/null
  # 공통 규칙과 기본 권한 (settings.local.json 은 없을 때 복사, 있으면 deny 만 합집합)
  if ! "$here/apply.sh" "$bot" > "$log" 2>&1; then cat "$log" >&2; exit 1; fi
  grep -v 'RULES.md$' "$log" || true

  # SOUL.md 렌더링, settings.extra.json 병합, MCP 복사 (값 파일은 여기서만 읽는다)
  /usr/bin/python3 -I - "$values" "$prof" "$bots_home/$bot" "$mcp_from" "${FORCE_SOUL:-}" <<'PY'
import hashlib, json, os, pathlib, re, shlex, string, subprocess, sys
values_path, prof, home, mcp_from, force_soul = sys.argv[1:6]
prof, home = pathlib.Path(prof), pathlib.Path(home)
vals = {}
for line in open(values_path, encoding="utf-8"):
    line = line.strip()
    if line and not line.startswith("#"):
        k, v = line.split("=", 1); vals[k.strip()] = shlex.split(v)[0] if v.strip() else ""

VAR = re.compile(r"\$\{([A-Za-z_][A-Za-z0-9_]*)\}")
def render(text, name):
    missing = sorted({m for m in VAR.findall(text) if m not in vals})
    if missing:
        sys.exit(f"{home.name}/{name}: 값 파일에 없는 변수 {missing}")
    return VAR.sub(lambda m: vals[m.group(1)], text)

def write_atomic(path, text):
    tmp = path.with_name(path.name + ".tmp")
    tmp.write_text(text, encoding="utf-8"); os.replace(tmp, path)

sha = lambda s: hashlib.sha256(s.encode("utf-8")).hexdigest()

# SOUL.md. 마지막으로 렌더링한 해시와 같으면(직접 고치지 않았으면) 새 템플릿으로 바꾸고, 고쳤으면 유지한다
soul_t = prof / "SOUL.md"
if soul_t.exists():
    want = render(soul_t.read_text(encoding="utf-8"), "SOUL.md")
    soul, mark = home / "SOUL.md", home / ".soul.rendered.sha256"
    have = soul.read_text(encoding="utf-8") if soul.exists() else ""
    last = mark.read_text().strip() if mark.exists() else ""
    untouched = (not have) or "One sentence: what this bot is for." in have or sha(have) == last
    if have == want:
        print(f"{home.name}: SOUL.md 같음")
    elif untouched or force_soul == "1":
        write_atomic(soul, want); print(f"{home.name}: SOUL.md 적용")
    else:
        print(f"{home.name}: SOUL.md 를 직접 고친 상태라 유지 (FORCE_SOUL=1 로 덮어쓰기)")
    if soul.read_text(encoding="utf-8") == want:
        mark.write_text(sha(want) + "\n")

# 봇별 추가 권한. 파싱한 뒤 문자열 값만 치환하고 목록은 합집합으로 더한다
def subst(node):
    if isinstance(node, str): return render(node, "settings.extra.json")
    if isinstance(node, list): return [subst(x) for x in node]
    if isinstance(node, dict): return {k: subst(v) for k, v in node.items()}
    return node
extra_t, target = prof / "settings.extra.json", home / ".claude" / "settings.local.json"
if extra_t.exists():
    extra = subst(json.loads(extra_t.read_text(encoding="utf-8")))
    cur = json.loads(target.read_text(encoding="utf-8"))
    for key, items in extra.get("permissions", {}).items():
        lst = cur.setdefault("permissions", {}).setdefault(key, [])
        lst.extend(it for it in items if it not in lst)
    write_atomic(target, json.dumps(cur, ensure_ascii=False, indent=2) + "\n")
    print(f"{home.name}: 추가 권한 병합")

# MCP. 원본 폴더에 local 범위로 등록된 서버를 봇 폴더에도 등록한다. 이미 있는 서버는 건드리지 않는다
cfg_path = pathlib.Path.home() / ".claude.json"
cfg = json.loads(cfg_path.read_text(encoding="utf-8")) if cfg_path.exists() else {}
root = cfg.get("projects", {}).get(mcp_from, {}).get("mcpServers", {})
have = cfg.get("projects", {}).get(str(home), {}).get("mcpServers", {})
if not root:
    print(f"{home.name}: 경고. {mcp_from} 에 등록된 MCP 가 없어 복사하지 않음 (HERDR_BOTS_MCP_FROM 으로 원본 폴더 지정)")
else:
    added = []
    for name, spec in root.items():
        if name in have: continue
        r = subprocess.run(["claude", "mcp", "add-json", "-s", "local", name, json.dumps(spec)],
                           cwd=home, capture_output=True, text=True)
        added.append(name if r.returncode == 0 else f"{name}(실패)")
    print(f"{home.name}: MCP {len(root)}개 중 추가 {added or '없음'}")
PY

  [ -n "$BOT_TITLE" ] && "$bots_home/bin/botsdb" set-title "$bot" "$BOT_TITLE" >/dev/null
  [ -n "$BOT_MODEL" ] && "$bots_home/bin/botsdb" set-model "$bot" "$BOT_MODEL" "${BOT_EFFORT:-low}" "$BOT_AGENT" >/dev/null
  if [ -n "$SCHEDULE_AT" ]; then
    "$bots_home/bin/herdr-bot" schedule "$bot" "$SCHEDULE_AT" "$SCHEDULE_DAYS" "$SCHEDULE_PROMPT" >/dev/null
    echo "$bot: 예약 $SCHEDULE_DAYS $SCHEDULE_AT"
  elif [ -f "$HOME/Library/LaunchAgents/dev.herdr-bots.$bot.plist" ]; then
    "$bots_home/bin/herdr-bot" unschedule "$bot"
    echo "$bot: 예약 해제"
  fi
done

# 4. 레이아웃 (앱이 꺼져 있으면 건너뜀)
herdr-app do layout.switch '{"name":"bots"}' >/dev/null 2>&1 && echo "레이아웃: bots" || echo "레이아웃 전환 건너뜀 (Herdr 앱 실행 후 다시 실행)"

cat <<EOF

직접 할 일.
  claude auth login                                   # 봇이 쓰는 Claude 로그인
  pbpaste | glab auth login --hostname <GitLab 호스트> --stdin   # 리뷰 대기 조회용, read_api 토큰
  봇마다 처음 한 번 채팅 창에서 폴더 신뢰 확인에 Yes
EOF
