---
name: notion-summarizer
description: "Explore and summarize Notion docs via notion-cli. Use when given a Notion URL/page ID to inspect content, child pages, action items, decisions, or meeting notes."
argument-hint: "[notion-url-or-page-id]"
allowed-tools: Bash, Read, Grep, Glob
---

# /notion-summarizer — Notion 문서 탐색 및 요약

`notion-cli`로 Notion 문서를 읽고, 필요한 경우 하위 페이지를 탐색한 뒤 사용자의 언어로 구조화된 요약을 작성한다.

## Argument Parsing

- `/notion-summarizer <notion-url-or-page-id>` — 해당 Notion 문서를 가져와 요약한다.
- `/notion-summarizer <notion-url-or-page-id> full` — 하위 페이지와 관련 링크까지 1단계 우선 탐색한다.
- 인자가 없고 대화에 Notion 링크가 있으면 가장 최근 링크를 대상으로 삼는다.

## Execution

### Step 1: 접근 상태 확인

`notion-cli`가 있는지 확인하고, 인증 상태가 불확실하면 다음을 실행한다.

```bash
notion-cli whoami
```

실패하면 인증 또는 페이지 공유 권한이 필요하다고 사용자에게 알린다.

### Step 2: 본문 가져오기

대화 또는 `$ARGUMENTS`에서 Notion URL/page ID만 `TARGET`으로 분리한다. `full`, "전체", "하위 페이지" 같은 탐색 옵션은 CLI에 넘기지 않는다. 기본적으로 bundled script를 사용한다.

```bash
python3 "${CLAUDE_SKILL_DIR}/scripts/fetch_notion_markdown.py" "$TARGET" --output /tmp/notion-page.md --check-auth
```

긴 문서는 `/tmp/notion-page.md`를 `Read`, `Grep`, `rg`로 탐색한다. 원문 전체를 사용자에게 붙여넣지 않는다.

### Step 3: 구조 파악

문서에서 제목, 목적, 섹션 구조, 표, 결정 사항, 요구사항, 담당자, 날짜, 리스크, 열린 질문, 액션 아이템을 확인한다.

### Step 4: 관련 페이지 탐색

다음 조건이면 즉시 하위/관련 페이지를 1단계만 탐색한다.

| 조건 | 행동 |
|---|---|
| 사용자가 "탐색", "전체", "관련 문서", "하위 페이지"를 요청 | child block과 Notion 링크를 확인한다 |
| 본문이 하위 페이지 목차 또는 링크 중심 | 즉시 연결된 Notion 페이지를 읽는다 |
| 외부 링크 또는 무관한 데이터베이스 | 사용자 요청 없이는 따라가지 않는다 |

필요한 명령:

```bash
python3 "${CLAUDE_SKILL_DIR}/scripts/fetch_notion_markdown.py" "$TARGET" --metadata /tmp/notion-page.json --children /tmp/notion-children.json --output /tmp/notion-page.md
notion-cli search --query "<title-or-keyword>" --limit 10 --json
```

### Step 5: 요약 작성

`${CLAUDE_SKILL_DIR}/templates/summary.md`를 읽고, 문서 유형에 맞게 불필요한 섹션은 생략한다. 한국어 요청에는 한국어로 답한다.

## Rules

- Notion private content는 브라우저보다 `notion-cli`를 우선 사용한다.
- 읽은 페이지와 접근 실패한 페이지를 최종 답변에 구분한다.
- 소유자, 기한, 날짜가 원문에 없으면 추정하지 말고 "명시 없음"으로 둔다.
- 많은 페이지를 재귀적으로 크롤링해야 하면 진행 전에 범위 확인을 요청한다.
- 실패 시 실행한 명령과 stderr 요지를 짧게 포함한다.
