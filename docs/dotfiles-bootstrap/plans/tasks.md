# dotfiles GitHub 저장소 구축

> 이슈: 없음
> 작업 종류: 기능 개발
> 상태: 대기
> 생성일: 2026-08-26

## 개요

새 맥을 세팅할 때마다 Homebrew 패키지, `.zshrc`, `~/.config` 아래 도구 설정을 손으로 다시 만들고 있다. 이 설정들을 GitHub 저장소 하나에 모으고, 새 맥에서 명령 한 줄로 복원되게 만든다.

복원 대상은 셸 환경(zsh + oh-my-zsh + 커스텀 함수), Homebrew 패키지 목록(formula 37개 / cask 11개), `~/.config` 아래 도구 설정, git 설정, AI 에이전트 규칙 문서다. 제외 대상은 자격증명이 담긴 파일 전부(`~/.aws`, `~/.ssh`, `~/.claude.json`, gcloud/vercel 토큰)와 머신마다 값이 다른 개인 설정이다.

방식은 `~/dotfiles` 저장소를 만들고 실제 위치로 심링크를 거는 구조다. `~/.zshrc`를 고치면 그게 곧 저장소 파일 수정이 되어 `git commit` 한 번으로 백업이 끝난다. GNU Stow나 chezmoi 같은 전용 도구는 쓰지 않는다 — 지금은 맥 한 종류만 쓰고 있어서 chezmoi의 머신별 템플릿 기능이 놀고, Stow는 심링크 거는 일만 대신해주는데 그건 셸 스크립트 20줄이면 된다.

저장소는 개인 계정 `movie42` 아래에 public으로 만든다 (`github.com/movie42/dotfiles`). public이어야 `curl | bash` 한 줄이 인증 없이 동작한다. 대신 Phase 1에서 시크릿과 신원을 분리하는 게 다른 모든 작업의 전제 조건이 된다.

Neovim 설정은 이 계획에 포함하지 않는다. `~/.config/nvim`은 2023년 9월에 `ecosse3/nvim`을 clone한 그대로이고 개인 커밋이 없다. `lazy-lock.json`에 당시 플러그인 버전이 고정돼 있어서 지금 neovim 0.10에 복원해도 정상 동작을 기대하기 어렵다. `neovim` 바이너리는 Brewfile에 남기고, 설정은 나중에 실제로 쓸 때 최신 LazyVim으로 새로 시작한다.

## Phase 1: 시크릿과 신원 분리

가장 먼저 한다. 이게 끝나기 전에는 어떤 파일도 커밋하지 않는다.

### 시크릿

- [x] `GOOGLE_GENERATIVE_AI_API_KEY` 완전 삭제 — 안 쓰는 키라 옮기지 않고 없앴다
  - `~/.zshrc`와 오래된 백업 `~/.zshrc.bak.mypr` 양쪽에서 제거
- [x] `~/.zshrc.local` 규약 도입 — 머신별 값과 시크릿 전용 파일, 권한 `600`
  - 이동 대상: `AWS_PROFILE`, `PULUMI_CONFIG_PASSPHRASE`
  - `~/.zshrc` 맨 끝에 `[ -f ~/.zshrc.local ] && source ~/.zshrc.local` 추가
- [x] `zshrc.local.example` 작성 — 키 이름과 발급처만 적고 값은 비워둔 템플릿 (`~/dotfiles/zshrc.local.example`)
- [x] `.gitignore` 작성 (`~/dotfiles/.gitignore`)
  - 제외: `.zshrc.local`, `gitconfig.local`, `config/gh/`, `config/gcloud/`, `config/vercel-plugin/`, `config/configstore/`, `config/devin/`, `config/github-copilot/`, `config/notion-cli/`
  - `~/.aws`, `~/.ssh`, `~/.claude.json`은 애초에 저장소로 복사하지 않는다

### 신원 — 계정 전환 없이 쓰기

