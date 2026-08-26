# Global Agent Rules

This file is the global root rule document for AI coding agents. Claude Code, Codex, Cursor, Aider, Pi, and other agents should read and apply this file before working.

## User Profile

Frontend web developer. Deep in React / TypeScript / Next.js; a beginner in native and non-web stacks — Java/JSP, Android Studio and the Android SDK, and React Native / Expo internals.

- For web/frontend work, skip the basics and be direct.
- For native, Java, or Android work, assume no prior knowledge: explain terminology on first use, give explicit step-by-step UI navigation ("File → Project Structure → ..."), and prefer concrete snippets over abstract description.
- Explanations in Korean; code and identifiers in English.

## Language Rules

All content written to `.claude/` must be in English. This includes skill documents, agent documents, rules, comments in code examples, string literals, placeholders, and any other text recorded in files under `.claude/`.

Exceptions where Korean is allowed:

- `README.md` at the project root
- `CHANGELOG.md` at the project root
- Skill output templates: `templates/*.md`
- Inline output examples in `SKILL.md`

## Interaction Rules

### Do Not Loop on Questions

Never end a turn with a bare "shall I do it this way?". When several approaches exist, lay out the options with trade-offs and name a recommendation in a single message.

Do not re-ask about anything the user already answered, or anything that already has a default in memory, `AGENTS.md`, `CLAUDE.md`, or earlier in the conversation. If a reasonable default exists, proceed on it and confirm once — do not ask defensively "in case there is another option".

### Confirm Before Irreversible Action on Ambiguous Intent

When the user asks a question or points something out, decide whether it is a request to change something or a request for information. If ambiguous, report the current state and ask — do not delete or rewrite on your own reading. This is the one case that overrides "do not loop on questions": the cost of guessing wrong is unrecoverable.

Never run `git checkout`, `git restore`, or other revert commands unless the user explicitly asked. Edits already applied stay applied until the user says to undo them.

### Say Upfront When Something Cannot Work

If a requested output format or approach will not work, say so in the first reply along with the working alternative. Do not build the artifact and then spend the session patching tooling around the gap.

When a tool fails 2–3 times, stop and present options instead of patching deeper. An interactive login or a global install is a signal the approach is too heavy, not a step to push through. Prefer the boring manual path when it costs the user minutes versus an uncertain automation chain.

### Explain in Plain Terms, or Not at All

Write for someone who did not implement the thing. Terms that only make sense after reading the code — serialization formats, protocol details, library internals, framework behavior — either get a sentence explaining what they are and why they matter here, or get left out.

- Background first, conclusion second. Start from the situation anyone can observe, then the choice made.
- Three sentences is the ceiling for a "why" explanation. If the background needs more, drop the whole point to one line instead — one clear line beats a paragraph that gets skipped.
- A paragraph the reader can only follow after reading the diff has failed. Delete it rather than shipping it.
- No filler: 전반적으로, ~등을 개선, 안정성 향상, 코드 정리.

This applies to chat replies, PR bodies, plan documents, and progress notes alike.

### Naming Discipline in Proposals

Do not reuse a loaded word for an unrelated axis. Concretely: never call a build artifact "prod" — environment (`local`/`stg`) and server mode (`dev`/`build`) are independent axes, and "prod" reads as a connection to the production backend. State that two axes are independent before proposing anything that spans them.

## Git Rules

### Commit Messages

Written in Korean unless the user explicitly asks for another language.

- Prefixes: `feat:` (feature), `fix:` / `hotfix:` (bug), `chore:`, `refactor:`, `docs:`
- Type only — no parenthesized scope. `feat:` is correct, `feat(shared):` is not. Existing log entries may contain scopes; do not copy that form.
- Do not include issue numbers.
- Do not include `Co-Authored-By`.
- When a plan document pre-writes commit titles, apply the same form there — plan titles get copied verbatim at implementation time.

### Commit Scope

Never ask which files to include. Stage everything — staged, unstaged, and untracked — and commit. Files under `docs/` are always included; plan documents are tracked alongside the code change.

### Verify the Branch Before Committing

A worktree can be shared by several concurrent agent sessions, so the branch recorded at session start goes stale. Run `git branch --show-current` immediately before any commit or branch creation instead of trusting session-start information.

If a file changes underneath you and the content differs from what you read, check whether the branch switched before writing it off as a linter fix — that is often the only visible signal. Line numbers pinned in plan docs (`file.ts:42`) drift by a line or two between branches. Do not switch another session's branch; chain new work off the current one.

### Pull Requests

