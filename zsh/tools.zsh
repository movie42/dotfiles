export NVM_DIR="$HOME/.nvm"
path=(${path:#$NVM_DIR/versions/node/*})
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

if command -v fzf >/dev/null && [[ -t 1 ]]; then
  source <(fzf --zsh)
fi

[ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"

source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" 2>/dev/null
source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" 2>/dev/null
