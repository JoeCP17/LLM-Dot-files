---
paths:
  - "**/*.kt"
---
# Kotlin 가독성과 계층 배치

> Kotlin 코드를 쓰기 전과 쓰는 중에 확인할 것. 문법을 의미대로 쓰는지(스코프 함수, 프로퍼티, 시퀀스, 코루틴 스코프), 코드가 맞는 계층에 있는지(mock, 테스트용 코드, 이름 없는 람다)를 다룹니다. 사내 MR 리뷰에서 실제로 지적받은 항목에서 출발했습니다.

## Tradeoff

이 룰은 **리뷰어가 코드를 읽는 비용**을 줄이는 게 목적입니다. 동작은 같아도 문법을 의미와 다르게 쓰면 리뷰에서 매번 같은 질문이 나오고, 한 MR 에 코멘트가 여러 개 쌓입니다. 일회성 스크립트, 테스트 픽스처 조립 코드에는 느슨하게 적용해도 됩니다. 레포에 다른 관례가 이미 굳어 있으면 그 관례가 우선입니다. 판단이 서지 않으면 레포 사용처를 세어 보고 정합니다.

---

## 0. 쓰기 전에 다섯 가지를 먼저 정한다

**코드를 쓰기 시작한 뒤에 위치와 모양을 고치면 MR 코멘트가 됩니다.** 첫 줄을 쓰기 전에 아래를 답합니다.

| 질문 | 확인 방법 |
|---|---|
| 이 코드는 어느 계층의 책임인가 (컨트롤러, 응용 서비스, 도메인 서비스, 리포지토리, 결과 클래스) | 같은 모듈의 비슷한 기능이 어디에 두는지 2~3곳 본다 |
| 운영에서 안 쓰는 코드(mock, 테스트 데이터, 디버그용)가 섞이는가 | 섞이면 6번대로 별도 빈으로 뺀다 |
| 레포에 같은 일을 하는 관례가 있는가 | 사용처 수를 센다 (`kotlin-lsp-exploration.md`) |
| 다른 함수를 옮겨 쓰는가 | 원본 스타일을 그대로 복사하지 말고 이 룰로 다시 쓴다 (7번) |
| 값이 바뀌는 객체인가, 생성 뒤 고정인가 | 프로퍼티 작성 방식이 갈린다 (2번) |

---

## 1. 스코프 함수는 의미대로 쓴다

**`let` 은 값을 바꿔 돌려줄 때, `also` 는 부수 효과, `apply` 는 객체 설정입니다. null 분기만 하려면 `if` 가 더 읽힙니다.**

| 하려는 일 | 쓸 것 |
|---|---|
| null 이 아니면 블록 실행, 반환값 안 씀 | `if (x != null) { ... }` (smart cast 로 `x` 그대로 사용) |
| null 이 아니면 다른 값으로 변환 | `x?.let { transform(it) }` |
| 값을 그대로 두고 로그, 검증 같은 부수 효과 | `x.also { log(it) }` |
| 객체를 만들고 필드 설정 | `Foo().apply { a = 1 }` |

### Anti-example

```kotlin
// ❌ 반환값을 버리는 let. 변환처럼 보여 읽는 사람이 결과를 찾는다
loginUser?.let { user ->
    if (repository.findById(user.userId)?.isAdult == true) throw MismatchAdult()
}

// ❌ let 안에 let. 무엇이 null 검사인지 한눈에 안 보인다
loginUser?.let {
    result.closedAt?.let { closedAt ->
        if (closedAt < now) throw Ended()
    }
}
```

### Good-example

```kotlin
// ✅ 분기는 if. 파라미터는 smart cast 된다
if (loginUser != null && repository.findById(loginUser.userId)?.isAdult == true) throw MismatchAdult()

// ✅ 다른 객체의 nullable 프로퍼티는 지역 val 로 받아 smart cast
if (loginUser != null) {
    val closedAt = result.closedAt
    if (closedAt != null && closedAt < now) throw Ended()
}
```

