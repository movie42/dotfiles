typeset -U path PATH

if [[ -x /opt/homebrew/bin/brew ]]; then
  export HOMEBREW_PREFIX=/opt/homebrew
else
  export HOMEBREW_PREFIX=/usr/local
fi

export JAVA_HOME="$HOMEBREW_PREFIX/opt/openjdk@17"

export ANDROID_SDK_ROOT="$HOME/Library/Android/sdk"
export ANDROID_HOME="$ANDROID_SDK_ROOT"

export PNPM_HOME="$HOME/Library/pnpm"
export BUN_INSTALL="$HOME/.bun"

path=(
  "$JAVA_HOME/bin"
  "$HOMEBREW_PREFIX/opt/ruby/bin"
  "$HOMEBREW_PREFIX/opt/mysql-client/bin"
  "$HOMEBREW_PREFIX/bin"
  "$HOMEBREW_PREFIX/sbin"
  "$HOME/.local/bin"
  "$HOME/.cargo/bin"
  "$BUN_INSTALL/bin"
  "$PNPM_HOME"
  "$HOME/.flashlight/bin"
  "$HOME/.ai-skills/bin"
  "$HOME/.maestro/bin"
  "$ANDROID_SDK_ROOT/emulator"
  "$ANDROID_SDK_ROOT/platform-tools"
  "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin"
  $path
)
