#!/usr/bin/env bash

DOTFILES="$HOME/dotfiles"
REPO="https://github.com/movie42/dotfiles.git"
FAILURES=()

log()  { printf '\n\033[1m▶ %s\033[0m\n' "$1"; }
ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; }
skip() { printf '  \033[2m-\033[0m %s\n' "$1"; }
fail() { printf '  \033[33m!\033[0m %s\n' "$1"; FAILURES+=("$1"); }

log "Homebrew"
if command -v brew >/dev/null 2>&1; then
  skip "이미 설치됨"
else
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
    || fail "Homebrew 설치 실패"
fi

if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

if ! command -v brew >/dev/null 2>&1; then
  printf '\n\033[31mbrew를 찾을 수 없어 중단합니다.\033[0m\n'
  exit 1
fi

log "저장소"
if [ -d "$DOTFILES/.git" ]; then
  skip "$DOTFILES 이미 있음"
else
  git clone "$REPO" "$DOTFILES" || { printf '\n\033[31mclone 실패 — 중단합니다.\033[0m\n'; exit 1; }
  ok "clone 완료"
fi

log "Homebrew 패키지"
brew bundle --file="$DOTFILES/Brewfile" || fail "brew bundle에서 일부 패키지가 실패했습니다"

log "oh-my-zsh"
if [ -d "$HOME/.oh-my-zsh" ]; then
  skip "이미 설치됨"
else
  RUNZSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
    || fail "oh-my-zsh 설치 실패"
fi

link() {
  local src="$DOTFILES/$1" dst="$2" backup
  if [ ! -e "$src" ]; then
    fail "저장소에 $1 이(가) 없습니다"
    return
  fi
  mkdir -p "$(dirname "$dst")"
  if [ -L "$dst" ]; then
    if [ "$(readlink "$dst")" = "$src" ]; then
      skip "$dst"
      return
    fi
    rm "$dst"
  elif [ -e "$dst" ]; then
    backup="$dst.bak"
    [ -e "$backup" ] && backup="$dst.bak.$(date +%Y%m%d%H%M%S)"
    mv "$dst" "$backup" || { fail "$dst 백업 실패"; return; }
    printf '  \033[2m기존 파일을 %s 로 옮김\033[0m\n' "$backup"
  fi
  ln -sfn "$src" "$dst" && ok "$dst" || fail "$dst 링크 실패"
}

log "심링크"
link zsh/zshrc               "$HOME/.zshrc"
link zsh/zprofile            "$HOME/.zprofile"
link git/gitconfig           "$HOME/.gitconfig"
link git/gitignore_global    "$HOME/.gitignore_global"
link claude/AGENTS.md        "$HOME/AGENTS.md"
link claude/CLAUDE.md        "$HOME/.claude/CLAUDE.md"
link claude/settings.json    "$HOME/.claude/settings.json"
link claude/rules            "$HOME/.claude/rules"
link claude/skills           "$HOME/.claude/skills"
link bin/git-status-preview  "$HOME/.local/bin/git-status-preview"

for dir in "$DOTFILES"/config/*/; do
  name=$(basename "$dir")
  link "config/$name" "$HOME/.config/$name"
done

VSCODE_USER="$HOME/Library/Application Support/Code/User"
link vscode/settings.json    "$VSCODE_USER/settings.json"
link vscode/keybindings.json "$VSCODE_USER/keybindings.json"

log "Node"
export NVM_DIR="$HOME/.nvm"
mkdir -p "$NVM_DIR"
if [ -s "$(brew --prefix nvm)/nvm.sh" ]; then
  # shellcheck disable=SC1091
  . "$(brew --prefix nvm)/nvm.sh"
  if nvm ls --no-colors 2>/dev/null | grep -q 'lts'; then
    skip "LTS 이미 설치됨"
  else
    nvm install --lts || fail "nvm install --lts 실패"
  fi
  nvm use --lts >/dev/null 2>&1
else
  fail "nvm을 찾을 수 없습니다 — brew bundle이 실패했는지 확인하세요"
fi

if command -v npm >/dev/null 2>&1; then
  for pkg in yarn corepack eas-cli @coastal-programs/notion-cli @playwright/cli; do
    if npm ls -g --depth=0 "$pkg" >/dev/null 2>&1; then
      skip "$pkg"
    else
      npm install -g "$pkg" >/dev/null 2>&1 && ok "$pkg" || fail "npm 전역 설치 실패: $pkg"
    fi
  done
else
  fail "npm이 없어 전역 패키지를 건너뜁니다"
fi

log "bun"
if command -v bun >/dev/null 2>&1 || [ -x "$HOME/.bun/bin/bun" ]; then
  skip "이미 설치됨"
else
  curl -fsSL https://bun.sh/install | bash || fail "bun 설치 실패"
fi

log "머신별 설정 파일"
for pair in "zshrc.local.example:$HOME/.zshrc.local" "git/gitconfig.local.example:$HOME/.gitconfig.local"; do
  example="$DOTFILES/${pair%%:*}"
  target="${pair#*:}"
  if [ -e "$target" ]; then
    skip "$target 이미 있음"
  elif cp "$example" "$target"; then
    chmod 600 "$target"
    ok "$target 생성 — 값을 채워야 합니다"
  else
    fail "$target 생성 실패"
  fi
done

printf '\n\033[1m설치 끝. 남은 일은 직접 해야 합니다.\033[0m\n\n'
cat <<'EOF'
  1. ~/.zshrc.local    AWS 프로필, Pulumi 패스프레이즈를 채운다
  2. ~/.gitconfig.local  커밋 이름과 이메일을 채운다 (비면 git이 커밋을 거부한다)
  3. gh auth login / aws configure
  4. SSH 키 생성 후 GitHub에 등록
  5. Xcode 설치 (App Store), Android Studio 첫 실행 시 SDK 내려받기
  6. macOS 시스템 설정 (키보드, 트랙패드, Dock)

  터미널을 새로 열면 새 설정이 적용됩니다.

  그 다음 검증:  ~/dotfiles/verify.sh
  전부 통과하면 0, 하나라도 실패하면 1로 끝납니다.
EOF

if [ ${#FAILURES[@]} -gt 0 ]; then
  printf '\n\033[33m실패한 항목 %s개:\033[0m\n' "${#FAILURES[@]}"
  for f in "${FAILURES[@]}"; do printf '  - %s\n' "$f"; done
  exit 1
fi