**smart cast 가 안 되는 경우.** 다른 모듈의 프로퍼티, `var`, 커스텀 getter 는 smart cast 되지 않습니다. 이때도 `?.let` 대신 지역 `val` 로 받습니다.

---

## 2. 생성 뒤 고정인 값은 초기화 `val`, 바뀔 수 있는 값은 `get()`

**`val x get() = ...` 는 읽을 때마다 다시 계산합니다.** 모든 생성자 프로퍼티가 `val` 인 불변 클래스라면 결과가 늘 같으므로 생성할 때 한 번 정합니다.

| 클래스 | 계산 프로퍼티 |
|---|---|
| 불변 결과, DTO (`data class` 의 모든 필드가 `val`) | `val isX: Boolean = ...` (초기화) |
| 필드가 `var` 인 엔티티, 상태 객체 | `val isX: Boolean get() = ...` (원본이 바뀌면 따라가야 함) |
| 현재 시각처럼 읽는 순간 달라지는 값 | `get()` |

### 영속 매핑 주의

본문 초기화 `val` 은 backing field 가 생겨 매핑기가 **프로퍼티로 인식**합니다.

- **Spring Data R2DBC, JDBC 조회 결과** — 조회 결과에 없는 컬럼은 채우지 않습니다(`MappingR2dbcConverter.captureRowValues`, `MappingRelationalConverter.populateProperties` 의 `hasValue` 검사, spring-data-relational 3.5 소스 확인). 조회 전용 결과 클래스에는 `@Transient` 를 붙이지 않습니다. `org.springframework.data.annotation.Transient` 는 「저장하지 않는 필드」를 뜻하는 엔티티용이고, 저장하지 않는 결과 클래스에 붙이면 영속 관심사가 섞여 읽는 사람이 엔티티로 오해합니다. 레포 선례도 엔티티(`var` 필드)에만 쓰고, 조회 결과의 본문 `val` 은 어노테이션 없이 씁니다. 계산 프로퍼티와 같은 이름의 컬럼을 `SELECT` 하지 않도록 이름을 정합니다.
- **저장하는 엔티티** — 쓰기 때 없는 컬럼을 찾습니다. 엔티티는 `get()` 을 씁니다 (`kotlin-spring-server.md` 3번).
- 의심되면 Testcontainers 통합 테스트로 실제 조회 결과의 계산 값까지 확인합니다.

`data class` 본문 프로퍼티는 `equals`, `hashCode`, `copy` 인자에서 빠지지만 생성자 값으로 계산되므로 결과는 일관됩니다.

### Anti-example

```kotlin
// ❌ 불변 결과인데 읽을 때마다 다시 계산
data class SentenceResult(val isExcluded: Boolean, val status: Status?, val startMs: Int?) {
    val hasAudio: Boolean
        get() = !isExcluded && status == Status.DONE && startMs != null
}
```

### Good-example

```kotlin
// ✅ 생성 때 한 번
data class SentenceResult(val isExcluded: Boolean, val status: Status?, val startMs: Int?) {
    val hasAudio: Boolean = !isExcluded && status == Status.DONE && startMs != null

    val isMissingAudio: Boolean = !isExcluded && !hasAudio   // 위에서 정한 값을 쓰므로 선언 순서가 중요하다
}
```

---

## 3. 여러 단계 컬렉션 연산은 `asSequence()` 로 한 번에 평가한다

**`filter`, `map`, `flatMap` 을 두 단계 이상 잇는 List 연산은 단계마다 중간 List 를 만듭니다.** 시퀀스는 원소 하나씩 끝까지 흘려 중간 컬렉션이 없습니다.

