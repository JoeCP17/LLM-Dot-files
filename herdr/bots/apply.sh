#!/bin/sh
# herdr-bots 설치 뒤 개인 규칙과 봇별 기본 권한을 덧입히는 스크립트
#   ./apply.sh                    모든 봇에 적용
#   ./apply.sh <봇> ...           지정한 봇에만 적용
#   FORCE_SETTINGS=1 ./apply.sh   settings.local.json 을 템플릿으로 통째로 덮어씀 (누적된 승인도 지워짐)
# 이미 있는 settings.local.json 은 유지하되 템플릿의 deny 는 매번 합집합으로 더한다.
set -eu

here=$(cd "$(dirname "$0")" && pwd)
bots_home=$HOME/.herdr-bots
rules=$bots_home/RULES.md
begin='<!-- owner-rules:begin -->'
end='<!-- owner-rules:end -->'

[ -f "$rules" ] || { echo "없음: $rules (herdr-bots 의 install.sh 를 먼저 실행)" >&2; exit 1; }
[ -f "$here/RULES.local.md" ] || { echo "없음: $here/RULES.local.md" >&2; exit 1; }

# RULES.md 의 표시 구간을 지우고 최신 개인 규칙을 다시 붙인다. 임시 파일에 쓴 뒤 교체해 중간 상태가 보이지 않게 한다.
tmp=$(mktemp "$rules.XXXXXX")
trap 'rm -f "$tmp"' EXIT
awk -v b="$begin" -v e="$end" '$0==b{skip=1;next} $0==e{skip=0;next} !skip' "$rules" |
  awk '{ lines[NR]=$0 } END { n=NR; while (n>0 && lines[n]=="") n--; for (i=1;i<=n;i++) print lines[i] }' > "$tmp"
{ printf '\n%s\n' "$begin"; cat "$here/RULES.local.md"; printf '%s\n' "$end"; } >> "$tmp"
mv "$tmp" "$rules"
echo "적용: $rules"

if [ $# -gt 0 ]; then bots=$*; else
  bots=$(for d in "$bots_home"/*/; do [ -f "$d/CLAUDE.md" ] && basename "$d"; done)
fi

for bot in $bots; do
  case $bot in *[!a-z0-9-]*|'') echo "봇 이름이 아님, 건너뜀: $bot" >&2; continue ;; esac
  [ -f "$bots_home/$bot/CLAUDE.md" ] || { echo "봇 아님, 건너뜀: $bot" >&2; continue; }
  dst=$bots_home/$bot/.claude/settings.local.json
  mkdir -p "$(dirname "$dst")"
  if [ ! -e "$dst" ] || [ "${FORCE_SETTINGS:-}" = 1 ]; then
    cp "$here/settings.local.json" "$dst"
    echo "적용: $dst"
    continue
  fi
  /usr/bin/python3 -I - "$here/settings.local.json" "$dst" <<'PY'
import json, os, sys
tmpl, dst = sys.argv[1], sys.argv[2]
want = json.load(open(tmpl, encoding="utf-8"))["permissions"]["deny"]
cur = json.load(open(dst, encoding="utf-8"))
deny = cur.setdefault("permissions", {}).setdefault("deny", [])
added = [d for d in want if d not in deny]
deny.extend(added)
if added:
    tmp = dst + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(cur, f, ensure_ascii=False, indent=2); f.write("\n")
    os.replace(tmp, dst)
print(f"유지, deny {len(added)}개 추가: {dst}")
PY
done
