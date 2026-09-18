---
paths:
  - "**/*.kt"
---
# Kotlin + Spring 서버 규약

> Spring 서버에서 반복해서 틀리는 일곱 가지 — `suspend` 의 main-safety, 엔티티의 계산 프로퍼티, 판별 로직의 위치, 유스케이스 경계. **MVC(Servlet)와 WebFlux(Netty)는 메커니즘이 같고 스레드 풀이 달라 결론이 갈립니다.** 항목마다 어느 스택에 해당하는지 표시했습니다.

## Tradeoff

본 룰은 **틀렸을 때 조용히 굴러가다 운영에서 터지는 것들**만 담습니다. 컴파일러도 테스트도 안 잡아 줍니다. 대신 Android/KMP·CLI·배치 전용 코드에는 1·3번이 해당하지 않으니 건너뛰어도 됩니다. 1번의 결론은 스택에 따라 **정반대**가 되므로 0번을 먼저 읽으세요.

---

## 0. 먼저 — 내 스택이 어느 쪽인가

| | **MVC (Servlet · Tomcat)** | **WebFlux (Netty)** |
| --- | --- | --- |
| 의존성 | `spring-boot-starter-web` | `spring-boot-starter-webflux` |
| 요청 스레드 | `http-nio-*-exec-N` | `reactor-http-nio-N` |
| 풀 크기 (기본) | **200** (`server.tomcat.threads.max`) | **`max(코어 수, 4)`** (`reactor.netty.ioWorkerCount`) |
| 스레드 모델 | 요청당 1스레드 | 이벤트 루프 다중화 |
| 블로킹 비용 | 200개 중 1개 점유 — **설계상 정상** | 4개 중 1개 정지 — **다른 요청까지 멈춤** |
| DB | JDBC/JPA (블로킹) | R2DBC (논블로킹) |

⚠️ **한 애플리케이션에 둘 다 있을 수 있습니다.** WebClient 만 쓰는 MVC 앱, 또는 모듈별로 스택이 다른 경우입니다. 판단은 **컨트롤러가 실제로 도는 스레드 이름**으로 하세요.

```kotlin
logger.info("carrier={}", Thread.currentThread().name)
```

---

## 1. `suspend` 는 호출자 스레드를 막지 않는다 (main-safety)

**`suspend` 키워드가 붙었다고 중단되는 게 아닙니다. 본문이 실제로 중단 지점을 만나야 합니다.**

| | 예 | 스레드를 |
|---|---|---|
| **중단** | `delay()` · `await*()` · `Flow.collect()` | **반납한다** |
| **블로킹** | `Thread.sleep()` · JDBC · `ImageIO.read()` · `Future.get()` | **붙잡는다** |

### 메커니즘은 두 스택이 같다

MVC·WebFlux 모두 `org.springframework.web.method.support.InvocableHandlerMethod` → `CoroutinesUtils.invokeSuspendingFunction` 을 타고, 이 함수는 **`Dispatchers.Unconfined`** 로 코루틴을 시작합니다.

`Unconfined` 는 **전용 스레드 풀이 없습니다.** 자기를 호출한 스레드를 그대로 빌려 쓰고, 중단 후에는 자기를 재개시킨 스레드에서 이어집니다. 그래서 **「코루틴 안이라서 격리된다」는 어느 스택에서도 성립하지 않습니다.**

### 결론은 스택에 따라 갈린다

**WebFlux — 블로킹은 결함입니다.**
빌리는 스레드가 이벤트 루프(`reactor-http-nio`, 또는 R2DBC 드라이버의 `reactor-tcp-nio`)이고 개수가 `max(코어,4)` 뿐입니다. 하나를 붙잡으면 **그 스레드에 묶인 다른 요청·다른 DB 커넥션이 전부 대기**합니다. 반드시 `withContext(Dispatchers.IO)` 로 넘깁니다.

**MVC — 블로킹이 기본값입니다.**
빌리는 스레드가 Tomcat 워커(기본 200개)이고, 요청당 1스레드가 원래 모델입니다. JDBC 호출을 `Dispatchers.IO` 로 넘기면 **스레드 홉만 늘고 얻는 게 없습니다.** 다만 다음은 MVC 에서도 오프로드가 맞습니다.

- 한 요청 안에서 **여러 작업을 병렬로** 돌릴 때 (`async` + `awaitAll`)
- 200개를 다 물 만큼 긴 작업 (수십 초짜리 외부 API)
- `spring.threads.virtual.enabled=true` 라면 블로킹 비용이 더 내려가므로 오프로드 필요성은 더 줄어듭니다

### Anti-example (WebFlux)

```kotlin
// ❌ suspend 인데 본문이 블로킹 — 시그니처가 거짓말이다
suspend fun download(key: String, dest: File) {
    transferManager.download(bucket, key, dest).waitForCompletion()
}
```