| 상황 | 쓸 것 |
|---|---|
| 두 단계 이상 연결 (`flatMap → filter → map` 등) | `asSequence() ... toList()` |
| 한 단계 (`filter` 하나, `map` 하나) | List 그대로 |
| 결과를 Set, Map 으로 모을 때 | `mapTo(mutableSetOf())`, `associateBy` 처럼 대상 컬렉션을 바로 지정 (`map { }.toSet()` 금지) |
| `sorted`, `groupBy` 처럼 전체를 봐야 하는 단계가 중간에 있음 | 시퀀스 이점이 줄어든다. 그 단계 앞뒤로 나눠 판단 |

### Anti-example

```kotlin
// ❌ 중간 List 3개
val missingSeqNos = chapters
    .flatMap { byChapter[it.no].orEmpty() }
    .filter { it.isMissingAudio }
    .map { it.seqNo }

val chapterNos = chapters.map { it.no }.toSet()
```

### Good-example

```kotlin
// ✅ 한 번에 평가
val missingSeqNos = chapters.asSequence()
    .flatMap { byChapter[it.no].orEmpty() }
    .filter { it.isMissingAudio }
    .map { it.seqNo }
    .toList()

val chapterNos = chapters.mapTo(mutableSetOf()) { it.no }
```

---

## 4. `coroutineScope` 는 동시 실행이 필요한 구간만 감싼다

**함수 본문 전체를 `= coroutineScope { }` 로 감싸면 어디서 동시 실행이 일어나는지 안 보입니다.** `async` 를 쓰는 블록만 감쌉니다.

### Anti-example

```kotlin
// ❌ 100줄 검증 전체가 스코프 안. async 가 어디 있는지 찾아야 한다
suspend fun getPlayback(...): Response = coroutineScope {
    validateA()
    validateB()
    val owned = async { libraryService.existsOwned(userId) }
    val rented = async { libraryService.existsRented(userId) }
    ...
}
```

### Good-example

```kotlin
// ✅ 동시 실행 구간만
suspend fun getPlayback(...): Response {
    validateA()
    validateB()
    val (isOwned, isRented) = coroutineScope {
        val owned = async { libraryService.existsOwned(userId) }
        val rented = async { libraryService.existsRented(userId) }
        owned.await() to rented.await()
    }
    ...
}
```

스코프를 좁혀도 구조적 동시성은 같습니다. 블록 안 `async` 하나가 실패하면 나머지가 취소되고 예외가 블록 밖으로 나옵니다.

---

## 5. 역할이 있는 동작은 이름 있는 함수로 둔다

**`val load: suspend () -> T = { ... }` 같은 지역 람다는 이름이 역할을 설명하지 못하면 리뷰어가 「이 함수가 뭘 하냐」고 묻습니다.** 10줄을 넘거나 분기가 있으면 private 함수로 빼고, 이름에 무엇을 어디서 하는지 드러냅니다.

### Anti-example

```kotlin
// ❌ load 가 무엇을 읽고 언제 불리는지 본문을 다 읽어야 안다
val load: suspend () -> Map<Int, List<Sentence>> = { /* 15줄 */ }
val serviceId = currentServiceIdOrNull() ?: return load()
return cache.get(key, load)
```

### Good-example

```kotlin
// ✅ 캐시 경로와 DB 읽기가 함수 이름으로 갈린다
val serviceId = currentServiceIdOrNull() ?: return readSentences(jobId, revision)
return cache.get(key) { readSentences(jobId, revision) }

/** DB 에서 문장을 읽어 챕터별로 묶는다. 캐시를 쓰면 캐시에 없을 때만 불린다. */
private suspend fun readSentences(jobId: Long, revision: Int): Map<Int, List<Sentence>> { ... }
```

---

## 6. 운영에서 안 쓰는 코드는 서비스 밖 별도 빈으로 둔다

**mock 데이터, 테스트용 고정 응답, 디버그 분기를 응용 서비스 안에 두지 않습니다.** 서비스가 프로필 문자열을 받아 분기하면 운영 코드와 확인용 코드가 한 파일에서 섞입니다.

