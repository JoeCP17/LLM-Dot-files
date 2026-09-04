---
name: obsidian-vault
description: |
  Obsidian vault 및 마크다운 문서 작업 시 사용. markdown-oxide LSP 기반 백링크/태그 검색,
  ripgrep 기반 fallback, 토큰 최적화 전략 제공. Obsidian, vault, 마크다운, 태그, 노트 정리,
  zettelkasten, 백링크, wiki-link, PKM 관련 작업 시 자동 적용.
  출처: msbaek/dotfiles의 obsidian-vault skill을 로컬 환경에 맞게 어댑테이션.
---

# Obsidian Vault 작업 가이드

## 경로 정보 (SSOT — 2026-06-05 갱신)

| 항목 | 경로 |
|------|------|
| 기본 vault | `~/Desktop/balcony-docs/` (`.obsidian/` 존재) |
| 프로젝트 분석/룰/도메인 | `<vault>/balcony-backend/` |
| 일자별 작업 로그 | `<vault>/daily-work/YYYY-MM-DD.md` |
| 도메인 지식·용어집 | `<vault>/domain-knowledge/` |

> 이전 vault `~/Desktop/ueibin.kim/`, 산출물 트리 `~/Desktop/plan-root-docs/` 는 **superseded**. 현행 vault 가 SSOT. 변경 시 본 표 업데이트 + [[feedback-obsidian-vault-convention]] 동기화.

## 검색 도구 우선순위

```
1순위: markdown-oxide LSP (백링크/태그/링크 그래프)  ← 설치 권장
2순위: ripgrep (Grep tool) — 단순 키워드/문자열
3순위: fd / Glob — 파일명 패턴
```

### markdown-oxide 설치 (선택)

```bash
# Cargo 기반
cargo install --locked markdown-oxide

# 또는 prebuilt binary
# https://github.com/Feel-ix-343/markdown-oxide/releases
```

설치 후 `claude-code-lsps` 마켓플레이스에 markdown-oxide LSP 플러그인이 있는지 확인:
```bash
ls ~/.claude/plugins/marketplaces/claude-code-lsps/ | grep -i markdown
```
없으면 markdown-oxide MCP 서버 설정으로 대체 (별도 작업 필요).

## LSP 기반 검색 (markdown-oxide 설치 시)

| 작업 | 도구 |
|------|------|
| `[[링크]]` → 정의 위치 | `goToDefinition` |
| 백링크 (이 노트를 참조하는 곳) | `findReferences` |
| `#태그` 사용처 | `findReferences` (태그 심볼) |
| 깨진 링크 | `diagnostics` |
| 파일 내 헤딩/심볼 트리 | `documentSymbol` |
| 워크스페이스 노트 검색 | `workspaceSymbol` |

### 사용 예시

```
"TDD 노트를 참조하는 모든 노트 찾아줘"  → findReferences
"#project/active 태그 노트 목록"        → findReferences (#project/active)
"vault에서 깨진 링크 확인"              → diagnostics
"이 노트의 헤딩 구조"                   → documentSymbol
```

## Fallback (markdown-oxide 미설치 시)

```bash
# 백링크 (이 노트의 파일명을 위키링크로 참조하는 곳)
rg -l '\[\[NoteName(\||\]])' "$VAULT_ROOT"

# 태그 검색
rg '#project/active(\s|$)' "$VAULT_ROOT" --type md

# 파일명으로 노트 찾기
fd 'TDD' "$VAULT_ROOT" -e md
```

## 폴더 구조 (현재 vault — balcony-docs, 2026-06-05 기준)

| 폴더 | 용도 | 권한 |
|------|------|------|
| `balcony-backend/` | balcony-backend 프로젝트 분석/룰/매핑/도메인 분석 (문서 목록은 로컬 vault 참조) | 읽기/쓰기 |
| `daily-work/` | 일자별 작업 로그 (`YYYY-MM-DD.md` 형식) | 읽기/쓰기 |
| `domain-knowledge/` | 용어집·키워드 사전 등 도메인 지식 일반 | 읽기/쓰기 |
| `.obsidian/` | Obsidian 설정 | **건드리지 말 것** |
| `.DS_Store` | macOS 시스템 파일 | **건드리지 말 것** |

> Zettelkasten 표준(`000-SLIPBOX`/`001-INBOX` 등)은 본 vault 미사용. 새 1-depth 폴더 추가는 사용자 확인 후. 본 표가 SSOT.

신규 노트 기본 저장 위치 — 명시적 지시가 없으면 주제별 매핑:
- balcony-backend 프로젝트 관련 → `balcony-backend/`
- 일자별 로그 → `daily-work/`
- 용어·도메인 지식 → `domain-knowledge/`

## Hierarchical Tags

- 형식: `#category/subcategory/detail`
- 카테고리 5종: Topic / Document Type / Source / Status / Project
- 예: `#topic/tdd`, `#type/article`, `#source/web`, `#status/draft`, `#project/payment-refund`

## 토큰 최적화 (vault 작업 한정)

`rules/token-optimization.md` 의 일반 원칙에 더해:

1. **한 번에 10개 이하 파일만 처리** — vault 전체 스캔 금지
2. **`archive/`, `.obsidian/`, `ATTACHMENTS/`(이미지) 무시**
3. **MOC(Map of Content) 노트가 있으면 먼저 읽고** 거기서 가리키는 노트만 선택적 로드
4. **frontmatter 만 필요하면 Read 대신 `rg --max-count 1 -A 10 '^---$'`** 로 첫 블록만 추출
5. 20회 이상 반복 작업 후 `/compact` 권장

## 효율적 요청 패턴

```
# ❌ 비효율적 — 전체 스캔, 토큰 폭발
"vault의 모든 파일을 분석해줘"
"모든 노트의 주제를 정리해줘"

# ✅ 효율적 — 범위·필터 명시
"003-RESOURCES에서 'kubernetes' 태그가 있는 노트 목록"
"001-INBOX의 최근 7일 노트 frontmatter만 보여줘"
"#status/draft 태그 노트 5개의 제목과 첫 문단"
```

## 노트 생성 시 frontmatter 템플릿

```yaml
---
created: 2026-04-11
modified: 2026-04-11
tags:
  - topic/<주제>
  - status/draft
source: <URL or 책 제목>
related: []
---
```

## 안티패턴

- ❌ `.obsidian/` 또는 `archive/` 폴더 수정
- ❌ vault 전체에 대해 grep 후 결과를 통째로 컨텍스트 로딩
- ❌ 이미지 첨부파일을 Read 도구로 열기 (binary)
- ❌ frontmatter 파싱을 위해 전체 파일 Read (`rg` 로 충분)
- ❌ 백링크 찾을 때 노트 한 개씩 Read (LSP 한 번 호출이면 끝)