### Good-example (WebFlux)

```kotlin
// ✅ 블로킹 API 를 감싸는 쪽이 책임진다. 호출자는 시그니처를 믿을 수 있다
suspend fun download(key: String, dest: File) {
    withContext(Dispatchers.IO) {
        transferManager.download(bucket, key, dest).waitForCompletion()
    }
}
```

**같은 디스패처로 중첩해도 재디스패치가 없습니다.** 서비스에서 넓게 감싸고 유틸에서 또 감싸도 스레드 홉이 늘지 않으므로 계층 선택은 배타적이지 않습니다. 다만 **한 블로킹 호출에 wrap 하나**로 유지해야 의도가 읽힙니다.

### 의심되면 재현해서 확인한다

고정 스레드 풀로 이벤트 루프를 흉내 내면 30초 만에 판별됩니다. 풀 크기를 4(WebFlux)와 200(MVC)으로 바꿔 보면 스택별 차이도 그대로 재현됩니다.

```kotlin
val loop = Executors.newFixedThreadPool(4).asCoroutineDispatcher()
// 느린 작업 4개로 풀을 채운 뒤, 짧은 요청 20개의 최대 대기 시간을 잰다
//   Thread.sleep(300)                                 → 300ms 밀린다
//   withContext(Dispatchers.IO) { Thread.sleep(300) } →   0ms
//   delay(300)                                        →   1ms  (진짜 중단)
```

---

## 2. 판별은 객체 안에 `val isX get()` 으로 둔다 *(스택 무관)*

**밖에서 상태를 물어 비교하지 말고, 객체가 답하게 합니다.** 함수형(`fun isX()`)이 아니라 **프로퍼티**를 씁니다.

### Anti-example

```kotlin
// ❌ 서비스가 enum 내부를 알고 있다
if (article.type != ArticleType.NOVEL) reject()
if (chapter.contentType == ContentType.EPUB) reject()
```

### Good-example

```kotlin
// 엔티티·enum 안
val isNovel: Boolean
    get() = type == ArticleType.NOVEL

val isEpub: Boolean
    get() = this == EPUB

// 호출부
if (!article.isNovel) reject()
if (chapter.contentType.isEpub) reject()
```

**예외.** 「이 기능이 어떤 값까지 지원하는가」는 enum 의 본질이 아니라 **서비스 정책**입니다. 지원 목록이 늘 때 바뀌어야 하는 쪽이 서비스라면 서비스에 둡니다.

---

## 3. 엔티티의 계산 프로퍼티는 컬럼이 아니다

`val` + `get()` 은 backing field 가 없어 영속 매핑에서 제외됩니다.

⚠️ **`var isX = ...` 로 쓰면 backing field 가 생겨 진짜 컬럼이 됩니다.** 반드시 `val` + `get()` 입니다.

### Spring Data (R2DBC · JDBC) — 확인된 동작

매핑 컨텍스트에 직접 물어보면 됩니다. DB 없이 돕니다.

```kotlin
val ctx = RelationalMappingContext()
val entity = ctx.getRequiredPersistentEntity(MyEntity::class.java)
entity.forEach { println("${it.name} -> ${it.columnName}") }
// 계산 프로퍼티가 목록에 없으면 안전
```

### JPA/Hibernate — 접근 타입에 달렸다

`@Id` 를 **필드**에 붙였으면 field access 라 계산 프로퍼티가 무시됩니다. **getter** 에 붙였으면 property access 가 되어 Hibernate 가 `isX` 를 매핑하려 듭니다. 이때는 `@Transient` 가 필요합니다. 헷갈리면 붙이세요 — field access 에서도 무해합니다.

---

## 4. 유스케이스는 서비스가 완결한다 *(스택 무관)*

**호출부가 「먼저 A 를 부르고 그다음 B」 같은 순서 계약을 알면 안 됩니다.** 빠뜨리면 검증이 통째로 사라지기 때문입니다.

### Anti-example

```kotlin
// ❌ 컨트롤러가 순서를 알아야 하고, 첫 줄을 빼면 검증이 사라진다
val target = service.findAndValidate(id)
return operator.execute { service.doWork(target) }
```

### Good-example

```kotlin
// ✅ doWork 가 스스로 열고 검증한다. 조회는 인프라 파라미터 용도일 뿐이다
val target = service.findAndValidate(id)   // 캐시 무효화 파라미터 조립용
return operator.executeWithCacheInvalidation(paramData = target.toParams()) {
    service.doWork(id)                     // 안에서 다시 검증한다
}
```

두 호출이 **순서 계약이 아니라 독립 호출**이 됩니다. 중복 조회 1회는 관리자용 단발 API 라면 감수할 만한 값입니다.