- `@Profile("local", "develop")` 컴포넌트로 분리하고, 서비스는 `ObjectProvider<T>.ifAvailable` 또는 nullable 주입으로 받습니다. 운영 프로필에서는 빈 자체가 없습니다.
- 레포 선례를 먼저 봅니다 (`@Profile` 컨트롤러, `ObjectProvider` 주입 사용처).
- 테스트에서는 프로필 문자열 대신 「mock 빈이 있다, 없다」로 나누고, 프로필 값은 어노테이션을 직접 확인하는 테스트 하나로 고정합니다.

### Anti-example

```kotlin
// ❌ 서비스가 프로필로 분기하고 mock 데이터 60줄을 품는다
class PlaybackService(@Value("\${spring.profiles.active:}") profile: String) {
    private val isMockEnabled = profile in setOf("local", "develop")
    private fun mockChapters() = listOf(/* 60줄 */)
}
```

### Good-example

```kotlin
// ✅ mock 은 따로, 서비스는 있으면 쓴다
@Component
@Profile("local", "develop")
class PlaybackMock(private val cdnUtil: CdnUtil) { fun findChapters(...) = ... }

class PlaybackService(mockProvider: ObjectProvider<PlaybackMock>) {
    private val playbackMock: PlaybackMock? = mockProvider.ifAvailable
}
```

---

## 7. 기존 함수를 옮겨 쓸 때는 다시 쓴다

**검증 단계를 다른 함수에서 옮겨 올 때 원본의 `?.let` 중첩, 넓은 스코프까지 그대로 복사하면 리뷰 코멘트도 같이 옮겨 옵니다.** 동작(검증 순서, 예외 종류와 메시지)은 그대로 두고 표현만 이 룰대로 다시 씁니다. 원본 함수는 요청 범위가 아니면 고치지 않고, 같은 문제가 있다고 보고만 합니다 (`behavioral-principles.md` 3번).

---

## 다른 룰과의 관계

| 룰 | 관계 |
|---|---|
| `coding-style.md` | 일반 Kotlin 스타일. 그쪽 «Scope Functions», «Boolean Predicates» 를 본 룰 1번, 2번이 구체화 |
| `kotlin-spring-server.md` | 2번(판별은 객체 안에)과 3번(엔티티 계산 프로퍼티)이 본 룰 2번의 엔티티 쪽. 불변 결과 클래스는 본 룰을 따름 |
| `behavioral-principles.md` | 원칙 3(Surgical) 이 본 룰 7번의 「원본은 보고만」 근거 |
| `kotlin-lsp-exploration.md` | 0번의 레포 관례 사용처 세기 |
| `agents.md` | 교차 리뷰 브리프에 본 룰 항목을 점검 대상으로 넣는다 |

---

## 안티패턴

- ❌ 반환값을 버리는 `?.let { }` 로 null 분기 → `if (x != null)`
- ❌ `?.let` 안에 `?.let` 중첩 → 지역 `val` 과 `if`
- ❌ 불변 data class 에 `val x get() = ...` → 초기화 `val`
- ❌ 저장하는 엔티티에 본문 초기화 `val` → 없는 컬럼을 찾는다. 엔티티는 `get()`
- ❌ 조회 전용 결과 클래스에 `@Transient` → 저장하지 않는 클래스에 엔티티용 영속 어노테이션이 섞인다. 같은 이름 컬럼을 조회하지 않게 이름으로 막는다
- ❌ `map { }.toSet()`, 세 단계 List 연산 → `mapTo`, `asSequence()`
- ❌ 함수 전체를 `= coroutineScope { }` 로 감쌈 → `async` 구간만
- ❌ 역할을 숨긴 지역 람다(`load`, `block`, `action`) → 이름 있는 private 함수
- ❌ 응용 서비스에 mock 데이터와 프로필 분기 → `@Profile` 별도 빈
- ❌ 옮겨 온 코드의 스타일을 그대로 복사 → 동작은 유지, 표현은 다시
- ❌ 이 룰 항목을 기억으로만 적용 → 쓰기 전 0번 표를 답하고, 리뷰 브리프에 점검 항목으로 넣는다