이 맥은 회사 계정(`AeiYo`)이 기본이고, 개인 계정(`movie42`)은 이 저장소 하나에만 쓴다. 그래서 원칙은 **전환하지 않는다**로 잡는다. 작업할 때마다 `gh auth switch`를 기억해야 하는 방식은 언젠가 반드시 잊어버리고, 잊은 결과가 "회사 이메일로 공개 커밋"이라 되돌리기 비싸다.

전환이 필요 없는 이유는 **git push가 gh CLI를 거치지 않기 때문**이다. push할 때 GitHub이 계정을 판별하는 건 gh의 활성 계정이 아니라 SSH 키다. 그래서 이 저장소에만 개인 키를 쓰게 만들면, gh가 어느 계정에 있든 상관없어진다.

이미 `~/.ssh/config`에 `github-personal` 별칭이 있고 `movie42`로 인증된다. 따로 키를 만들 필요가 없다.

| | 인증되는 계정 |
| --- | --- |
| `git@github.com:...` (기본) | AeiYo |
| `git@github-personal:...` | movie42 |

- [x] gh CLI에 `movie42` 계정 추가 — `AeiYo`와 함께 두 계정이 등록됨
- [x] gh 활성 계정을 `AeiYo`로 되돌린다 — `gh auth switch --user AeiYo`
  - 지금 `movie42`가 활성이라 `mypr`(`prs`)의 `@me`가 개인 계정으로 해석돼 회사 PR이 안 보인다. 일상 작업이 회사 쪽이므로 기본값은 `AeiYo`가 맞다.
  - 저장소 생성 때만 잠깐 `movie42`가 필요하다. 아래 항목 참조.
- [x] `movie42/dotfiles` 저장소 생성 — 이 한 번만 개인 계정이 필요하다
  - `gh auth switch --user movie42` → `gh repo create movie42/dotfiles --public` → `gh auth switch --user AeiYo`
  - 전환이 번거로우면 GitHub 웹에서 빈 저장소를 만들어도 결과는 같다. 이후로는 gh를 쓸 일이 없다.
- [x] `~/dotfiles`의 원격 주소를 개인 별칭으로 지정 (`~/dotfiles/.git/config`)
  - `git remote add origin git@github-personal:movie42/dotfiles.git`
- [x] `~/dotfiles`에만 전역 SSH 키 고정을 해제 (`~/dotfiles/.git/config`)
  - 전역 `core.sshCommand`가 `-i ~/.ssh/AeiYo`로 키를 못박고 있어서, 그대로 두면 `github-personal` 별칭을 써도 AeiYo로 인증된다. 확인해봤고 실제로 그렇게 동작한다.
  - `git config core.sshCommand "ssh"` — 저장소 안에서만 `-i`를 걷어내면 `~/.ssh/config`의 별칭 설정이 적용된다
- [x] `~/dotfiles`에만 개인 신원 적용 (`~/dotfiles/.git/config`)
  - 전역 설정(회사 계정)은 건드리지 않는다. `git config user.name movie42`, `git config user.email 44064122+movie42@users.noreply.github.com`
  - 이 이메일은 GitHub이 계정마다 주는 익명 주소다. public 저장소 커밋 로그에 실제 개인 이메일이 노출되지 않는다.
- [x] 설정이 실제로 먹었는지 push 전에 확인
  - `git log --format='%an <%ae>'` — 개인 계정으로 나와야 한다
  - `GIT_SSH_COMMAND="ssh" ssh -T github-personal` — `Hi movie42!`가 나와야 한다
  - 여기서 틀린 채로 push하면 히스토리 재작성 말고는 방법이 없다
- [x] gh 계정 전환 alias 추가 (`~/dotfiles/zsh/aliases.zsh`)
  - `alias ghwork="gh auth switch --user AeiYo"` / `alias ghme="gh auth switch --user movie42"`
  - 위 설정이 끝나면 평소엔 쓸 일이 없다. 개인 저장소에 `gh` 명령(PR 생성 등)을 쓸 때만 필요하다.

