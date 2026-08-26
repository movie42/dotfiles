# dotfiles

macOS 개발 환경 설정. 새 맥에서 명령 한 줄로 복원한다.

```bash
curl -fsSL https://raw.githubusercontent.com/movie42/dotfiles/main/install.sh | bash
```

Homebrew → 저장소 clone → `brew bundle` → oh-my-zsh → 심링크 → node(LTS) → npm 전역 패키지 → bun 순으로 진행한다.
깨끗한 맥에는 git이 없기 때문에 Homebrew가 맨 앞이다 — Homebrew 설치 과정이 Xcode Command Line Tools를 깔고 거기에 git이 딸려 온다.

여러 번 실행해도 결과가 같다. 각 단계가 존재 여부를 먼저 검사하고, 실패한 항목은 중단하지 않고 맨 마지막에 모아 출력한다.

## 구조

저장소 파일을 실제 위치로 심링크한다. `~/.zshrc`를 고치면 그게 곧 저장소 파일 수정이라 `git commit` 한 번으로 백업이 끝난다.

| 저장소 안 | 심링크 위치 |
| --- | --- |
| `zsh/zshrc` | `~/.zshrc` |
| `zsh/zprofile` | `~/.zprofile` |
| `git/gitconfig` | `~/.gitconfig` |
| `git/gitignore_global` | `~/.gitignore_global` |
| `claude/AGENTS.md` | `~/AGENTS.md` |
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` |
| `claude/settings.json` | `~/.claude/settings.json` |
| `claude/rules/` | `~/.claude/rules` |
| `claude/skills/` | `~/.claude/skills` |
| `config/<도구>/` | `~/.config/<도구>` |
| `bin/git-status-preview` | `~/.local/bin/git-status-preview` |
| `vscode/settings.json` | `~/Library/Application Support/Code/User/settings.json` |
| `vscode/keybindings.json` | `~/Library/Application Support/Code/User/keybindings.json` |

`config/` 아래는 디렉토리 하나하나를 개별 링크로 건다. `~/.config` 자체를 통째로 링크하면 저장소에 없는 도구들(`gcloud`, `vercel-plugin` 등 자격증명이 든 것 포함)이 갈 곳을 잃는다.

기존에 실제 파일이 있으면 `.bak`을 붙여 옮긴 뒤 링크한다. 말없이 덮어쓰지 않는다.

`zsh/zshrc`는 oh-my-zsh를 띄우고 나머지를 순서대로 읽는다.

| 파일 | 내용 |
| --- | --- |
| `zsh/path.zsh` | PATH, `JAVA_HOME`, Android SDK, Homebrew prefix |
| `zsh/aliases.zsh` | alias |
| `zsh/functions/git.zsh` | `gco` `gp` `gs` `gfl` `gbd` `gbsf` `gtd` `mypr` 등 |
| `zsh/functions/nav.zsh` | `fcd` `fzcd` |
| `zsh/functions/dev.zsh` | `killport` `emu` `pfx-list` |
| `zsh/tools.zsh` | nvm, zoxide, fzf, bun completion, zsh 플러그인 |

## 커밋하지 않는 것

시크릿과 머신별 값은 저장소 밖의 `.local` 파일에 둔다. 잘못 커밋한 키는 히스토리에서 지워도 이미 노출된 것이라, 되돌리는 방법은 키를 폐기하고 새로 발급받는 것뿐이다.

| 파일 | 내용 | 템플릿 |
| --- | --- | --- |
| `~/.zshrc.local` | AWS 프로필, Pulumi 패스프레이즈, API 키 | `zshrc.local.example` |
| `~/.gitconfig.local` | 커밋 이름·이메일, SSH 키 경로, 사내 인증서 | `git/gitconfig.local.example` |

`~/.aws`, `~/.ssh`, `~/.claude.json`, gcloud/vercel 토큰 캐시는 저장소로 복사조차 하지 않는다.

`install.sh`가 두 파일을 템플릿에서 만들어주지만 값은 비어 있다. **`~/.gitconfig.local`의 `user.email`이 비면 git이 커밋을 거부한다** — 가장 먼저 채워야 하는 값이다.

## 설치 후 직접 해야 하는 일

1. `~/.zshrc.local` — AWS 프로필, Pulumi 패스프레이즈
2. `~/.gitconfig.local` — 커밋 이름과 이메일
3. `gh auth login`, `aws configure`
4. SSH 키 생성 후 GitHub에 등록
5. Xcode, Android Studio 설치 및 SDK 내려받기
6. macOS 시스템 설정 (키보드, 트랙패드, Dock)

`~/.claude/skills/browse`는 소스만 들어 있다. 쓰려면 `~/.claude/skills/browse/setup.sh`를 한 번 실행해 의존성을 받아야 한다.

## install.sh가 복원하지 못하는 것

`brew bundle`은 Homebrew가 아는 것만 깐다. 아래는 목록에 담기지 않아 직접 받아야 한다.

| 항목 | 이유 |
| --- | --- |
| Xcode | App Store 전용. `mas` CLI는 로그인 상태에 의존하고 자주 깨져 쓰지 않는다 |
| KakaoTalk | Homebrew cask가 없다 |
| 사내 배포 앱 | 사내 채널로만 받는다 |
| Jetendard 폰트 | `~/.config/ghostty/config`가 이 폰트를 쓴다. 없으면 기본 폰트로 뜬다 |
| macOS 시스템 설정 | 키보드·트랙패드·Dock·Finder. `defaults write` 키가 macOS 버전마다 바뀌어 자동화하지 않는다 |
| Android SDK | Android Studio를 처음 실행하면 받는다 |

node는 nvm이 관리한다. Brewfile에 `node`를 넣지 않고, `nvm install --lts` 후 npm 전역 패키지를 깐다. bun은 Homebrew에 없어 공식 설치 스크립트를 쓴다.

## 이 저장소에 push하기

`install.sh`는 HTTPS로 clone한다. 새 맥에는 SSH 키가 없기 때문이다. 반면 push는 개인 SSH 키로 해야 하므로 원격 주소를 바꾼다.

```bash
cd ~/dotfiles
git remote set-url origin git@github-personal:movie42/dotfiles.git
git config core.sshCommand "ssh"
git config user.name movie42
git config user.email 44064122+movie42@users.noreply.github.com
```

`core.sshCommand "ssh"`가 필요한 이유는 전역 설정이 `-i ~/.ssh/<회사키>`로 키를 못박고 있기 때문이다. 그대로 두면 `~/.ssh/config`의 별칭을 써도 회사 계정으로 인증되고, public 저장소 커밋 로그에 회사 이메일이 박힌다.

push 전 확인:

```bash
git log --format='%an <%ae>' -1
GIT_SSH_COMMAND="ssh" ssh -T github-personal   # Hi movie42! 가 나와야 한다
git diff --cached | grep -iE 'key|token|secret|password'
```

## 포함하지 않은 것

Neovim 설정(`~/.config/nvim`). 2023년에 clone한 `ecosse3/nvim` 그대로이고 `lazy-lock.json`이 당시 플러그인 버전을 고정하고 있어, 지금 복원해도 정상 동작을 기대하기 어렵다. `neovim` 바이너리는 Brewfile에 남아 있으니 실제로 쓸 때 최신 설정으로 새로 시작한다.
