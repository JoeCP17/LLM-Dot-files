# Kotlin Code Exploration via LSP

> Kotlin 코드 탐색은 `kotlin-lsp@claude-code-lsps` 플러그인이 노출하는 JetBrains 공식 Kotlin LSP 를 우선 사용. `java-lsp-exploration.md` 의 Kotlin 짝.

## Tradeoff

Kotlin 의 expression body, 확장 함수, 람다, 스코프 함수, sealed type, 컴파일러 합성(`copy`/`componentN`), Spring/JPA 어노테이션을 grep/rg 로 추적하면 오탐·누락이 폭주. LSP 는 동일 토큰 비용으로 정확한 정의·참조·호출 계층을 돌려줍니다. 단 — kotlin-lsp 는 **Alpha** 단계 + 초기 인덱싱이 60초 이상 걸릴 수 있어, `*.kts`/`build.gradle.kts` 빌드 파일·문자열 리터럴·로그 메시지 검색까지 LSP 로 끌어들이는 건 과잉. 빌드/리소스/JSON/YAML 은 그대로 `rg`/`Glob` 으로 처리.

---

## 1. 필수 사용 시점 — Kotlin 심볼 작업은 LSP First

다음 작업은 **무조건** LSP 도구로 수행합니다.

| 작업 | LSP 도구 | grep 으로 했다면 발생할 문제 |
|------|----------|------------------------------|
| 클래스/메서드/프로퍼티 **정의 위치** | `goToDefinition` | 동명이인·부모 클래스 메서드·인터페이스 vs 구현체 구분 불가 |
| 인터페이스/추상 클래스 **구현체** | `goToImplementation` | `: Foo` 만 잡으면 `object: Foo by delegate` / typealias / sealed 누락 |
| **사용처(참조)** | `findReferences` | 확장 함수 호출, infix, operator overload, named argument 모두 텍스트로는 형태가 달라 누락 |
| **호출 계층** | `prepareCallHierarchy` + `incomingCalls` / `outgoingCalls` | 람다, 메서드 레퍼런스(`::foo`), SAM, suspend continuation 추적 불가 |
| 파일 내 **심볼 구조** | `documentSymbol` | Read 로 1000줄 훑기 vs 50줄 심볼 트리 — 토큰 10배+ 차이 |
| 워크스페이스 **심볼 검색** | `workspaceSymbol` | 패키지 포함 정확 매칭, 동명 클래스 구분 |
| 타입/KDoc 정보 | `hover` | 제네릭 바인딩, nullable 여부, suspend/inline 수식어 정확 판단 |
| 자동 import 정리 | `organizeImports` | 수동 정리 시 wildcard import 누락 |

---

## 2. 금지 — Anti-patterns

### Anti-example

```bash
# ❌ BAD — Kotlin 심볼 탐색을 grep/rg 로 수행
Grep pattern="class ContentsService"           # data class·sealed class·companion 구분 불가
Grep pattern="fun isMbjContents"               # 확장 함수면 receiver 정보 누락
Grep pattern=": PaymentGateway"                # by delegation, typealias 누락
Grep pattern="contentsService.cancel"          # named arg / infix call 누락

# ❌ BAD — 큰 Kotlin 파일을 통째 Read 후 구조 파악
Read file_path=".../EpisodeService.kt"         # 1600줄 통째 → 컨텍스트 폭발
```

### Good-example

```
# ✅ GOOD — LSP 도구로 직접 질의
LSP: workspaceSymbol query="ContentsService"
LSP: goToDefinition file=X line=Y character=Z
LSP: findReferences symbol="ContentsService.findById"
LSP: documentSymbol file=".../EpisodeService.kt"   # 50줄 트리
LSP: incomingCalls method="EpisodeService.saveSampleCampaignEpisodeImages"
```

---

## 3. 탐색 순서 (권장 워크플로우)

Kotlin 관련 질문/조사가 들어오면 다음 순서로.

1. **진입점** — `workspaceSymbol` 로 클래스/탑레벨 함수 검색
2. **구조 파악** — `documentSymbol` 로 파일 심볼 트리 확인 (Read 보다 우선)
3. **정의 확인** — `goToDefinition` / `hover` 로 시그니처·KDoc 조회
4. **영향 범위** — `findReferences` 로 사용처 나열
5. **호출 흐름** — `incomingCalls` / `outgoingCalls`
6. **최후의 수단** — 위 단계로 답이 안 나올 때만 `Grep`/`Read` fallback

---

## 4. Fallback — grep/Read 가 정답인 경우

다음에 해당할 때는 LSP 대신 일반 도구가 효율적.

- `build.gradle.kts`, `settings.gradle.kts`, `gradle.properties`, `application.yml` 등 **비 Kotlin 또는 Gradle 빌드 스크립트** (kotlin-lsp 가 KTS 일부 지원하지만 빌드 의존성 모델은 약함)
- 주석·문자열 리터럴·로그 메시지·SQL 쿼리 본문 검색
- 심볼이 아닌 파일명 패턴 글롭 (예. `**/*Controller.kt` 목록)
- LSP 서버가 첫 인덱싱 중이거나 Alpha 한계로 응답 미반환 시 (사용자에게 명시적으로 알리고 진행)
- 멀티 모듈 Gradle 프로젝트에서 LSP 가 일부 모듈만 인덱싱 한 경우 — 미인덱싱 모듈은 grep fallback

