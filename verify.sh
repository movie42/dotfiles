#!/usr/bin/env bash

DOTFILES="$HOME/dotfiles"
PASS=0; FAIL=0; WARN=0
FAILED_ITEMS=()

sect() { printf '\n\033[1m%s\033[0m\n' "$1"; }
ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; PASS=$((PASS+1)); }
bad()  { printf '  \033[31m✗\033[0m %s\n' "$1"; FAIL=$((FAIL+1)); FAILED_ITEMS+=("$1"); }
warn() { printf '  \033[33m!\033[0m %s\n' "$1"; WARN=$((WARN+1)); }

check_link() {
  local src="$DOTFILES/$1" dst="$2" actual
  if [ ! -L "$dst" ]; then
    if [ -e "$dst" ]; then bad "$2 — 심링크가 아니라 실제 파일"
    else bad "$2 — 없음"; fi
    return
  fi
  actual=$(readlink "$dst")
  if [ "$actual" != "$src" ]; then bad "$2 — $actual 를 가리킴"; return; fi
  if [ ! -e "$dst" ]; then bad "$2 — 끊긴 링크"; return; fi
  ok "$2"
}

check_cmd() {
  if command -v "$1" >/dev/null 2>&1; then ok "$1"; else bad "$1 — PATH에 없음"; fi
}

check_app() {
  if [ -d "/Applications/$1.app" ]; then ok "$1"; else bad "$1 — /Applications에 없음"; fi
}

sect "심링크"
check_link zsh/zshrc               "$HOME/.zshrc"
check_link zsh/zprofile            "$HOME/.zprofile"
check_link git/gitconfig           "$HOME/.gitconfig"
check_link git/gitignore_global    "$HOME/.gitignore_global"
check_link claude/AGENTS.md        "$HOME/AGENTS.md"
check_link claude/CLAUDE.md        "$HOME/.claude/CLAUDE.md"
check_link claude/settings.json    "$HOME/.claude/settings.json"
check_link claude/rules            "$HOME/.claude/rules"
check_link claude/skills           "$HOME/.claude/skills"
check_link bin/git-status-preview  "$HOME/.local/bin/git-status-preview"
check_link vscode/settings.json    "$HOME/Library/Application Support/Code/User/settings.json"
check_link vscode/keybindings.json "$HOME/Library/Application Support/Code/User/keybindings.json"
for dir in "$DOTFILES"/config/*/; do
  name=$(basename "$dir")
  check_link "config/$name" "$HOME/.config/$name"
done

sect "CLI"
for c in brew git gh delta fzf zoxide eza bat rg yazi glow pnpm pipx tmux scrcpy watchman pulumi duti tree qrencode; do
  case "$c" in
    tmux|qrencode) continue ;;
  esac
  check_cmd "$c"
done
check_cmd jq
check_cmd node
check_cmd bun

sect "GUI 앱"
for a in "Aside" "Google Chrome" "Visual Studio Code" "Orca" "Warp" "Android Studio" \
         "DBeaver" "Fork" "Figma" "Claude" "Slack" "Notion" "Rectangle" "Pritunl" \
         "Ghostty" "Flipper" "Reactotron"; do
  check_app "$a"
done

sect "셸 — 함수와 alias"
PROBE=$(zsh -i -c '
for f in git_checkout git_push git_status git_flow git_branch_delete gbsf gtd \
         gset-leaf grebase-chain gshow-leaf mypr fcd fzcd killport pfx-list emu; do
  whence -w "$f" 2>/dev/null | grep -q function || echo "FN:$f"
done
for a in ls ll tree y p gco gp gs gfl gbd prs c cr zshsource; do
  whence -w "$a" 2>/dev/null | grep -q alias || echo "AL:$a"
done
print "JAVA_HOME=$JAVA_HOME"
print "NODE=$(command -v node)"
print "PAGER=$(git config --get core.pager)"
' 2>/dev/null)

MISSING_FN=$(printf '%s\n' "$PROBE" | grep '^FN:' | cut -d: -f2 | tr '\n' ' ')
MISSING_AL=$(printf '%s\n' "$PROBE" | grep '^AL:' | cut -d: -f2 | tr '\n' ' ')
[ -z "$MISSING_FN" ] && ok "함수 16개 전부 정의됨" || bad "함수 누락: $MISSING_FN"
[ -z "$MISSING_AL" ] && ok "alias 14개 전부 정의됨" || bad "alias 누락: $MISSING_AL"

STARTUP_ERR=$(zsh -i -c 'true' 2>&1)
[ -z "$STARTUP_ERR" ] && ok "새 셸이 에러 없이 뜸" || bad "셸 시작 시 출력: $STARTUP_ERR"

sect "환경 변수와 버전"
JH=$(printf '%s\n' "$PROBE" | grep '^JAVA_HOME=' | cut -d= -f2-)
case "$JH" in
  */openjdk@17) ok "JAVA_HOME = $JH" ;;
  "")           bad "JAVA_HOME 이 비어 있음" ;;
  *)            warn "JAVA_HOME = $JH (계획은 openjdk@17)" ;;