## Phase 2: 저장소 뼈대와 zshrc 분해

현재 `.zshrc`는 751줄에 alias, 함수 15개, PATH 설정 25줄, 도구 초기화가 섞여 있다. 파일별로 쪼개면 나중에 뭘 고칠 때 찾기 쉽고, 아래 중복/버그도 같이 정리된다.

- [x] 저장소 디렉토리 구조 생성 (`~/dotfiles/`)
  - `zsh/`, `git/`, `config/`, `bin/`, `claude/`
- [x] `zsh/zshrc` — oh-my-zsh 로딩과 나머지 파일 source만 담당 (`~/dotfiles/zsh/zshrc`)
  - 맨 끝에 `[ -f ~/.zshrc.local ] && source ~/.zshrc.local` 추가
- [x] `zsh/path.zsh` — 흩어진 PATH 설정 25줄을 한곳으로 (`~/dotfiles/zsh/path.zsh`)
  - `.zshrc:547`이 `export PATH=/opt/homebrew/bin:...`로 PATH를 통째로 덮어써서, 앞에서 추가한 pnpm(150줄)과 bun(160줄) 경로가 지워진다. 지금은 뒤에서 다시 추가해줘서 우연히 동작하는 상태다. 덮어쓰기를 없애고 append만 남긴다.
  - 중복 제거: bun 블록 2회(160, 571), Windsurf 2회(583, 586), maestro 3회(634~636)
  - `$(brew --prefix ruby)`(580)와 `$(brew --prefix mysql-client)`(749)는 셸을 열 때마다 brew를 실행한다. 현재 셸 시작이 0.67초인데 이 두 줄이 그중 상당 부분이다. 경로를 상수로 박는다.
  - `JAVA_HOME`이 어디에도 설정돼 있지 않다. openjdk@17과 @21이 둘 다 깔려 있고 PATH 순서상 21이 이긴다. Gradle과 Android 빌드 도구는 PATH의 java가 아니라 `JAVA_HOME`을 보는 경우가 많아, 어느 버전을 쓸지 정해서 명시적으로 export 한다.
- [x] `zsh/aliases.zsh` — alias 30여 개 이동 (`~/dotfiles/zsh/aliases.zsh`)
- [x] `zsh/tools.zsh` — zoxide, nvm, fzf, bun completion, zsh-autosuggestions, zsh-syntax-highlighting 초기화 (`~/dotfiles/zsh/tools.zsh`)
- [x] `zsh/functions/git.zsh` — `git_checkout` `git_push` `git_status` `git_flow` `git_branch_delete` `gbsf` `gtd` `gset-leaf` `grebase-chain` `gshow-leaf` `mypr` (`~/dotfiles/zsh/functions/git.zsh`)
- [x] `zsh/functions/nav.zsh` — `fcd` `fzcd` (`~/dotfiles/zsh/functions/nav.zsh`)
- [x] `zsh/functions/dev.zsh` — `killport` `emu` `pfx-list` (`~/dotfiles/zsh/functions/dev.zsh`)
- [x] `zsh/zprofile` 이동 (`~/dotfiles/zsh/zprofile`)
  - Amazon Q pre/post 블록 2개 삭제. OrbStack 초기화 줄은 유지한다.
- [x] 안 쓰는 도구 블록 삭제 — 아래 4개는 저장소에 옮기지 않는다
  - Amazon Q: `.zshrc` 최상단 pre 블록(2)과 최하단 post 블록(574), `.zprofile` pre/post 블록. `/Applications/Amazon Q.app`이 이미 없어서 지금도 아무 일도 하지 않는 줄이다.
  - CodeWhisperer: `~/.local/bin`의 심링크 3개(`cw`, `cwterm`, `q`)가 사라진 앱을 가리킨다.
  - Windsurf: `.zshrc:583`, `.zshrc:586` PATH 2줄(중복)
  - Antigravity: `.zshrc:594` PATH 1줄
  - 유지: flashlight, maestro, ai-skills — 셋 다 실제로 설치돼 있고 모바일 작업에 쓰인다