- Base branch defaults to `develop`, not `master`/`main`. Confirm if the repo has no `develop`.
- Check for an existing PR first (`gh pr list --head <branch>`); if one exists, return its URL instead of opening another.
- Use the `/git-pr` skill's body template and rules. Keep the whole body to roughly one screen — five sections (구현사항 / 특이사항 / 핵심 리뷰 포인트 / 구현 화면 / 테스트 케이스), 3–6 bullets each, one line per point. Design rationale and comparison tables belong in `docs/<feature>/plans/`; the PR just points there.
- Leave the 구현 화면 table empty — the user fills it.
- Pass the body with `--body-file`, never inline `--body "..."` (backticks and mermaid break under shell interpolation).

### Attaching Media to a PR

- Images: upload with the `gh attach` extension. Create the PR first to get its number, then `gh attach --issue <PR#> --image ./shot.png --url-only` and embed the returned URL. Do not ask the user where to upload. `--issue` is required even in url-only mode; direct mode is configured in `~/.config/gh-attach/config`.
- Videos: there is no API path. GitHub mints `user-attachments/assets` URLs only from a browser drag-and-drop, and `gh attach` is image-only. Ask the user to drag the files in and paste the URLs back.
- A video renders as a player only when its URL sits alone on its own line — inside a table cell it degrades to a plain link. Use heading sections (`## 시나리오 N` → `### before` → `### after`) rather than a before/after table.

## Task Planning Rules

### `/task-plan` Skill Usage

When the user requests new feature development, bug fixes, or similar implementation tasks, ask first whether they want to create a task plan with the `/task-plan` skill or proceed directly. Ask with this exact wording:

> "/task-plan skill을 사용해서 작업 계획을 먼저 세울까요, 아니면 바로 진행할까요?"

- If the user says no planning is needed, proceed directly.
- If the user wants a plan, run the `/task-plan` skill.
- If the user attaches a design document or requirements, analyze them and feed them into the skill flow.

Direction changes, PR creation rules, and PRD update rules are defined in the `/task-plan` skill.

### Merge Into an In-Flight Plan

When a new request is really a gap or refinement of a plan that is still 대기/진행중, fold it into that plan's `tasks.md`/`spec.md`. Do not create a separate `docs/<name>/plans/` folder with a `참조:` link — that pattern is for modifying an already-shipped feature.

### Keep Follow-Up Entries Terse

Follow-up sections in `tasks.md` contain the metadata line, a `## 변경` bullet list of files touched and what changed, and at most one caveat line. No 개요, no 배경, no 유지/가정, no narrative progress log.

### Interview Scope

When interviewing the user about a plan (`/grill-me` and similar), cover design and scope trade-offs only. PR splitting, commit granularity, work sequence, branch naming, and reviewer routing are the user's call, not interview material. Filter each candidate question by: does this change the visual result, the structure, or the API — or only the order of work? If only the order, drop it.

## Implementation Rules

### No Code Comments

Do not add comments to code. Add a comment only when the user explicitly requests it. Record rationale, background, and change history in the related docs (`docs/`), not in code comments. This applies even when surrounding code already contains comments — do not introduce new ones.

### Do Not Remove console Logging

`console.log` / `warn` / `error` are left in deliberately for debugging. Never remove them as cleanup during refactors, logger migrations, or any other task — only on an explicit request.

### Copy User-Facing Text Verbatim

Copy notices, consent text, privacy policy, alerts, and labels exactly as written in the PRD. Never paraphrase, summarize, or invent a string. If the PRD does not specify it, ask rather than writing one — this is critical for legally sensitive text.

### Direct Implementation, No Sub-agents

All code changes are executed directly in the main conversation. Do not spawn sub-agents for implementation.

- Follow `.claude/rules/react-typescript.md` for frontend code.
- Follow existing patterns discovered during codebase exploration.
- When using `/implement`, the skill orchestrates phases, but code is written directly and not delegated.

The general principle: a delegated step's completion depends on the agent's response, which is not guaranteed — failures surface only when you check the filesystem by hand. Design loops so each step is decided by a command's exit code or a file's existence, and keep the procedure in a skill or document that the main conversation executes. When proposing new automation, reach for "let's define the gate command", not "let's hand this to an agent".

### Exceptions: Direct Edits Without Agents

The following changes may be handled directly:

- Config file changes such as `package.json`, `tsconfig.json`, `.env`, and similar files
- Documentation file changes: `*.md`
- Simple typo or naming fixes of one or two lines
- Import path corrections
- Lint or format fixes

### A Missing Backend Is Not a Reason to Stop

Absence of a backend contract does not gate the start of work. Stand up an in-memory stub, finish everything the UI and client can do, and swap the real API in later. Record the gap in both the docs and the screen itself (a dev-notice panel).

Do not write `⛔ 착수 불가` / "waiting on backend" gates into plans. Status is either ✅ (actually usable) or 🟡 (stub — screen stands only), and gap tables mean "is it usable", not "can we start". Give the sub-plan a Phase 0 rollback checklist.

### Do Not Change Shared Primitives

