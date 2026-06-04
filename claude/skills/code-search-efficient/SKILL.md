---
name: code-search-efficient
description: |
  코드 분석/탐색 시 토큰을 최소화하면서 정확도를 최대화하는 도구 선택과 검색 전략. ast-grep(sg)
  구문 인식 검색, ripgrep, fd, LSP, Glob의 우선순위·조합 가이드. 코드 검색, 심볼 탐색,
  리팩토링, 패턴 찾기, "어디서 쓰이는지", "구현체 찾아줘" 등의 요청 시 자동 적용.
  출처: msbaek/dotfiles `<tool_preferences>` 패턴을 로컬 환경에 어댑테이션.
---

# Efficient Code Search

## 도구 우선순위 (Decision Tree)

```
질문이 들어옴
  │
  ├─ 언어가 Java인가? ──── YES ──► jdtls LSP (rules/java-lsp-exploration.md)
  │
  ├─ 언어가 Kotlin(.kt/.kts)인가? ──── YES ──► kotlin-lsp (rules/kotlin-lsp-exploration.md)
  │
  ├─ 구조적 매칭 필요?  (메서드 시그니처, 데코레이터,  ──► sg (ast-grep)
  │   JSX props, 함수 호출 패턴 등)
  │
  ├─ 단순 텍스트 검색?  ────────────────────────────────► rg (Grep tool)
  │
  ├─ 파일명 패턴?       ────────────────────────────────► fd / Glob tool
  │
  ├─ 큰 파일 구조 파악? ────────────────────────────────► LSP documentSymbol
  │                                                      → fallback: Read offset/limit
  │
  └─ 백링크/문서 그래프? (마크다운/노트) ────────────────► markdown-oxide LSP / obsidian-vault skill
```

## sg (ast-grep) 사용법

`sg`는 **AST 패턴 매칭** 도구. 정규식보다 정확하고 짧으며 오탐이 거의 없다.

### 핵심 메타변수

| 변수 | 의미 |
|------|------|
| `$NAME` | 단일 노드 (식별자, 표현식 등) 1개 |
| `$$$NAME` | 여러 노드 (가변 인자, 본문 statement 묶음) |
| `$_` | 임의의 단일 노드 (이름 없음) |
| `$$$_` | 임의의 다수 노드 (이름 없음) |

### Java 예시

```bash
# 1. 특정 어노테이션 붙은 메서드 찾기
sg --lang java -p '@Transactional
public $RET $METHOD($$$ARGS) { $$$ }'

# 2. .stream().filter(...).collect(...) 체인
sg --lang java -p '$LIST.stream().filter($$$).collect($$$)'

# 3. throw new XxxException(...) 사용처
sg --lang java -p 'throw new $EXCEPTION($$$ARGS)'

# 4. Service 클래스의 모든 public 메서드
sg --lang java -p 'public $RET $METHOD($$$) { $$$ }' \
   --globs '**/*Service.java'
```

### TypeScript / React 예시

```bash
# 1. useEffect 훅 의존성 누락 후보
sg --lang tsx -p 'useEffect(() => { $$$ }, [])'

# 2. console.log 모두 (디버그 코드 청소)
sg --lang ts -p 'console.log($$$)'

# 3. 특정 컴포넌트 사용처
sg --lang tsx -p '<UserCard $$$ />'

# 4. axios.get/post 호출 패턴
sg --lang ts -p 'axios.$METHOD($URL, $$$)'
```

### Python 예시

```bash
# 1. 데코레이터가 붙은 함수
sg --lang python -p '@$DEC
def $FN($$$): $$$'

# 2. except Exception 광범위 캐치
sg --lang python -p 'try: $$$
except Exception: $$$'

# 3. print 디버그 잔존
sg --lang python -p 'print($$$)'
```

### 리라이트 (sg --rewrite)

`sg`는 검색뿐 아니라 **AST 기반 일괄 변환**도 가능. Edit 도구로 100번 수정할 일을 한 번에.

```bash
# console.log를 logger.debug로 일괄 교체
sg --lang ts -p 'console.log($$$ARGS)' --rewrite 'logger.debug($$$ARGS)'

# 미리보기
sg --lang ts -p 'console.log($$$ARGS)' --rewrite 'logger.debug($$$ARGS)' --json
```

## fd 사용법

`find` 보다 빠르고 직관적. `.gitignore` 자동 존중.

