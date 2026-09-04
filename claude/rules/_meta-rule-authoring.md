# Meta Rule — Rule Authoring

> Claude rule 마크다운 (`rules/*.md`, `agents/*.md`, `skills/**/SKILL.md`) 을 새로 만들거나 수정할 때 따라야 하는 골격과 절차. 본 룰은 다른 룰들의 **품질 게이트** 역할.

## Purpose

새 룰을 추가할 때 매번 형식·중복·일관성을 사람이 검수하면 비용이 큼. 이 파일이 정한 골격을 따르면 — 작성 시점에 자동 검증되고, 다음 사용자가 즉시 진입 가능.

이 파일 자체도 본 골격을 따릅니다 (eat your own dog food).

## Tradeoff

룰이 늘어날수록 일관성 비용이 커집니다. 본 메타 룰은 그 비용을 작성 시점에 회수합니다. 1회성 메모·개인 노트에는 적용 불필요.

---

## 1. 파일을 만들기 전 — 중복·교차 확인

**룰을 추가하기 전에** 반드시 점검합니다.

```bash
# 1. 비슷한 룰이 있나?
ls /Users/user/Documents/GitHub/LLM-Dot-files/claude/rules/
grep -l "<핵심 키워드>" /Users/user/Documents/GitHub/LLM-Dot-files/claude/rules/*.md

# 2. 글로벌에도 있나?
ls /Users/user/.claude/rules/

# 3. agents/ skills/ 에 같은 주제 있나?
grep -rli "<핵심 키워드>" /Users/user/Documents/GitHub/LLM-Dot-files/claude/{agents,skills}
```

판단 트리.

```
같은 주제 파일이 이미 있다
  │
  ├─ 90%+ 겹친다 → 새 파일 만들지 말고 기존 파일에 섹션 추가 (refactor)
  │
  ├─ 50~90% 겹친다 → 기존 파일을 surgical 보강 + cross-reference 추가
  │
  └─ <50% 겹친다 → 새 파일 OK, 단 기존 파일과의 관계를 "다른 룰과의 관계" 섹션에 명시
```

`behavioral-principles.md` 원칙 3 (Surgical Changes) 와 호환되는 의사결정입니다.

---

## 2. 필수 골격

모든 룰 파일은 아래 골격을 가집니다.

````markdown
# <Title>

> <Purpose 한 줄 — 무엇을 위한 룰이며 누가 언제 따라야 하나>

## Tradeoff
<언제 이 룰이 도움 되나, 언제 생략 가능한가>

---

## <원칙 1 제목>
**<원칙 한 줄 요약>**

<본문>

### Anti-example
<❌ BAD 예시>

### Good-example
<✅ GOOD 예시>

---

## 다른 룰과의 관계
| 룰 | 관계 |
|---|---|
| `<file>.md` | <어떻게 보강/배제하는지> |

## 안티패턴
- ❌ ...
- ❌ ...
````

**필수 요소**.
- `# <Title>` (한 줄, H1 한 개만)
- `> ` 로 시작하는 Purpose 인용구 (제목 바로 다음)
- `## Tradeoff` 섹션 — 이 룰을 따르는 비용/효익 명시
- 안티패턴 섹션 — ❌ 마커로 무엇을 하지 말지 명시

**선택 요소**.
- frontmatter (`---\npaths: ...\n---`) — 경로 한정 룰일 때만
- 다른 룰과의 관계 표 — 2개 이상 룰을 cross-reference 할 때
- 설치 검증 (`bash ... --version`) — 외부 도구 의존하는 룰일 때

---

## 3. 한국어 출력 스타일 준수

본 룰 파일도 사용자 응답이 한국어 컨텍스트이므로 — `korean-output-style.md` 를 따릅니다.

- 한국어 문장은 **마침표**로 종결 (`:` 종결 금지)
- 코드 블록 안의 한국어 주석은 자유 (코드 영역)
- 표·라벨·frontmatter 안의 `:` 는 OK

---

## 4. 검증 (자동 하네스)

룰 파일을 `Write`/`Edit` 하면 `claude/bin/check-md-rule.sh` 가 자동 실행되어 다음을 점검합니다.

| 항목 | 상태 |
|------|------|
| `# Title` 한 개 존재 | 경고 |
| `> Purpose` 인용구 존재 | 경고 |
| `## Tradeoff` 섹션 존재 | 경고 |
| 한국어 콜론 종결 | 경고 (warning-only 모드) |
| 안티패턴 섹션 (❌ 마커 ≥ 1개) | 경고 |

현재는 **warning-only** — 차단(blocking) 안 함. 인지 후 작성자가 자율 교정.

본 메타 룰 파일이 그 검증 항목의 정답지 역할을 합니다.

---

## 5. 글로벌 sync 절차

룰을 `LLM-Dot-files/claude/rules/` 에 추가/수정한 뒤 — 글로벌 (`~/.claude/`) 에도 반영해야 활성화됩니다.

```bash
# 단일 파일 sync
cp /Users/user/Documents/GitHub/LLM-Dot-files/claude/rules/<file>.md \
   /Users/user/.claude/rules/<file>.md

# 전체 rules sync (덮어쓰기)
rsync -av --delete \
  /Users/user/Documents/GitHub/LLM-Dot-files/claude/rules/ \
  /Users/user/.claude/rules/

# CLAUDE.md import 라인도 동기화
cp /Users/user/Documents/GitHub/LLM-Dot-files/claude/CLAUDE.md \
   /Users/user/.claude/CLAUDE.md
```

