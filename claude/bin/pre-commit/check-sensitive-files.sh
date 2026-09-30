#!/usr/bin/env bash
# pre-commit 훅 — 인증서·키·실제 .env·인증 캐시·세션키 생성 파일이 스테이징되면 커밋 차단

# Usage: pre-commit 이 스테이징 파일 목록을 인자로 넘김. 확장자·이름은 대소문자 구분 없음.
# Exit: 0 없음 / 1 발견
# Reference: SECURITY.md, .gitignore

set -uo pipefail
shopt -s nocasematch

EXT_RE='\.(pem|key|p12|pfx|jks|crt|cer|keystore|p8|gpg|asc|keychain|mobileprovision)$'
ENV_RE='(^|/)\.env(\.[^/]+)?$'
# 세션 키를 소스에 박는 생성 파일(Claude Usage 앱), CLI 인증 캐시, 셸 자격 파일, SSH 개인키
NAME_RE='(^|/)(fetch-claude-usage\.swift|\.credentials\.json|auth\.json|credentials\.[a-z]+|\.envrc|\.netrc|\.npmrc|\.pypirc|id_(rsa|ed25519|ecdsa|dsa)|service-account[^/]*\.json)$'

status=0
for f in "$@"; do
  if [[ "$f" =~ $EXT_RE ]]; then
    echo "✗ $f — 인증서/키 파일은 커밋하지 않습니다."
    status=1
  elif [[ "$f" =~ $ENV_RE && ! "$f" =~ \.example$ ]]; then
    echo "✗ $f — 실제 .env 파일입니다. .env.example 템플릿만 커밋합니다."
    status=1
  elif [[ "$f" =~ $NAME_RE ]]; then
    echo "✗ $f — 인증 정보/세션 키가 들어가는 파일입니다."
    status=1
  fi
done
exit $status