---

## 5. 설치 검증

```bash
# 1. kotlin-lsp 바이너리 (Homebrew)
which kotlin-lsp                               # /opt/homebrew/bin/kotlin-lsp
kotlin-lsp --version                           # 262.x 이상

# 2. Claude Code 플러그인
claude plugin list | grep kotlin-lsp           # kotlin-lsp@claude-code-lsps enabled
cat ~/.claude/plugins/cache/claude-code-lsps/kotlin-lsp/*/\.lsp.json
# → {"kotlin": {"command":"kotlin-lsp","args":["--stdio"],"extensionToLanguage":{".kt":"kotlin",".kts":"kotlin"}, ...}}

# 3. JVM (Kotlin LSP 는 JVM 위에서 동작)
java -version                                  # 17 이상 권장
```

문제 발생 시 트러블슈팅.

- `kotlin-lsp` 명령이 없으면 → `brew install JetBrains/utils/kotlin-lsp`
- 플러그인이 없으면 → `claude plugin install kotlin-lsp@claude-code-lsps`
- 첫 호출 시 인덱싱에 **30~120초 가능** (Alpha 단계, balcony-backend 처럼 30+ Gradle 모듈이면 더 오래)
- `startupTimeout: 60000ms` 이 짧다고 판단되면 `.lsp.json` 의 timeout 을 300000 으로 늘려 사용 (jdtls 와 동일 값)
- Claude Code 재시작 후 첫 Kotlin 탐색에 시간이 걸리는 것은 정상
- KMP/`expect`/`actual` 멀티플랫폼 심볼은 platform-specific 모듈이 인덱싱돼야 보임 — 한쪽만 잡히면 LSP fallback 으로 grep 보강

---

## 6. Alpha 단계 주의

JetBrains kotlin-lsp 는 2026-06 기준 **Alpha**. 아래는 알려진 약점.

- 일부 KMP `expect`/`actual` 심볼 해석 불완전
- 멀티 모듈 Gradle 프로젝트에서 모듈 경계 넘는 참조 일부 누락
- KSP/Anvil/kapt 생성 코드는 인덱싱 늦거나 누락
- 리팩토링(rename) 은 동작하지만 모든 호출처 갱신 보장 약함 — 변경 후 `findReferences` 로 재확인 권장

위 상황에서는 명시적으로 사용자에게 "kotlin-lsp Alpha 한계로 X 영역은 grep 보강" 이라고 보고하고 진행합니다.

---

## 7. 리포팅 규칙

LSP 로 탐색한 결과를 사용자에게 보고할 때.

- 파일 경로는 `file_path:line_number` 형태 (Claude Code 렌더러 자동 링크)
- 심볼 이름과 함께 **어떤 LSP 함수로 찾았는지** 명시 (투명성)
  - 예. "`EpisodeService.saveSampleCampaignEpisodeImages` 는 `findReferences` 로 3곳에서 호출됨"
- LSP fallback 으로 grep 사용했다면 이유 명시 ("Alpha 한계 / KSP 생성 코드 / 인덱싱 미완료 등")
- 동일 심볼명이 여러 패키지에 존재할 때 — 풀 qualified name (`com.kidaristudio.balcony.backend.front.service.contents.ContentsService`) 로 구분

---

## 다른 룰과의 관계

| 룰 | 관계 |
|---|---|
| `java-lsp-exploration.md` | 본 룰의 Java 짝. balcony-backend 처럼 Kotlin+Java 혼합 프로젝트는 양쪽 동시 사용 |
| `token-optimization.md` | 8번 Tool Preferences 표에 Kotlin 심볼 = LSP 1순위 적용 |
| `code-search-efficient/SKILL.md` | 결정 트리 첫 분기 — "언어가 Kotlin 인가?" → kotlin-lsp |
| `behavioral-principles.md` | 원칙 1(Think Before Coding) — 인덱싱 미완료 상태를 추측하지 말고 LSP health 확인 후 진행 |

---

## 안티패턴

- ❌ Kotlin 심볼 탐색을 `rg`/`Grep` 으로 (LSP 가 있는데도)
- ❌ 1000줄 이상 Kotlin 파일을 통째 Read 후 "정리해줘"
- ❌ 확장 함수 사용처를 receiver 타입으로 grep — operator/infix/named arg 형태로 호출되면 누락
- ❌ data class `copy()` / `componentN()` / `equals` 등 컴파일러 합성 메서드 사용처를 grep — LSP 가 합성 심볼도 추적
- ❌ Alpha 한계로 LSP 가 부분 결과만 줬는데 그대로 결론 — 사용자에게 한계 보고 + grep 보강
- ❌ Java 짝 룰만 따르고 Kotlin 도 `jdtls` 가 처리한다고 가정 — jdtls 는 `.java` 만, `.kt`/`.kts` 는 kotlin-lsp 담당
- ❌ KSP/kapt 생성 코드에 대한 참조를 LSP 만 신뢰 — 생성 모듈 인덱싱 시점에 따라 누락, grep 보강 필요