**캐시 무효화·트랜잭션 경계 같은 인프라 관심사는 진입점(컨트롤러 래퍼·배치 리스너)에 둡니다.** 서비스로 내리면 그 파일만 다른 패턴이 됩니다 — 옮기기 전에 레포 전체의 사용처를 세어 보세요.

---

## 5. 응용 서비스는 도메인 서비스를 직접 쓴다 *(스택 무관)*

응용 서비스가 도메인/영속 서비스를 직접 주입하는 게 기본입니다. **응용 서비스끼리 주입하는 건 예외**이며, 순환 의존과 트랜잭션 경계 혼선의 출발점입니다.

「기존 서비스를 거쳐야 하나」 싶으면 **레포에서 두 방식의 사용처 수를 세어** 판단하세요.

---

## 6. 트랜잭션이 없는 경로는 교체 순서를 지킨다 *(스택 무관)*

파일 업로드·외부 API 가 섞인 경로에는 트랜잭션이 없는 경우가 많습니다. 리액티브 스택에서는 특히 흔합니다. **새 자원을 확보한 뒤에 기존 것을 지웁니다.**

```
① 새 파일 업로드 → 성공 확인
② 기존 레코드 삭제
③ 새 레코드 저장
④ 캐시 갱신
```

①과 ②를 뒤집으면 업로드가 거절될 때 **기존 데이터가 사라지고 되돌릴 수단이 없습니다.**

---

## 7. 같은 예외 타입을 여러 사유에 쓰면 사유까지 검증한다 *(스택 무관)*

한 서비스가 `InvalidParameterException` 을 다섯 가지 이유로 던진다면 `assertThrows<InvalidParameterException>` 은 **아무것도 증명하지 못합니다.** 다른 이유로 실패해도 통과합니다.

### Anti-example

```kotlin
// ❌ 어떤 이유로 거절됐는지 구분이 안 된다
assertThrows<InvalidParameterException> { sut.extract(id) }
```

### Good-example

```kotlin
// ✅ 거절 사유를 고정한다
val thrown = assertThrows<InvalidParameterException> { sut.extract(id) }
assertEquals(NOT_NOVEL_MESSAGE, thrown.message)
assertEquals(ErrorCode.InvalidParams, thrown.code)
```

메시지 중복이 싫으면 상수로 빼거나 에러 코드로 비교합니다.

---

## 다른 룰과의 관계

| 룰 | 관계 |
|---|---|
| `coding-style.md` | 일반 Kotlin 스타일. 본 룰 2번이 그쪽 «Boolean Predicates» 의 서버 적용 |
| `patterns.md` | Android/KMP 패턴. 본 룰은 서버 계층 경계(4·5번) 담당 |
| `testing.md` | 테스트 일반. 본 룰 7번이 그쪽 «Asserting Exceptions» 와 짝 |
| `behavioral-principles.md` | 원칙 10(Read Errors) — 0·1·3번의 「추측 말고 재현·조회해서 확인」이 그 적용 |
| `kotlin-lsp-exploration.md` | 5번의 사용처 세기는 LSP `findReferences` 로 |

---

## 안티패턴

- ❌ 스택을 확인하지 않고 블로킹 규칙을 적용 → MVC 에 불필요한 오프로드, WebFlux 에 누락
- ❌ `suspend` 가 붙었으니 논블로킹이라고 가정 → 본문이 블로킹이면 캐리어 스레드를 잡는다
- ❌ 「코루틴 안이니까 다른 요청과 격리된다」 → `Unconfined` 는 전용 스레드가 없다
- ❌ WebFlux 에서 블로킹 오프로드를 호출자에게 떠넘기기 → 한 곳만 빠뜨려도 조용히 재발한다
- ❌ MVC 에서 모든 JDBC 호출을 `Dispatchers.IO` 로 감싸기 → 스레드 홉만 늘고 얻는 게 없다
- ❌ 한 블로킹 호출에 wrap 을 두세 겹 → 비용은 0이지만 의도가 안 읽힌다
- ❌ 엔티티에 `var isX = ...` 로 파생 값 저장 → backing field 가 생겨 없는 컬럼을 찾는다
- ❌ JPA 에서 계산 프로퍼티에 `@Transient` 생략 → property access 면 매핑 오류
- ❌ 서비스가 enum·엔티티 내부를 꺼내 비교 → 판별 규칙이 호출부마다 흩어진다
- ❌ 컨트롤러가 「먼저 A, 그다음 B」 순서를 알아야 동작 → 한 줄 빠지면 검증이 사라진다
- ❌ 기존 레코드를 먼저 지우고 새 파일을 업로드 → 실패 시 복구 불가
- ❌ 예외 타입만 검증 → 다른 이유로 실패해도 초록불
- ❌ 스레드·매핑 동작을 기억으로 단정 → 재현 테스트나 매핑 컨텍스트 조회로 확인할 것