- [x] 분해 후 새 셸에서 alias·함수 전부 동작하는지 확인, 시작 시간 재측정

## Phase 3: 나머지 설정 수집

- [x] `~/.gitconfig` 분해 — `.zshrc`와 같은 패턴으로 공유분과 개인분을 가른다 (`~/dotfiles/git/gitconfig`)
  - 커밋: alias(`s` `ss` `l`), delta 설정, `merge.conflictstyle`, `diff.colorMoved`, `init.defaultBranch`, `column.ui`
  - 커밋 안 함 → `~/.gitconfig.local`: `user.name` / `user.email`(회사 계정), `core.sshCommand`의 SSH 키 경로, `http.sslCAInfo`(사내 인증서)
  - `gitconfig` 맨 끝에 `[include] path = ~/.gitconfig.local` 추가. git은 뒤에 include된 값이 이기므로 개인 설정이 공유 설정을 덮어쓴다.
  - `core.excludesfile`이 `/Users/hyunsuko/...` 절대 경로다. 새 맥에서 사용자명이 다르면 깨지므로 `~/.gitignore_global`로 바꾼다.
  - Sourcetree mergetool 설정 삭제 — 경로가 macOS AppTranslocation 임시 디렉토리라 이미 만료됐다
  - `http.sslCAInfo`는 사내 git 서버용 인증서다. 새 맥에 그 파일이 없는 상태로 이 설정이 있으면 git이 HTTPS 통신에서 실패한다. `.local`로 빼는 이유가 이것이다.
- [x] `~/.gitignore_global` 이동 (`~/dotfiles/git/gitignore_global`)
- [x] `gitconfig.local.example` 작성 — 신원과 사내 설정 자리만 비워둔 템플릿 (`~/dotfiles/git/gitconfig.local.example`)
- [x] `~/.config` 아래 도구 설정 복사 (`~/dotfiles/config/`)
  - 대상: `ghostty`, `yazi`, `ccstatusline`, `glow`, `git`, `karabiner`, `zed`, `gh-attach`
  - `nvim`은 제외 (개요 참조)
- [x] oh-my-zsh 커스텀 플러그인 처리 (`~/dotfiles/install.sh`)
  - `~/.oh-my-zsh/custom/plugins`에 `zsh-autosuggestions`, `zsh-syntax-highlighting`이 있는데 brew로도 같은 게 깔려 있다. brew 쪽만 남기고 omz 플러그인 목록에서 뺀다.
- [ ] 커스텀 실행 스크립트 이동 (`~/dotfiles/bin/`)
  - `~/.local/bin/git-status-preview` — `git_status` 함수의 fzf preview가 이걸 호출한다. 없으면 preview 창이 깨진다.
  - `~/Library/pnpm/git-diff-tree` — `gdt` alias가 쓴다. pnpm 전역 패키지 목록에는 없는 단독 셸 스크립트라 직접 챙겨야 한다.
- [x] AI 에이전트 규칙 문서 이동 (`~/dotfiles/claude/`)
  - `~/AGENTS.md`, `~/.claude/CLAUDE.md`, `~/.claude/rules/`, `~/.claude/settings.json`, `~/.claude/skills/`
  - `~/.claude.json`은 세션 기록과 자격증명이 들어 있어 제외

## Phase 4: Brewfile과 install.sh

- [x] Brewfile 생성 (`~/dotfiles/Brewfile`)
  - `brew bundle dump --describe --file=~/dotfiles/Brewfile`
  - formula 37개, cask 11개. `--describe`를 붙이면 각 패키지 설명이 주석으로 들어가 나중에 "이게 뭐였지"를 막는다.