esac

JV=$(java -version 2>&1 | head -1)
case "$JV" in
  *'"17'*) ok "java = 17" ;;
  *)       bad "java 가 17이 아님: $JV" ;;
esac

NODE_PATH_PROBE=$(printf '%s\n' "$PROBE" | grep '^NODE=' | cut -d= -f2-)
case "$NODE_PATH_PROBE" in
  *"/.nvm/versions/node/"*) ok "node = nvm 관리 ($NODE_PATH_PROBE)" ;;
  "")                       bad "node 를 찾을 수 없음" ;;
  *)                        warn "node 가 nvm 밖에 있음: $NODE_PATH_PROBE" ;;
esac

GP=$(printf '%s\n' "$PROBE" | grep '^PAGER=' | cut -d= -f2-)
[ "$GP" = "delta" ] && ok "git pager = delta" || bad "git pager 가 delta가 아님: ${GP:-없음}"

sect "git 신원"
GN=$(git config --get user.name)
GE=$(git config --get user.email)
if [ -z "$GN" ] || [ -z "$GE" ]; then
  bad "user.name / user.email 이 비어 있음 — ~/.gitconfig.local 을 채워야 커밋이 된다"
else
  ok "커밋 신원: $GN <$GE>"
fi

sect "머신별 설정 파일"
for f in "$HOME/.zshrc.local" "$HOME/.gitconfig.local"; do
  if [ ! -e "$f" ]; then bad "$f 없음"
  elif [ "$(stat -f '%A' "$f")" != "600" ]; then warn "$f 권한이 600이 아님 ($(stat -f '%A' "$f"))"
  else ok "$f"; fi
done

sect "실제로 돌려보기"
if git -C "$DOTFILES" status --short >/dev/null 2>&1; then ok "git status 동작"; else bad "git status 실패"; fi
if echo 'a' | delta >/dev/null 2>&1; then ok "delta 동작"; else bad "delta 실행 실패"; fi
if fzf --version >/dev/null 2>&1; then ok "fzf 동작"; else bad "fzf 실행 실패"; fi
if git-status-preview >/dev/null 2>&1 || [ -x "$HOME/.local/bin/git-status-preview" ]; then
  ok "git-status-preview 실행 가능"
else
  bad "git-status-preview 실행 불가 — gs 의 preview 창이 깨진다"
fi

printf '\n\033[1m결과\033[0m  통과 %s · 실패 %s · 경고 %s\n' "$PASS" "$FAIL" "$WARN"
if [ "$FAIL" -gt 0 ]; then
  printf '\n\033[31m실패 항목\033[0m\n'
  for f in "${FAILED_ITEMS[@]}"; do printf '  - %s\n' "$f"; done
  exit 1
fi
printf '\n\033[32m전부 통과했습니다.\033[0m\n'
