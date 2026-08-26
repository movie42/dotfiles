---
name: tm
description: "Explain how a technology works step by step, pausing after each chunk with '이해 됐나요?' to confirm understanding before continuing. Triggered ONLY by explicit /tm — never auto-activated, even when the user asks 'how does X work' during implementation."
argument-hint: "<topic or question>"
disable-model-invocation: true
---

# /tm — Step-by-Step Teaching Mode

Walk the user through a technical topic one digestible chunk at a time, confirming comprehension after each chunk before continuing.

## Argument Parsing

- `/tm <topic>` — the topic/question to explain (e.g. `/tm React fiber 리렌더링`)
- `/tm` with no argument — ask the user what they want explained, then proceed

`$ARGUMENTS` holds the raw input.

## Execution

### Step 1: Frame the Topic

Before explaining, do two things:

1. State the topic in one sentence so the user can confirm scope ("React fiber의 리렌더링 동작 원리를 설명할게요.").
2. Outline the chunks you plan to cover as a short numbered list (3–6 items). This is the roadmap — do not explain yet.

Then ask: **"이 순서로 가도 될까요?"** Wait for the user's response.

If the user adjusts the roadmap, update it and re-confirm. If they say go, move to Step 2.

### Step 2: Explain One Chunk

Pick the next chunk from the roadmap. Explain only that chunk.

Rules for a chunk:

| Constraint | Why |
|---|---|
| One concept per chunk | Comprehension check must map to one idea |
| ≤ 8 lines of prose, or ≤ 15 lines with a small code/diagram example | Avoid wall-of-text |
| Use concrete examples or analogies before abstract definitions | Lower entry cost |
| Show the chunk number — e.g. `[2/5] Virtual DOM diff` | User tracks progress |

After the explanation, end the message with exactly:

```
이해 됐나요?
```

Do not append anything after this line. Stop and wait.

### Step 3: Branch on the User's Response

| User says | Action |
|---|---|
| "네" / "응" / "ok" / "이해했어" / equivalent | Go to Step 2 for the next chunk |
| "아니" / "잘 모르겠어" / asks a follow-up question | Re-explain the **same chunk** differently — try a new analogy, a code example, or break the chunk into smaller pieces. Then ask "이해 됐나요?" again |
| "다음" / "skip" / "넘어가자" | Mark current chunk as skipped, move to next |
| "그만" / "끝" / "stop" | Go to Step 4 (early end) |
| Asks about a topic outside the roadmap | Briefly answer (≤ 3 lines), then ask "원래 로드맵으로 돌아갈까요, 아니면 이 주제로 갈아탈까요?" |

### Step 4: Wrap Up

When all chunks are covered (or the user stops early):

1. List what was covered as a one-line summary per chunk.
2. Mention any chunk that was skipped or left unfinished.
3. Ask if the user wants to dive deeper into any specific chunk.

Do not auto-suggest unrelated topics.

## Output Style

Example of a single chunk message:

```
[2/5] Virtual DOM diff

React는 새 렌더 결과(VDOM 트리)와 이전 트리를 노드 단위로 비교해서,
바뀐 부분만 실제 DOM에 반영합니다. 전체 트리를 다시 그리지 않는 게 핵심이에요.

예: <ul>의 자식 5개 중 1개만 텍스트가 바뀌면, React는 그 <li> 하나의
textContent만 업데이트하고 나머지 4개는 건드리지 않습니다.

이해 됐나요?
```

## Rules

- Never explain more than one chunk per message. The teaching pace is one chunk → one comprehension check.
- Never skip the "이해 됐나요?" prompt. It is the contract of this skill.
- Never auto-trigger this skill. `/tm` must be explicitly invoked by the user. If the user asks a "how does X work" question without `/tm`, answer normally — do not enter teaching mode.
- Do not preempt with implementation suggestions, refactors, or code changes during /tm. This is a teaching session, not a coding session.
- If the user asks an implementation question mid-session, pause teaching mode, answer it briefly, and offer to resume teaching: "여기까지 멈추고 구현으로 넘어갈까요, 아니면 설명 계속할까요?"
- Match the user's language. If they write in Korean, teach in Korean. If English, switch to English.
