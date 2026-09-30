# GitHub Secret Scanning 설정 가이드

> Purpose. 레포를 GitHub 에 공개한 뒤 서버 측 가드(push protection·secret scanning) 를 켜고, 시크릿이 이미 푸시됐을 때의 복구 절차.

## Tradeoff

로컬 `pre-commit` 은 `--no-verify` 로 우회할 수 있다. GitHub push protection 은 서버에서 막으므로 마지막 방어선이다. Public 레포는 무료로 제공되므로 켜지 않을 이유가 없다.

---

## 1. 필수 설정

GitHub 레포 → Settings → Code security and analysis.

- Secret scanning: Enabled (public 레포 기본값). 확인만.
- Push protection: **Enable**. 이게 핵심.
- Dependabot alerts: Enable (선택).

## 2. 푸시가 차단됐을 때

1. 차단 메시지의 파일·라인을 확인한다.
2. 값을 제거하고 `git add` 후 `git commit --amend`.
3. 다시 푸시.

## 3. 이미 푸시된 시크릿

```bash
# 1. 키 무효화가 먼저다. GitHub PAT·Notion·Datadog 키는 각 콘솔에서 revoke.
#    claude.ai 세션 키(fetch-claude-usage.swift)는 로그아웃·재로그인.

# 2. 히스토리 제거
brew install git-filter-repo
git filter-repo --path <파일> --invert-paths      # 파일째 제거
# 문자열만 지울 때는 시크릿을 셸 히스토리에 남기지 않도록 파일로 넘긴다
#   printf 'OLD_SECRET==>REMOVED\n' > /tmp/replace.txt && git filter-repo --replace-text /tmp/replace.txt && rm /tmp/replace.txt

# 3. filter-repo 는 안전을 위해 origin remote 를 지우므로 다시 붙이고 전체 강제 푸시
git remote add origin <레포 URL>
git push --force --all && git push --force --tags
```

## 4. 로컬 가드 설치 (재확인)

```bash
brew install pre-commit detect-secrets
# pre-commit install 은 하지 않는다. 전역 core.hooksPath 의 claude/git-hooks/pre-commit 래퍼가 커밋 시 실행한다
detect-secrets scan --baseline .secrets.baseline
pre-commit run --all-files
```

## 5. 체크리스트

- [ ] Push protection 활성화
- [ ] 첫 푸시 후 Security 탭에 알림 없음
- [ ] `pre-commit run --all-files` 로컬 통과
- [ ] `.secrets.baseline` 커밋됨

## 안티패턴

- ❌ `PRE_COMMIT_DISABLE_HOOK=1` 이나 `--no-verify` 로 로컬 가드 우회 (`--no-verify` 는 로컬 훅만 건너뛰고 서버 push protection 은 우회하지 못함)
- ❌ 키 무효화 없이 히스토리만 지우기 (이미 크롤링됐다고 가정해야 함)
- ❌ 오탐이라며 push protection 자체를 끄기 (baseline 으로 항목별 처리)