⚠️ **주의**. `~/.claude/` 는 모든 Claude Code 세션에 즉시 영향. 변경 후 새 세션에서 동작 확인.

---

## 6. 새 룰 추가 절차 (체크리스트)

`artifact-discipline.md` 의 Checklist 패턴을 적용.

- [ ] 위 1번 — 중복 확인 (grep, ls)
- [ ] 위 2번 — 골격에 맞춰 파일 작성
- [ ] `LLM-Dot-files/claude/CLAUDE.md` 에 `@rules/<file>.md` 추가 (글로벌 활성화 의도일 때)
- [ ] 위 5번 — `~/.claude/` 로 sync
- [ ] `claude/bin/rule-loop.sh <file>` 실행 — 5단계 통합 검증 + 자동 fix 루프 통과
- [ ] (선택) `claude/tests/run-tests.sh` — 검증기 회귀 점검
- [ ] `LLM-Dot-files` 에 commit — 메시지 prefix `rule:` (e.g. `rule: add korean-output-style`)

## 7. 자동화 도구

룰 추가/수정 시 사용하는 4개 스크립트.

| 도구 | 용도 | 호출 위치 |
|------|------|----------|
| `bin/check-md-rule.sh <file>` | 정적 검증 — 골격·종결부호 점검 (warning-only) | PostToolUse hook, 직접 호출 |
| `bin/test-rule-harness.sh <file>` | 5단계 통합 검증 — 정적/sync/import/hook end-to-end | 직접 호출, rule-loop가 호출 |
| `bin/fix-rule.sh <file>` | 자동 수정 — 콜론 종결·골격 스텁 (의미 수정은 안 함) | rule-loop가 호출 |
| `bin/rule-loop.sh <file>` | test → fix → test 최대 3회 루프 | 사용자 직접 호출 (가장 흔히 사용) |

### 사용 흐름

```bash
# 신규 룰 작성
vim ~/Documents/GitHub/LLM-Dot-files/claude/rules/my-new-rule.md

# 통합 검증 + 자동 수정 (가장 흔한 진입점)
bash ~/Documents/GitHub/LLM-Dot-files/claude/bin/rule-loop.sh \
  ~/Documents/GitHub/LLM-Dot-files/claude/rules/my-new-rule.md

# PASS면 commit, FAIL이면 stderr 안내 따라 수동 수정
```

### 자동 수정의 보수성

`fix-rule.sh` 는 **mechanical 결함만** 수정합니다 — 본문 내용은 절대 안 건드림.

- ✅ 자동 수정 가능 — 콜론 종결 → 마침표, 골격 스텁 삽입 (`> Purpose`/`## Tradeoff`/`## 안티패턴`)
- ❌ 자동 수정 불가 — 안티패턴 항목 본문 작성, 룰 충돌 해결, 의미적 일관성

스텁이 삽입되면 작성자가 `TODO:` 자리에 실제 내용을 채워야 합니다.

### Sandbox 테스트

본인 룰을 직접 건드리기 전 sandbox에서 시연 가능.

```bash
SANDBOX=/tmp/rule-sandbox-$$
mkdir -p "$SANDBOX/rules"
cp my-new-rule.md "$SANDBOX/rules/"
bash ~/Documents/GitHub/LLM-Dot-files/claude/bin/rule-loop.sh "$SANDBOX/rules/my-new-rule.md"
diff -u my-new-rule.md "$SANDBOX/rules/my-new-rule.md"   # 변경 확인
```

---

## 다른 룰과의 관계

| 룰 | 관계 |
|---|---|
| `behavioral-principles.md` | 본 룰은 원칙 3 (Surgical) 의 메타 적용 — 룰 작성 자체에 surgical 원칙 적용 |
| `korean-output-style.md` | 본 룰 작성 시 5·6번 적용 |
| `artifact-discipline.md` | 위 6번 체크리스트가 본 룰의 적용 사례 |
| `docs/GUIDELINE.md` | `GUIDELINE.md` 는 brew/zsh/MCP/plugin/skill/settings 추가 가이드 — 본 룰은 **rule** 추가 가이드 (보완 관계) |

---

## 안티패턴

- ❌ 새 룰 추가하면서 기존 룰과 중복 확인 안 함 → 14개 룰이 25개로 늘면서 어디에 뭐가 있는지 모르게 됨
- ❌ `> Purpose` 인용구 누락 → 다른 세션이 파일 첫 줄만 보고 목적 파악 불가
- ❌ `## Tradeoff` 섹션 빼고 "무조건 따라라" 식 톤 → 룰 충돌 시 사용자가 판단 못 함
- ❌ 안티패턴 섹션 없이 좋은 예시만 나열 → "안 되는 케이스"가 더 학습 효과 큼
- ❌ `LLM-Dot-files` 에만 추가하고 `~/.claude/` sync 누락 → 룰이 실제로 활성화 안 됨
- ❌ 본 메타 룰을 무시하고 자기 스타일로 새 룰 작성 → 다음 사용자가 매번 재학습