When a design differs from what a shared primitive (`components/ui/*` and equivalents) renders, scope the fix to the feature component and leave the mismatch. Report the deviation explicitly — name the primitive, the delta, and the screens a change would affect — and do not re-raise it later. Change the primitive only when the request is specifically about the design system.

### Promote Only on a Real Second Caller

Promoting across layers (feature → widget → shared) happens only when a second caller exists in the code today. "It looks domain-agnostic" and "this seems reusable" are not reasons. A promise that a second screen is coming does not count until that screen exists.

Grep for callers before proposing a promotion. With one caller, the module lives next to that caller. One adapter is a hypothetical seam; two adapters is a real seam — a prematurely shared component ends up carrying its original caller's validation copy, layout, and tone, and the second caller adds branches until nobody dares touch it.

### No Wildcard Exports

Never use `export * from "..."` in a barrel (`index.ts`) or at any other export point. Use explicit named exports. The public API must be a deliberate selection — a wildcard drags helpers, types, and temporary exports into it and makes the module boundary untraceable.

### No Hardcoded Colors

Always use the project's color tokens (`theme.colors.*`, CSS custom properties, Tailwind token classes). Never hardcode a hex value. Map hex values from a design file to the project's token definitions rather than pasting them.

### No Inline Styles

Never use `style={{}}`. In styled-components projects create a styled component, or drive child styling from a top-level styled container via className / nested selectors. In Tailwind projects use utility classes per the project's conventions. This includes `display: none` (hidden inputs and similar). Convert inline styles you encounter in code you are already editing.

### UI State Is the Source of Truth for URL Sync

When designing URL state synchronization:

1. UI state is the source of truth. UI behavior must not depend on how the URL parses.
2. The URL syncs to the UI, never the reverse. The URL is a derived view.
3. URL → UI only happens at entry points: initial mount, and external URL changes (back button, deep link).

The two directions are asymmetric in rank: the UI → URL transform is the primary rule invoked on every change, while URL → UI parsing is a secondary override used only when a backend's payload shape defeats the default. Reflect that ranking in JSDoc and docs too.

### Releasing a Click Lock Around Navigation

For a headless button holding an internal lock alongside an external `pending` prop, release the lock from the caller's `catch` — that is, make the action handler throw on failure. Do not use `finally`.

On success the mutation completes, `pending` flips for the navigation transition, and there is a window where `pending` is false but the component has not unmounted; a `finally` release inside that window allows a double-click that re-fires the mutation. A `catch`-based release holds the lock until natural unmount while still clearing on error so retry works.

If the lock gets stuck, the cause is usually a callee swallowing errors in an empty `try/catch {}` — fix the callee so the error propagates. The inner code should already have shown its toast or closed its modal before throwing; the caller needs the throw as a signal, not as UI handling.

## Design Reference Rules

### Scan the Design Directly Before Implementing

When a task document carries a Figma node ID or `figma.com` URL and the work is UI, scan the source before writing code — do not implement from the spec's prose or from a guess. Text descriptions of paths, dimensions, and colors are frequently the output of someone else's guess and mismatch the original: an arc that is actually a cubic Bézier, an absolute overlay that is actually a flex sibling, a `w-full` that is actually `flex-1`.

Do not write "design verified" until you have actually pulled the design, not just grepped a token value.

### Scan at Implementation Time Only

During planning (`/task-plan`, `/grill-me`, design conversations), record the Figma link as text in the spec and do not scan. Scanning belongs to the implementation step. Repeated scans during planning waste context and time.

### Token Names Drift From Token Values

A Figma variable and a project CSS token can share a name and hold different values. Never reason "Figma calls it X, so use the project's X token". Extract the actual hex from the design file, then find the matching value in the project's global stylesheet and map to that token.

When writing a color mapping table, include the source hex as its own column. Do not assume two design systems are in sync — it varies per project.

## React Native / Expo Rules

- **Do not blanket-recommend prebuild.** JS/TS changes need only an app restart. Prebuild is required only for native changes: `app.config.ts` plugins, `plugins/`, `AndroidManifest`, and similar. Always say which case applies.
- **Diagnose Android notifications as a whole.** iOS gets APNs handling for free; Android needs the notification channel, the FCM `default_notification_channel_id` meta-data, and the `POST_NOTIFICATIONS` permission all present. Check all three as a checklist and propose one combined fix rather than iterating symptom by symptom.
- **Screen-entry performance is about mount storms, not memoization.** `CommonActions.reset` remounts a whole tree at once and is a common cause of a JS-thread spike; replacing it with sequential `navigate` calls avoids remounting what is already mounted. `useMemo` / `React.memo` / `FastImage` are typically irrelevant here — measure before touching them.
- **Never set `maxLength` on `TextInput` on Android** — it triggers a render update loop. Enforce length with a controlled value and `onChangeText` slicing.
- **RN 0.79 Yoga layout crash:** when many sibling nodes change size simultaneously, the native side aborts with nothing in the JS log. Stagger or restructure the layout change.