- [x] `install.sh` 작성 (`~/dotfiles/install.sh`)
  - 순서: Homebrew 설치 → 저장소 clone → `brew bundle` → oh-my-zsh 설치 → 심링크 → `nvm install --lts` → `~/.zshrc.local` 생성 안내
  - Homebrew가 맨 앞인 이유: 깨끗한 맥에는 git이 없다. Homebrew 설치 과정이 Xcode Command Line Tools를 깔고 거기에 git이 딸려 온다. 그래야 다음 줄의 `git clone`이 동작한다.
  - 심링크는 `ln -sfn`. 이미 파일이 있으면 `.bak`으로 밀어두고 건다 — 기존 설정을 말없이 지우지 않기 위해서다.
  - 두 번 실행해도 결과가 같아야 한다. 각 단계 앞에 존재 여부 검사를 둔다.
- [x] `README.md` 작성 — 설치 한 줄, 수동으로 해야 할 일 목록 (`~/dotfiles/README.md`)
  - 자동화 못 하는 것: `~/.zshrc.local`과 `~/.gitconfig.local` 값 채우기, `gh auth login`, `aws configure`, SSH 키 생성, Xcode/Android Studio 설치, macOS 시스템 설정
  - README는 저장소 루트라 한국어로 쓴다

## Phase 5: 실제 검증

스크립트를 읽어보는 것만으로는 "깨끗한 맥에서 되는지"를 알 수 없다. 지금 맥에는 이미 모든 게 깔려 있어서 install.sh가 전부 건너뛰고 성공한 것처럼 보이기 때문이다.

- [ ] macOS에 새 사용자 계정을 만들어 그 계정으로 로그인 후 install.sh 실행
  - Linux 컨테이너로는 검증할 수 없다. Homebrew 경로(`/opt/homebrew`), cask, macOS 전용 도구가 전부 다르게 동작한다.
- [ ] 실패 지점 기록하고 스크립트 수정, 다시 실행
- [ ] 검증 끝나면 현재 맥의 실제 dotfile들을 저장소 심링크로 교체

## 진행 기록

<!-- 구현 중 내린 결정과 이유, 계획과 달라진 부분, 블로커를 남긴다. -->

### 2026-08-26

- Phase 1 시크릿 분리 완료. `zshrc.local.example`과 `.gitignore`는 저장소 뼈대를 만들 때 함께 작성한다.
- 결정: `GOOGLE_GENERATIVE_AI_API_KEY`는 `~/.zshrc.local`로 옮기지 않고 삭제했다 — 쓰지 않는 키라 보관할 이유가 없다.
- `.zshrc`가 751줄이 되면서 Phase 2에 적어둔 줄 번호 중 3곳이 밀려 갱신했다.
- 오래된 백업 `~/.zshrc.bak.mypr`, `~/.zshrcBackupupup` 삭제. 현재 `.zshrc`와 대조해 고유 내용이 없음을 확인한 뒤 지웠다.
- `.zshrcBackupupup`에만 있던 `JAVA_HOME` 설정이 현재 `.zshrc`에서는 빠져 있는 걸 발견해 Phase 2에 항목으로 추가했다.
- 결정: 저장소는 개인 계정 `movie42/dotfiles`. 확인해보니 gh CLI는 회사 계정으로만 로그인돼 있고 전역 git 신원도 회사 계정이라, 신원 분리 작업을 Phase 1에, `~/.gitconfig` 분해를 Phase 3에 추가했다.
- gh CLI에 `movie42` 추가 완료. 활성 계정이 `movie42`로 바뀌면서 `AeiYo`의 git 프로토콜 설정이 ssh에서 https로 덮어써졌다 — 회사 저장소를 `gh repo clone`할 때 원격 주소가 달라진다.
- 결정: 계정 전환에 의존하지 않는다. 이 맥의 기본은 회사 계정이고, `~/dotfiles` 저장소만 개인 SSH 키로 push한다. `~/.ssh/config`에 이미 있던 `github-personal` 별칭이 `movie42`로 인증되는 걸 확인해서 새 키를 만들지 않았다.
- 전역 `core.sshCommand`의 `-i ~/.ssh/AeiYo`가 SSH 별칭의 IdentityFile을 덮어쓰는 것을 확인했다(별칭으로 접속해도 AeiYo로 인증됨). 저장소 단위로 `core.sshCommand = ssh`를 줘서 푼다.