```bash
# 확장자별 파일 찾기
fd -e java -e kt              # java/kotlin 파일 전체
fd -e ts -e tsx src/          # src 하위 ts/tsx
fd '^Test' -e java            # Test로 시작하는 java 파일

# 디렉토리만
fd -t d 'service'             # 이름에 service가 들어간 디렉토리

# 변경 시간 기준
fd --changed-within 1d -e java   # 24시간 이내 변경 java 파일

# 결과를 다른 도구로 파이프
fd -e java | xargs wc -l | tail -5
fd -0 -e java | xargs -0 sg --lang java -p '...'
```

## rg (ripgrep) 사용 팁

> Claude Code에서는 **Grep tool** 을 사용 (Bash로 `rg` 직접 호출 금지). 아래는 사고 모델용.

```bash
# 파일 타입 필터
rg --type java 'Service'              # type 옵션이 glob보다 빠름
rg -tjava -tkotlin 'PaymentGateway'

# 컨텍스트 (뒤 라인)
rg 'TODO' -A 3                        # 매치 + 뒤 3줄

# 카운트만 (토큰 절약)
rg -c 'logger\.debug' src/            # 파일별 매치 수만

# files-with-matches (목록만)
rg -l 'BeforeCommit' tests/

# multiline 매칭
rg -U --multiline '@Transactional[\s\S]*?public'
```

## LSP First (Java)

Java는 항상 `rules/java-lsp-exploration.md` 를 우선 적용. 아래는 빠른 매핑:

| 의도 | LSP 함수 | grep으로 했다면 발생할 문제 |
|------|----------|------------------------|
| `OrderService.cancel()` 정의 | `goToDefinition` | 동명이인, 인터페이스/구현체 혼동 |
| `cancel()` 사용처 | `findReferences` | `cancel` 단어가 들어간 모든 메서드 오탐 |
| `PaymentGateway` 구현체 | `goToImplementation` | `implements` 라인만으로는 추상 클래스 누락 |
| 호출 경로 | `incomingCalls` | 람다·메서드 레퍼런스·SAM 변환 추적 불가 |

## 토큰 절약 패턴

### 1. 카운트/통계 먼저, 본문 나중에

```bash
# ❌ BAD: 1000 매치 결과를 통째로 받음
rg 'logger.error' src/

# ✅ GOOD: 먼저 카운트로 규모 파악
rg -c 'logger.error' src/ | sort -t: -k2 -n -r | head -10
# → 어느 파일에 몰려있는지 보고, 그 파일만 정밀 조회
```

### 2. files-with-matches로 분할 정복

```bash
# 1단계: 대상 파일만 추리기
rg -l 'PaymentEvent' src/main/java/

# 2단계: 좁혀진 파일에 대해서만 LSP 호출 또는 정밀 검사
```

### 3. 출력 → 임시 파일

대량 결과는 `/tmp/` 에 저장 후 필요한 부분만 Read.

```bash
sg --lang java -p '...' > /tmp/sg-results-$$.txt
wc -l /tmp/sg-results-$$.txt
# → "234 매치, /tmp/sg-results-$$.txt 저장됨" 보고
# → 사용자 요청 시 head/tail 또는 grep으로 좁혀서 Read
```

### 4. 큰 파일은 LSP `documentSymbol` 부터

```
Read file (3000줄)        → 즉시 컨텍스트 폭발
LSP documentSymbol(file)  → 50줄 심볼 트리 → 필요한 메서드만 Read offset/limit
```

## Anti-patterns (해서는 안 됨)

- ❌ Java 심볼 탐색을 `rg`/`Grep` 으로 (LSP가 있는데도)
- ❌ 1000줄 파일을 통째로 Read 후 "정리해줘"
- ❌ 100개 매치를 그대로 컨텍스트에 받고 AI가 스크롤
- ❌ 정규식으로 메서드 호출 패턴 매칭 ("$x.foo($$$)" 같은 sg 패턴이 정확)
- ❌ `find` 대신 `fd` 사용 안 함 (느리고 .gitignore 무시)
- ❌ 파일 일괄 변환을 Edit 도구로 100번 (sg --rewrite 한 번이면 됨)

## 설치 검증

```bash
which sg ast-grep fd rg jdtls
sg --version           # ast-grep 0.4x+
fd --version           # fd 10.x+
rg --version           # ripgrep 14.x+
```