## Jira Rules

### Jira Cloud Description Updates

When writing Jira Cloud issue descriptions from local markdown, use the Atlassian CLI (`acli`) when available.

- Check authentication with `acli jira auth status`.
- Update descriptions with `acli jira workitem edit --key "<ISSUE-KEY>" --description-file "<file>" --yes`.
- Prefer Atlassian Document Format (ADF) JSON for Jira descriptions instead of raw markdown text.
- Convert markdown headings, paragraphs, ordered lists, bullet lists, code spans, horizontal rules, and tables to ordinary ADF nodes.
- Do not use ADF `taskList` or `taskItem` for checklist-style acceptance criteria when humans will edit the description in Jira. In practice, Jira can render those from CLI updates, but manual editing can break or destabilize the description.
- Represent checklist items as ordinary bullet list items whose text starts with `[ ]`, for example `[ ] The acceptance condition text`.
- After updating, verify that the description contains `0` `taskItem` nodes and expected heading/list nodes with:
  `acli jira workitem view <ISSUE-KEY> --fields description --json`.

## Local Environment Notes

- **yarn requires nvm first.** yarn lives inside the nvm-managed Node install and is not on the default shell PATH. Prefix with `export NVM_DIR="$HOME/.nvm" && source "$NVM_DIR/nvm.sh" && nvm use && yarn ...`.
- **HWP files:** no built-in reader. `pyhwp` is installed via pipx (`pipx install pyhwp` + `pipx inject pyhwp six`). `hwp5txt <file>` gives text but loses tables (renders `<표>`); prefer `hwp5html <file> --output <dir>` for tables and images.
- **Next.js middleware** must live in `middleware.ts` at the project root and export a function named `middleware` or `default`. Any other export name (e.g. `proxy`) fails at build.

## Claude Code Specific Rules

Applies to Claude Code only. Other agents can skip this section.

### Skills

- **Browser verification** — use the `browse` skill (headless Playwright) and log in as the agent. Do not open the `claude-in-chrome` MCP and do not ask the user to log in by hand. Load credentials from the repo's `.env.local` and pass them as shell variables (`$B fill "input[name=password]" "$ADMIN_PW"`) so plaintext never lands in a command line or report. Refs like `@e1` die after hydration — use CSS selectors. `$B js` swallows output on multiline or object-array returns; stash the result on `window.__x` and read it back with `JSON.stringify` in the next command. Port 3000 may be held by another project — check with `lsof` and pick a free port.
- **`/git-pr`** is `disable-model-invocation: true`, so it cannot be called with the Skill tool. Either suggest the user run `/git-pr`, or read the skill's template and rules and follow them directly. Same for the `/task-plan` conventions recorded above under Task Planning Rules.
- **Calendar** — "캘린더에 일정 넣어줘" means the `apple-calendar` skill (macOS Calendar). Use the Google Calendar MCP only when the user explicitly says 구글 캘린더 / Google Calendar. Calendar names like "Work" are Apple Calendar names.

### MCP Servers

- **Figma** — the scan rules are above under Design Reference Rules. The concrete calls are `mcp__plugin_figma_figma__get_design_context` + `get_screenshot`, plus `get_variable_defs` for token values.
- **Datadog** — the MCP server connects and authenticates but exposes only onboarding and DDSQL-schema tools for this org; every telemetry-query tool is absent. This is org-level toolset enrollment, not a permissions problem, so do not re-diagnose it. Use the REST API instead: pull the OAuth token from `security find-generic-password -s "Claude Code-credentials" -w` (JSON key `mcpOAuth.datadog|<hash>.accessToken`) and call `api.datadoghq.com` directly — `POST /api/v2/logs/events/search`, `POST /api/v2/logs/analytics/aggregate` (no `sort` inside `group_by`; sort client-side), `POST /api/v2/spans/events/search`. `GET /api/v1/validate` returning 403 is expected. The token expires roughly hourly; re-auth with `/mcp`.

### Status Line

`~/.config/ccstatusline/settings.json` (v2.2.x) has three traps:

- A global `defaultSeparator` set to a glyph other than `|`, `,`, `-`, or space prints three times. Put custom glyphs on each separator widget's `character` (including surrounding spaces) and leave the global key empty.
- A Custom Text widget reads the top-level `customText` key, not `metadata.text` — the wrong key renders empty with no error.
- `merge: true` joins with the **next** widget. Git widgets accept an emoji via `character`, but `rawValue: true` drops the symbol entirely.

Render check: `printf '{"cwd":"...","model":{"display_name":"Opus 5"},"workspace":{"current_dir":"..."}}' | ~/.bun/bin/ccstatusline`
