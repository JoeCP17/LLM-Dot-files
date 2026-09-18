---
paths:
  - "**/*.kt"
  - "**/*.kts"
---
# Kotlin Coding Style

> This file extends [common/coding-style.md](../common/coding-style.md) with Kotlin-specific content.

## Formatting

- **ktlint** or **Detekt** for style enforcement
- Official Kotlin code style (`kotlin.code.style=official` in `gradle.properties`)

## Immutability

- Prefer `val` over `var` — default to `val` and only use `var` when mutation is required
- Use `data class` for value types; use immutable collections (`List`, `Map`, `Set`) in public APIs
- Copy-on-write for state updates: `state.copy(field = newValue)`

## Naming

Follow Kotlin conventions:
- `camelCase` for functions and properties
- `PascalCase` for classes, interfaces, objects, and type aliases
- `SCREAMING_SNAKE_CASE` for constants (`const val` or `@JvmStatic`)
- Prefix interfaces with behavior, not `I`: `Clickable` not `IClickable`

## Null Safety

- Never use `!!` — prefer `?.`, `?:`, `requireNotNull()`, or `checkNotNull()`
- Use `?.let {}` for scoped null-safe operations
- Return nullable types from functions that can legitimately have no result

```kotlin
// BAD
val name = user!!.name

// GOOD
val name = user?.name ?: "Unknown"
val name = requireNotNull(user) { "User must be set before accessing name" }.name
```

## Boolean Predicates

파생된 불리언은 **밖에서 비교하지 말고 객체가 답하게** 합니다. 함수보다 `val` + `get()` 프로퍼티를 씁니다.

```kotlin
// BAD — 호출부가 내부 구조를 안다
if (contents.type != ContentsMainType.NOVEL) reject()

// GOOD — 객체가 답한다
val isNovel: Boolean
    get() = type == ContentsMainType.NOVEL

if (!contents.isNovel) reject()
```

- 값을 저장하지 말 것 (`var isNovel = ...`) — 원본이 바뀌면 어긋납니다.
- 영속 엔티티에서 `val` + `get()` 은 backing field 가 없어 컬럼으로 매핑되지 않습니다 (JPA 는 접근 타입에 따라 `@Transient` 필요). 자세한 내용은 [kotlin-spring-server.md](./kotlin-spring-server.md) 3번.

## Sealed Types

Use sealed classes/interfaces to model closed state hierarchies:

```kotlin
sealed interface UiState<out T> {
    data object Loading : UiState<Nothing>
    data class Success<T>(val data: T) : UiState<T>
    data class Error(val message: String) : UiState<Nothing>
}
```

Always use exhaustive `when` with sealed types — no `else` branch.

## Extension Functions

Use extension functions for utility operations, but keep them discoverable:
- Place in a file named after the receiver type (`StringExt.kt`, `FlowExt.kt`)
- Keep scope limited — don't add extensions to `Any` or overly generic types

## Scope Functions

Use the right scope function:
- `let` — null check + transform: `user?.let { greet(it) }`
- `run` — compute a result using receiver: `service.run { fetch(config) }`
- `apply` — configure an object: `builder.apply { timeout = 30 }`
- `also` — side effects: `result.also { log(it) }`
- Avoid deep nesting of scope functions (max 2 levels)

## Error Handling

- Use `Result<T>` or custom sealed types
- Use `runCatching {}` for wrapping throwable code
- Never catch `CancellationException` — always rethrow it
- Avoid `try-catch` for control flow

```kotlin
// BAD — using exceptions for control flow
val user = try { repository.getUser(id) } catch (e: NotFoundException) { null }

// GOOD — nullable return
val user: User? = repository.findUser(id)
```
