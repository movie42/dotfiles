git_checkout() {
  if [[ "$1" == "-b" && -n "$2" ]]; then
    # gco -b 브랜치명: 새 브랜치 생성 및 체크아웃
    git checkout -b "$2"
  else
    # gco: 기존 브랜치 fzf로 선택
    local branch
    branch=$(git branch --all | grep -v '\->' | sed 's/^..//' | sort | uniq | \
      fzf --preview 'git log --oneline --decorate --color=always -10 {1}' \
          --preview-window 'right:55%:wrap')

    if [ -n "$branch" ]; then
      branch=${branch#remotes/origin/}
      git checkout "$branch"
    fi
  fi
}

git_push() {
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "⚠️  git 저장소가 아닙니다"
    return 1
  fi

  local current branch
  current=$(git branch --show-current)

  branch=$({
    [ -n "$current" ] && echo "$current"
    git for-each-ref --format='%(refname:short)' refs/heads | grep -vx "$current"
  } | fzf --ansi \
        --prompt="[push] branch> " \
        --header="푸시할 브랜치 선택 (ESC 취소)" \
        --preview 'git log --oneline --decorate --color=always -10 {1}' \
        --preview-window 'right:55%:wrap')

  [ -z "$branch" ] && { echo "취소됨"; return 0; }

  local opts
  opts=$(printf '%s\n' \
    "(없음)              추가 옵션 없이 푸시" \
    "-u                  업스트림 설정 (--set-upstream)" \
    "--force-with-lease  안전한 강제 푸시" \
    "--force             강제 푸시" \
    "--no-verify         pre-push 훅 건너뛰기" \
    "--tags              태그도 함께 푸시" \
    "--dry-run           실제 푸시 없이 결과만 확인" \
    | fzf --multi --ansi \
          --prompt="[push] option> " \
          --header="추가 옵션: TAB 다중 선택 / 그냥 Enter = 옵션 없음 (ESC 취소)")

  local fzf_status=$?
  [ $fzf_status -ne 0 ] && { echo "취소됨"; return 0; }

  local -a flags
  if [ -n "$opts" ]; then
    flags=(${(f)opts})
    flags=(${flags%% *})
    flags=(${flags:#\(없음\)})
  fi

  echo "▶ git push origin $branch ${flags[*]}"
  git push origin "$branch" "${flags[@]}"
}

git_status() {
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "⚠️  git 저장소가 아닙니다"
    return 1
  fi

  setopt localoptions extendedglob
  local branch upstream header lines selected line xy fname
  local reload='reload(git -c color.status=always status -s)'

  while true; do
    lines=$(git -c color.status=always status -s)
    if [ -z "$lines" ]; then
      echo "✨ 변경사항 없음 ($(git branch --show-current))"
      return 0
    fi

    branch=$(git branch --show-current)
    upstream=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)
    header="${branch}${upstream:+ → ${upstream}}"$'\n'"enter: staged 토글 (TAB 다중) · ctrl-a: 전체 스테이징 · ctrl-u: 전체 해제 · esc: 종료"

    selected=$(print -r -- "$lines" | fzf --ansi --multi \
      --prompt="[status] " \
      --header="$header" \
      --preview 'git-status-preview {} $FZF_PREVIEW_COLUMNS' \
      --preview-window 'right:62%:wrap' \
      --bind "ctrl-a:execute-silent(git add -A)+$reload" \
      --bind "ctrl-u:execute-silent(git reset -q)+$reload")

    [ -z "$selected" ] && return 0

    print -r -- "$selected" | while IFS= read -r line; do
      [ -z "$line" ] && continue
      line=${line//$'\033'\[[0-9;]#m/}
      xy=${line[1,2]}
      fname=${line[4,-1]}
      [[ "$fname" == *" -> "* ]] && fname=${fname##* -> }
      fname=${fname%\"}
      fname=${fname#\"}

      if [[ "$xy" == "??" ]]; then
        git add -- "$fname"
      elif [[ "${xy[1]}" != " " ]]; then
        git restore --staged -- "$fname"
      else
        git add -- "$fname"
      fi
    done
  done
}

git_flow() {
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "⚠️  git 저장소가 아닙니다"
    return 1
  fi

  local branch upstream reply staged_n head_before head_after

  git_status

  staged_n=$(git diff --cached --name-only | wc -l | tr -d ' ')
  if [ "$staged_n" -eq 0 ]; then
    echo "⚠️  staged된 파일이 없습니다 — 중단"
    return 0
  fi

  echo ""
  echo "▶ staged ${staged_n}개"
  git diff --cached --name-status | sed 's/^/   /'
  echo ""
  echo -n "커밋 진행할까요? (Y/n) "
  read -r reply
  [[ "$reply" == [Nn]* ]] && { echo "중단됨 (staged 상태는 유지)"; return 0; }

  head_before=$(git rev-parse HEAD 2>/dev/null)
  git commit --verbose
  head_after=$(git rev-parse HEAD 2>/dev/null)
  if [ "$head_before" = "$head_after" ]; then
    echo "커밋되지 않음 — 중단"
    return 0
  fi
  echo "✅ 커밋 완료 $(git rev-parse --short HEAD)"

  branch=$(git branch --show-current)
  upstream=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)

  echo ""
  echo -n "푸시할까요? (Y/n) "
  read -r reply
  [[ "$reply" == [Nn]* ]] && { echo "커밋만 완료 (푸시 안 함)"; return 0; }

  if [ -z "$upstream" ]; then
    echo "▶ git push -u origin $branch"
    git push -u origin "$branch"
  else
    echo "▶ git push origin $branch"
    git push origin "$branch"
  fi
}

git_branch_delete() {
  local branches branch merged_branches
  merged_branches=$(git branch --merged master | sed 's/^[* ]*//')

  branches=$(git branch --format='%(refname:short)' | grep -v "^$(git branch --show-current)$" | while read -r b; do
    if echo "$merged_branches" | grep -qx "$b"; then
      echo "✅ [merged]    $b"
    else
      echo "⚠️  [unmerged]  $b"
    fi
  done) &&

  branch=$(echo "$branches" | fzf --multi --ansi \
    --preview 'git log --oneline -10 {-1}' \
    --header 'master 기준 머지 여부 | 삭제할 브랜치 선택 (TAB: 다중선택)') &&

  if [[ -n "$branch" ]]; then
    local selected=$(echo "$branch" | awk '{print $NF}')

    echo "\n삭제할 브랜치:"
    echo "$selected"
    echo -n "\n리모트(origin)에서도 삭제하시겠습니까? (y/N): "
    read delete_remote

    echo "$selected" | while read -r b; do
      echo "\n🗑️  로컬 삭제: $b"
      git branch -d "$b" 2>/dev/null || git branch -D "$b"

      if [[ "$delete_remote" =~ ^[Yy]$ ]]; then
        echo "🌐 리모트 삭제: $b"
        git push origin --delete "$b" 2>/dev/null && echo "✅ 완료" || echo "⚠️  리모트에 없거나 삭제 실패"
      fi
    done
  fi
}

# Git Branch Suffix - 현재 브랜치에 접미사 추가
gbsf() {
    # Git 저장소인지 확인
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "\033[0;31m❌ 현재 디렉토리는 Git 저장소가 아닙니다.\033[0m"
        return 1
    fi

    # 현재 브랜치 이름 가져오기
    local current_branch=$(git branch --show-current)

    # 색상 정의
    local RED='\033[0;31m'
    local GREEN='\033[0;32m'
    local YELLOW='\033[1;33m'
    local BLUE='\033[0;34m'
    local NC='\033[0m' # No Color

    # 현재 브랜치 표시
    echo "${BLUE}현재 브랜치: ${GREEN}${current_branch}${NC}"
    echo ""

    # 접미사 입력 받기
    echo "${YELLOW}추가할 접미사를 입력하세요 (예: dev, stg, prod):${NC}"
    read "suffix?> "

    # 입력 검증
    if [[ -z "$suffix" ]]; then
        echo "${RED}❌ 접미사를 입력해주세요.${NC}"
        return 1
    fi

    # 새 브랜치 이름 생성
    local new_branch="${current_branch}-${suffix}"

    # 브랜치 존재 여부 확인
    if git show-ref --verify --quiet "refs/heads/${new_branch}"; then
        echo "${RED}❌ 브랜치 '${new_branch}'가 이미 존재합니다.${NC}"
        echo "${YELLOW}다른 접미사를 사용하거나 기존 브랜치를 삭제해주세요.${NC}"
        return 1
    fi

    # 새 브랜치 생성 및 체크아웃 여부 확인
    echo ""
    echo "${BLUE}새 브랜치: ${GREEN}${new_branch}${NC}"
    echo "${YELLOW}이 브랜치를 생성하고 체크아웃하시겠습니까? (y/n):${NC}"
    read "confirm?> "

    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        # 새 브랜치 생성 및 체크아웃
        git checkout -b "$new_branch"
        echo "${GREEN}✅ 브랜치 '${new_branch}'가 생성되고 체크아웃되었습니다.${NC}"
    else
        # 체크아웃 없이 브랜치만 생성할지 확인
        echo "${YELLOW}브랜치만 생성하시겠습니까? (체크아웃하지 않음) (y/n):${NC}"
        read "create_only?> "

        if [[ "$create_only" =~ ^[Yy]$ ]]; then
            git branch "$new_branch"
            echo "${GREEN}✅ 브랜치 '${new_branch}'가 생성되었습니다.${NC}"
            echo "${BLUE}체크아웃하려면: ${NC}git checkout ${new_branch}"
        else
            echo "${YELLOW}취소되었습니다.${NC}"
        fi
    fi
}

gtd() {
  local tags tag
  tags=$(git tag --sort=-creatordate) &&

  if [[ -z "$tags" ]]; then
    echo "태그가 없습니다."
    return 0
  fi

  tag=$(echo "$tags" | fzf --multi --ansi \
    --preview 'git show --quiet --format="커밋: %h%n작성자: %an%n날짜: %cd%n메시지: %s" {}' \
    --header '삭제할 태그 선택 (TAB: 다중선택)') &&

  if [[ -n "$tag" ]]; then
    echo "\n삭제할 태그:"
    echo "$tag"
    echo -n "\n리모트(origin)에서도 삭제하시겠습니까? (y/N): "
    read delete_remote

    echo "$tag" | while read -r t; do
      echo "\n🗑️  로컬 삭제: $t"
      git tag -d "$t"

      if [[ "$delete_remote" =~ ^[Yy]$ ]]; then
        echo "🌐 리모트 삭제: $t"
        git push origin --delete "$t" 2>/dev/null && echo "✅ 완료" || echo "⚠️  리모트에 없거나 삭제 실패"
      fi
    done
  fi
}

gset-leaf() {
  # leaf 브랜치 설정 (현재 터미널 세션만)
  export GIT_LEAF_BRANCH="$(git branch --show-current)"
  echo "leaf 설정: $GIT_LEAF_BRANCH"
}

# leaf로 이동 후 현재 브랜치 기준 rebase
grebase-chain() {
  local current=$(git branch --show-current)

  if [ -z "$GIT_LEAF_BRANCH" ]; then
    echo "leaf가 설정 안됨. gset-leaf로 먼저 설정하세요"
    return 1
  fi

  git checkout "$GIT_LEAF_BRANCH" && git rebase --update-refs "$current"
}

# 현재 leaf 확인
gshow-leaf() {
  echo "${GIT_LEAF_BRANCH:-설정 안됨}"
}

# ── my open PRs across all repos ──────────────────────────────
mypr() {
  local limit=30 pick=0 urls=0 md=0 copy=0

  local -a usage
  usage=(
    $'\033[1mmypr\033[0m \033[2m— 내가 연 PR 전부 보기 (alias: prs)\033[0m'
    ''
    $'  \033[1musage\033[0m  mypr [-p|-u|-m|-c] [-n <count>]'
    ''
    $'  \033[33m(없음)\033[0m       레포별로 묶어서 터미널에 출력 \033[2m(기본)\033[0m'
    $'  \033[33m-p, --pick\033[0m   fzf로 하나 골라서 브라우저로 열기'
    $'  \033[33m-u, --urls\033[0m   url + 제목만 한 줄씩'
    $'  \033[33m-m, --md\033[0m     슬랙 붙여넣기용 마크다운 \033[2m(--markdown, --slack 동일)\033[0m'
    $'  \033[33m-c, --copy\033[0m   -m 출력을 클립보드에도 복사'
    $'  \033[33m-n <count>\033[0m   가져올 개수 \033[2m(기본 30, 숫자만 써도 됨: mypr 50)\033[0m'
    $'  \033[33m-h, --help\033[0m   이 도움말'
  )

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -p|--pick) pick=1 ;;
      -u|--urls) urls=1 ;;
      -m|--md|--markdown|--slack) md=1 ;;
      -c|--copy) md=1; copy=1 ;;
      -n) shift; limit="$1" ;;
      -h|--help) print -rl -- "$usage[@]"; return 0 ;;
      <->) limit="$1" ;;
      *) print -u2 "mypr: unknown option: $1"; print -u2 -rl -- "$usage[@]"; return 2 ;;
    esac
    shift
  done

  local json
  json=$(gh search prs --author "@me" --state open --limit "$limit" \
    --json number,title,repository,url,createdAt,isDraft,commentsCount) || return

  if (( pick )); then
    local sel
    sel=$(print -r -- "$json" | jq -r '
      sort_by(.repository.nameWithOwner, -.number)[]
      | "\(.url)\t\(.repository.name)  #\(.number)  \(.title)"' \
      | fzf --with-nth=2.. --delimiter=$'\t' --ansi \
            --prompt="PR> " --height=60% --reverse \
            --preview='gh pr view {1} 2>/dev/null | head -60' --preview-window=right,50%,wrap)
    [[ -n "$sel" ]] && open "${sel%%$'\t'*}"
    return
  fi

  if (( urls )); then
    print -r -- "$json" | jq -r '
      sort_by(.repository.nameWithOwner, -.number)[]
      | "\(.url)  \(.title)"'
    return
  fi

  if (( md )); then
    local out
    out=$(print -r -- "$json" | jq -r '
      def ago:
        (now - (.createdAt | fromdateiso8601)) as $s
        | if   $s < 3600   then "\(($s/60)|floor)분 전"
          elif $s < 86400  then "\(($s/3600)|floor)시간 전"
          elif $s < 604800 then "\(($s/86400)|floor)일 전"
          else "\(($s/604800)|floor)주 전" end;

      [ group_by(.repository.nameWithOwner)
        | sort_by(-length)[]
        | ( ["*\(.[0].repository.nameWithOwner)* (\(length))"]
            + [ sort_by(-.number)[]
                | "- [#\(.number) \(.title)](\(.url))"
                  + (if .isDraft then " · draft" else "" end)
                  + " · \(ago)"
                  + (if .commentsCount > 0 then " · 💬\(.commentsCount)" else "" end) ]
          )
      ] | map(join("\n")) | join("\n\n")')
    print -r -- "$out"
    if (( copy )) && command -v pbcopy >/dev/null; then
      print -r -- "$out" | pbcopy
      print -u2 -- $'\n\033[2m클립보드에 복사됨\033[0m'
    fi
    return
  fi

  print -r -- "$json" | jq -r '
    def ljust($n): tostring | . + ((" " * ($n - length)) // "");
    def ago:
      (now - (.createdAt | fromdateiso8601)) as $s
      | if   $s < 3600   then "\(($s/60)|floor)m"
        elif $s < 86400  then "\(($s/3600)|floor)h"
        elif $s < 604800 then "\(($s/86400)|floor)d"
        else "\(($s/604800)|floor)w" end;

    ( group_by(.repository.nameWithOwner)
      | sort_by(-length)[]
      | "[1;36m▌ \(.[0].repository.nameWithOwner)[0m [2m(\(length))[0m",
        ( sort_by(-.number)[]
          | "  [33m\("#\(.number)"|ljust(5))[0m"
          + "[2m\(ago|ljust(5))[0m"
          + (if .isDraft then "[35mDRAFT [0m" else "" end)
          + .title
          + (if .commentsCount > 0 then " [2m(\(.commentsCount))[0m" else "" end),
          "       [2m\(.url)[0m"
        ),
        ""
    ),
    "[2mopen \(length) · mypr -p 열기 · -m 마크다운 · -c 복사 · -h 도움말[0m"
  '
}
