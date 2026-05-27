# Claude MCP 서버 설정

## 설치된 MCP 서버 목록

| 서버명 | 타입 | 패키지 | 용도 |
|--------|------|--------|------|
| jetbrains | stdio | `@jetbrains/mcp-proxy` | IntelliJ 등 JetBrains IDE 연동 |
| github | stdio | `@modelcontextprotocol/server-github` | GitHub 이슈/PR/코드 조회 |
| atlassian | HTTP | `mcp.atlassian.com` | Jira, Confluence 연동 |
| mysql-mcp-server | stdio | `awslabs.mysql-mcp-server` | AWS RDS MySQL 읽기 전용 조회 |
| taskmaster-ai | stdio | `task-master-ai` | AI 기반 태스크 관리 |
| mcp-installer | stdio | `@anaisbetts/mcp-installer` | MCP 서버 설치 도우미 |
| sequential-thinking | stdio | `@modelcontextprotocol/server-sequential-thinking` | 단계적 사고 지원 |
| browsermcp | stdio | `@browsermcp/mcp` | 브라우저 자동화 |
| context7 | stdio | `@upstash/context7-mcp` | 라이브러리 최신 문서 조회 |
| notion | stdio | `@notionhq/notion-mcp-server` | Notion 페이지/DB 연동 |
| datadog-mcp | HTTP | `mcp.datadoghq.com` | Datadog 로그/모니터 조회 |
| playwright | stdio | `@playwright/mcp` | 브라우저 자동화 (Playwright) |
| claude.ai Gmail | HTTP | `gmail.mcp.claude.com` | Gmail 연동 (OAuth) |
| claude.ai Google Calendar | HTTP | `gcal.mcp.claude.com` | Google Calendar 연동 (OAuth) |

## 복원 방법 (새 PC 세팅)

### 1. 환경변수 설정
```bash
cp ~/LLM-Dot-files/claude/mcp/.env.example ~/LLM-Dot-files/claude/mcp/.env
# .env 파일에 실제 값 입력
```

### 2. MCP 서버 일괄 등록
```bash
# 인증 불필요 서버
claude mcp add jetbrains -s user -- npx -y @jetbrains/mcp-proxy
claude mcp add mcp-installer -s user -- npx @anaisbetts/mcp-installer
claude mcp add sequential-thinking -s user -- npx -y @modelcontextprotocol/server-sequential-thinking
claude mcp add browsermcp -s user -- npx @browsermcp/mcp@latest
claude mcp add playwright -s user -- npx @playwright/mcp@latest
claude mcp add context7 -s user -e DEFAULT_MINIMUM_TOKENS=6000 -- npx -y @upstash/context7-mcp
claude mcp add taskmaster-ai -s user \
  -e AWS_REGION=us-east-1 \
  -e AWS_PROFILE=default \
  -e BEDROCK_ENABLED=true \
  -e BEDROCK_MODEL_ID=us.anthropic.claude-sonnet-4-20250514-v1:0 \
  -- npx -y --package=task-master-ai task-master-ai

# 인증 필요 서버 (토큰 직접 입력)
claude mcp add github -s user \
  -e GITHUB_PERSONAL_ACCESS_TOKEN=<your_token> \
  -- npx -y @modelcontextprotocol/server-github

claude mcp add notion -s user \
  -e NOTION_TOKEN=<your_token> \
  -- npx -y @notionhq/notion-mcp-server

claude mcp add atlassian -s user --transport http https://mcp.atlassian.com/v1/mcp

# AWS MySQL (업무용 - 개인 환경에 맞게 수정)
claude mcp add mysql-mcp-server -s user \
  -e AWS_PROFILE=default \
  -e AWS_REGION=ap-northeast-2 \
  -e FASTMCP_LOG_LEVEL=ERROR \
  -- uvx awslabs.mysql-mcp-server@latest \
    --hostname <db_endpoint> \
    --secret_arn <secret_arn> \
    --database <db_name> \
    --region ap-northeast-2 \
    --readonly True

# Datadog HTTP MCP
claude mcp add datadog-mcp -s user \
  --transport http \
  --header "DD_API_KEY=<api_key>" \
  --header "DD_APPLICATION_KEY=<app_key>" \
  https://mcp.datadoghq.com/api/unstable/mcp-server/mcp
```
