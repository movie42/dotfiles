killport() { lsof -ti tcp:"$1" | xargs kill -9 }

pfx-list() {
    #: 현재 스택의 버킷/CF 정보 조회 (BUCKET, CF_DOMAIN, CF_ID, ALIASES)
    pulumi stack export 2>/dev/null | jq -r '
      .deployment.resources[]
      | select(.type == "aws:cloudfront/distribution:Distribution")
      | "\(.outputs.origins[0].domainName | split(".")[0])\t\(.outputs.domainName)\t\(.id)\t\(.outputs.aliases // [] | join(", "))"
    ' | column -t -s $'\t' | awk 'NR==1 {print "BUCKET\t\t\t\tCF_DOMAIN\t\t\t\tCF_ID\t\t\tALIASES"} {print}'
  }

# Android Emulator Launcher
emu() {
  local avd
  avd=$(emulator -list-avds 2>/dev/null | fzf --prompt="에뮬레이터 선택: " --header="실행할 AVD를 선택하세요")
  [[ -z "$avd" ]] && return
  echo "🚀 실행 중: $avd"
  emulator "@$avd" &>/dev/null &
  disown
}
