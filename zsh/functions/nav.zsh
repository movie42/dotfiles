# fcd
fcd() {
  local dir
  local base="${1:-.}"
  while true; do
    dir=$({ echo ".."; find "$base" -maxdepth 3 -type d \( -name 'node_modules' -prune \) -o -type d -not -path '*/\.*' -print 2> /dev/null; } | fzf +m)
    [[ -z "$dir" ]] && return  # ESC나 취소시 종료
    if [[ "$dir" == ".." ]]; then
      base="$(dirname "$(realpath "$base")")"
    else
      cd "$dir" && return
    fi
  done
}

# fzcd - zoxide(자주가는곳) + local(현재위치 디렉토리 탐색) 전환
# tab: 모드 전환 | ctrl-u: 상위로 이동 (local 모드)
fzcd() {
  local mode="zoxide" base="." result
  while true; do
    if [[ "$mode" == "zoxide" ]]; then
      result=$(zoxide query -l 2>/dev/null | \
        fzf --prompt="[zoxide] cd> " \
            --header="tab: local 모드 전환" \
            --preview 'ls {}' \
            --bind "tab:become(echo __TOGGLE__)" \
      )
    else
      result=$({ echo ".."; find "$base" -maxdepth 4 -type d \
        \( -name 'node_modules' -o -name '.git' -o -name '.yarn' -o -name '.gradle' -o -name 'target' -o -name '.next' -o -name '__pycache__' \) -prune \
        -o -type d -not -path '*/\.*' -print 2>/dev/null; } | \
        fzf --prompt="[local:${base}] cd> " \
            --header="tab: zoxide 모드 전환 | ctrl-u: 상위로" \
            --preview 'ls {}' \
            --bind "tab:become(echo __TOGGLE__)" \
            --bind "ctrl-u:become(echo __GO_UP__)" \
      )
    fi

    case "$result" in
      __TOGGLE__)
        if [[ "$mode" == "zoxide" ]]; then mode="local"; base="."
        else mode="zoxide"; fi ;;
      __GO_UP__) base="$(dirname "$(realpath "$base")")" ;;
      ..) base="$(dirname "$(realpath "$base")")" ;;
      "") return ;;
      *) cd "$result" && return ;;
    esac
  done
}
