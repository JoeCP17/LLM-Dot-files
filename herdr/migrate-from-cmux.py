#!/usr/bin/env python3
# cmux 세션 파일의 워크스페이스와 분할 구조를 herdr 스페이스로 옮기고 Claude 세션을 resume 으로 다시 띄운다
"""
사용법
  python3 -I migrate-from-cmux.py --dry-run   # 만들 내용만 출력
  python3 -I migrate-from-cmux.py             # 실제 생성

전제
  - cmux 를 먼저 종료한다. 같은 Claude 세션을 두 곳에서 resume 하면 기록이 꼬인다.
  - herdr 앱이 실행 중이어야 한다 (herdr-app do 가 창에 명령을 보낸다).

동작
  - cmux 워크스페이스 1개 = herdr 스페이스 1개 (이름은 cmux 제목에서 '✳ ' 를 뗀 값)
  - cmux 분할 트리를 같은 방향으로 재현한다 (horizontal = 오른쪽, vertical = 아래)
  - Claude 패널은 `claude --resume <session>`, 그 외 패널은 기본 셸
  - 이미 같은 이름의 스페이스가 있으면 건너뛴다 (재실행해도 중복 생성 없음)
  - 분할 비율은 복원하지 않는다 (herdr 는 화면에 보이는 칸만 크기 조절 가능)
"""
import argparse
import json
import os
import subprocess
import sys
import time

SESSION_FILE = os.path.expanduser(
    "~/Library/Application Support/cmux/session-com.cmuxterm.app.json"
)
HERDR = os.path.expanduser("~/.local/bin/herdr-app")


def herdr(*args):
    out = subprocess.run([HERDR, *args], capture_output=True, text=True)
    data = json.loads(out.stdout or "{}")
    if out.returncode != 0 or "error" in data:
        raise RuntimeError(f"herdr-app {' '.join(args)} 실패: {data or out.stderr}")
    return data


def panel_argv(panel):
    term = panel.get("terminal") or {}
    binding = term.get("resumeBinding") or {}
    agent = term.get("agent") or {}
    kind = binding.get("kind") or agent.get("kind")
    session = binding.get("checkpointId") or agent.get("sessionId")
    if kind == "claude" and session:
        return ["claude", "--resume", session]
    return None


def panel_cwd(panel):
    term = panel.get("terminal") or {}
    binding = term.get("resumeBinding") or {}
    return binding.get("cwd") or term.get("workingDirectory") or panel.get("directory")


def leftmost(node):
    while "split" in node:
        node = node["split"]["first"]
    return node["pane"]["selectedPanelId"]


def build(node, pane, panels, dry):
    if "split" not in node:
        return
    split = node["split"]
    direction = "right" if split["orientation"] == "horizontal" else "down"
    second = panels[leftmost(split["second"])]
    argv = panel_argv(second)
    print(f"    split {direction}: {argv or 'shell'}")
    new_pane = "dry" if dry else herdr(
        "do", "pane.split", "--direction", direction, "--pane", pane,
        *(["--argv", json.dumps(argv)] if argv else []),
    )["pane"]
    build(split["first"], pane, panels, dry)
    build(split["second"], new_pane, panels, dry)


def pane_of(terminal):
    for space in herdr("ls")["spaces"]:
        for tab in space["tabs"]:
            for t in tab["terminals"]:
                if t["terminal"] == terminal:
                    return t["pane"]
    raise RuntimeError(f"{terminal} 의 pane 을 찾지 못함")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--session-file", default=SESSION_FILE)
    parser.add_argument("--delay", type=float, default=3.0, help="스페이스 사이 대기 초")
    args = parser.parse_args()

    session = json.load(open(args.session_file))
    existing = set() if args.dry_run else {s["name"] for s in herdr("ls")["spaces"]}

    for window in session["windows"]:
        for ws in window["tabManager"]["workspaces"]:
            name = (ws.get("customTitle") or ws["processTitle"]).lstrip("✳ ").strip()
            if name in existing:
                print(f"건너뜀 (이미 있음): {name}")
                continue
            panels = {p["id"]: p for p in ws["panels"]}
            first = panels[leftmost(ws["layout"])]
            argv = panel_argv(first)
            folder = panel_cwd(first) or os.path.expanduser("~")
            print(f"스페이스: {name}  ({folder})  {argv or 'shell'}")
            if args.dry_run:
                build(ws["layout"], "dry", panels, True)
                continue
            made = herdr(
                "do", "space.new", "--name", name, "--folder", folder, "--focus", "false",
                *(["--argv", json.dumps(argv)] if argv else []),
            )
            build(ws["layout"], pane_of(made["terminal"]), panels, False)
            time.sleep(args.delay)


if __name__ == "__main__":
    try:
        main()
    except RuntimeError as e:
        print(e, file=sys.stderr)
        sys.exit(1)