### 2026-08-26 (구현)

- Phase 1~4 완료. Phase 5(새 사용자 계정 검증)와 첫 push는 사용자 확인 대기.
- 검증: 새 셸과 현재 셸의 `alias` 출력 비교 — gh 전환 alias 2개만 추가되고 나머지 동일. 함수 16개 `functions` 출력 대조 — `pfx-list`의 후행 공백만 다르고 전부 일치. 셸 시작 시간 중앙값 0.95초 → 0.79초.
- 검증: install.sh의 `link()`를 가짜 HOME으로 4가지 상황(실제 파일 존재 / 재실행 / 다른 곳 가리키는 심링크 / 원본 없음) 테스트 — 백업·멱등성·실패 수집 모두 의도대로.
- 검증: 첫 커밋 전 `git diff --cached`에 gh·sk·AIza·AKIA·JWT·PEM 패턴 없음, 회사 이메일 없음. `git log`가 `movie42 <44064122+movie42@...>`, `ssh -T github-personal`이 `Hi movie42!`.
- 결정: `JAVA_HOME`은 `openjdk@17`. RN/Expo Android 빌드의 표준 버전이라 골랐다. PATH도 17이 이겨 `java -version`이 21에서 17로 바뀐다. 21로 되돌리려면 `~/.zshrc.local`에 두 줄을 넣는다 (`zshrc.local.example` 참조).
- 결정: PATH 관리에 zsh의 `typeset -U path`를 쓴다. 중복 제거가 셸 기능으로 처리돼 bun·Windsurf·maestro 중복 블록을 따로 지울 필요가 없다.
- 결정: `.zshrc:547`의 PATH 덮어쓰기를 없앨 때 `/opt/homebrew/bin`을 명시적으로 추가했다. `/etc/paths`에 homebrew 경로가 없어서, 그 줄이 이 맥에서 유일하게 brew를 PATH에 올리고 있었다.
- 결정: `HOMEBREW_PREFIX`를 install.sh가 계산해 남기는 대신 `path.zsh`가 직접 파일 존재로 판별한다. 생성 파일에 의존하면 clone만 한 맥에서 셸이 깨진다. spec 엣지 케이스에 반영.
- 결정: Brewfile에서 VS Code 확장 36줄을 뺐다. `code` CLI가 없는 맥이고 계획 범위(formula/cask) 밖이다. 대신 `brew "node"`를 넣었다 — Brewfile의 `npm` 항목 10개가 설치 시점에 node를 필요로 한다.
- 결정: `~/.claude/settings.json`의 `statusLine.command`를 `$HOME/.bun/bin/ccstatusline`으로 바꿨다. 절대 홈 경로라 사용자명이 다른 맥에서 깨진다.
- 결정: `claude/skills/browse`는 `node_modules`와 `dist`를 뺀 소스만 담았다(72MB → 672KB). 복원은 `setup.sh`로 한다. README에 적었다.
- 블로커: `gdt`(`git-diff-tree`)와 `docs/` 공개 여부 — spec의 `## 결정이 필요한 부분` 참조.
- 잔재 발견: `~/.local/bin`에 Amazon Q 흔적이 더 있다 — `qchat`, `qterm` 끊긴 심링크와 88MB짜리 `* (qterm)` 바이너리 4개(합계 352MB). 계획에 없어 손대지 않았다.
