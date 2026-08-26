# dotfiles GitHub 저장소 구축 - 명세

## 설치 흐름

새 맥에서 실행하는 명령은 하나다.

```bash
curl -fsSL https://raw.githubusercontent.com/movie42/dotfiles/main/install.sh | bash
```

이 스크립트가 순서대로 하는 일:

- Homebrew 없음: 공식 설치 스크립트 실행 → Xcode Command Line Tools가 함께 설치되어 git이 생김
- Homebrew 있음: 건너뜀
- `~/dotfiles` 없음: `https://github.com/movie42/dotfiles.git`에서 clone → 있음: 건너뜀
  - clone은 HTTPS로 한다. public 저장소라 인증이 필요 없고, 새 맥에는 SSH 키도 `~/.ssh/config`의 별칭도 아직 없다.
- `brew bundle --file=~/dotfiles/Brewfile` → Brewfile에 있는 패키지 중 없는 것만 설치
- `~/.oh-my-zsh` 없음: unattended 모드로 설치 → 있음: 건너뜀
- 심링크 생성 → 기존 실제 파일이 있으면 `.bak`으로 이름 바꾼 뒤 링크
- `nvm install --lts` → node 설치
- `~/.zshrc.local` 없음: `zshrc.local.example`을 복사하고 "값을 채우라"는 안내 출력

마지막에 아직 사람이 해야 할 일 목록을 출력하고 끝난다. `exec zsh`로 셸을 갈아치우지는 않는다 — `curl | bash`로 실행 중이라 그 시점에 셸을 바꾸면 스크립트가 어디서 끝났는지 알 수 없어진다. 터미널을 새로 열라고 안내만 한다.

## 심링크 대응표

| 저장소 안 | 심링크 위치 |
| --- | --- |
| `zsh/zshrc` | `~/.zshrc` |
| `zsh/zprofile` | `~/.zprofile` |
| `git/gitconfig` | `~/.gitconfig` |
| `git/gitignore_global` | `~/.gitignore_global` |
| (없음 — 수동 작성) | `~/.gitconfig.local` |
| `claude/AGENTS.md` | `~/AGENTS.md` |
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` |
| `claude/settings.json` | `~/.claude/settings.json` |
| `claude/rules/` | `~/.claude/rules` |
| `claude/skills/` | `~/.claude/skills` |
| `config/<도구>/` | `~/.config/<도구>` |
| `bin/git-status-preview` | `~/.local/bin/git-status-preview` |
| `bin/git-diff-tree` | `~/.local/bin/git-diff-tree` |

`config/` 아래는 디렉토리 하나하나를 개별 링크로 건다. `~/.config` 자체를 통째로 링크하면 저장소에 없는 도구들(`gcloud`, `vercel-plugin` 등 자격증명이 든 것 포함)이 갈 곳을 잃는다.

`git-diff-tree`는 원래 `~/Library/pnpm/`에 있었지만 `~/.local/bin`으로 옮긴다. pnpm이 관리하는 패키지가 아니라 그냥 거기 놓여 있던 단독 스크립트라, pnpm을 재설치하면 사라진다.

## 파일 분류 기준

| 분류 | 설명 | 처리 |
| --- | --- | --- |
| 공유 설정 | 어느 맥에서나 같은 값. alias, 함수, 도구 설정 | 저장소에 커밋, 심링크 |
| 머신별 값 | 맥마다 다름. AWS 프로필, 회사/개인 구분 | `~/.zshrc.local` — 커밋 안 함 |
| 시크릿 | API 키, 토큰, 패스프레이즈 | `~/.zshrc.local` — 커밋 안 함 |
| git 신원·사내 설정 | 커밋 이름/이메일, SSH 키 경로, 사내 인증서 경로 | `~/.gitconfig.local` — 커밋 안 함 |
| 자격증명 파일 | `~/.aws`, `~/.ssh`, `~/.claude.json`, gcloud/vercel 캐시 | 저장소로 복사조차 하지 않음 |
| 안 쓰는 도구 | Amazon Q, CodeWhisperer, Windsurf, Antigravity | 옮기지 않고 원본에서도 삭제 |
| 재생성 가능 | `node_modules`, brew 캐시, 플러그인 설치본 | 무시 |

판단이 애매하면 `~/.zshrc.local`로 보낸다. 잘못 커밋한 시크릿은 히스토리에서 지워도 이미 노출된 것이라 키를 새로 발급받아야 하지만, `.local`에 잘못 넣은 공유 설정은 나중에 옮기면 그만이다.

## 엣지 케이스

- **기존 파일이 이미 있는 상태에서 설치**: `ln -sfn`은 실제 파일을 말없이 덮어쓴다. 링크 걸기 전에 실제 파일(심링크가 아닌)이면 `.bak`을 붙여 옮긴다.
- **두 번 실행**: 각 단계가 존재 여부를 먼저 검사한다. `brew bundle`과 `ln -sfn`은 원래 여러 번 실행해도 안전하다.
- **Apple Silicon / Intel 경로 차이**: Homebrew 위치가 `/opt/homebrew`와 `/usr/local`로 다르다. `zsh/path.zsh`가 두 경로에 `brew` 실행 파일이 있는지 직접 보고 `HOMEBREW_PREFIX`를 정한다. 파일 존재 검사라 `brew --prefix`처럼 프로세스를 띄우지 않는다. install.sh가 값을 남기는 방식은 쓰지 않는다 — 그러면 install.sh를 거치지 않고 clone만 한 맥에서 셸이 깨진다.
- **`~/.zshrc.local`이 비어 있는 채로 셸 시작**: 키가 없어도 셸은 정상적으로 떠야 한다. 값이 없을 때 오류를 내는 코드를 넣지 않는다.
- **`brew bundle` 도중 실패**: 패키지 하나가 실패해도 나머지는 계속 깔린다. 스크립트를 `set -e`로 중단시키지 말고, 실패 목록을 마지막에 모아 출력한다.
- **public 저장소에 시크릿을 실수로 커밋**: `git rm` 후 다시 커밋해도 히스토리에 남고, 이미 크롤러에 노출된 뒤다. 되돌리는 방법은 히스토리 정리가 아니라 해당 키를 폐기하고 새로 발급받는 것이다. 첫 push 전에 `git diff --cached | grep -iE 'key|token|secret|password'`로 한 번 훑는다.
- **회사 계정으로 커밋**: 전역 git 설정이 회사 계정이라, 저장소별 신원을 지정하지 않으면 개인 public 저장소에 회사 이메일이 박힌다. 커밋은 되돌릴 수 있어도 이미 push된 히스토리는 재작성해야 한다. 첫 커밋 후 push 전에 `git log --format='%an <%ae>'`로 확인한다.
- **clone 주소와 push 주소가 다르다**: install.sh는 HTTPS로 clone한다(새 맥엔 SSH 키가 없으므로). 반면 이 맥에서 변경분을 push할 때는 `git@github-personal:movie42/dotfiles.git`을 쓴다 — 개인 SSH 키로 인증해야 회사 계정으로 커밋이 올라가지 않기 때문이다. 새 맥에서도 직접 수정하고 push하려면 그때 원격 주소를 SSH로 바꾸고 `core.sshCommand`를 조정한다. README에 적어둔다.
- **`gh repo create`가 엉뚱한 계정에 저장소 생성**: gh 활성 계정을 회사 쪽으로 두는 게 기본이라, 저장소 만들 때만 `gh auth switch --user movie42`가 필요하다. 웹에서 빈 저장소를 만들면 이 과정 자체가 없어진다.
- **새 맥에 `~/.gitconfig.local`이 없는 상태**: `[include]`가 없는 파일을 가리켜도 git은 조용히 넘어간다. 다만 `user.email`이 비어 커밋 시점에 git이 에러를 낸다. README에 이 파일을 먼저 채우라고 명시한다.
- **회사 맥 / 개인 맥**: 지금은 구분하지 않는다. 실제로 두 대를 다르게 써야 할 상황이 오면 그때 `~/.zshrc.local`로 분기하거나 chezmoi로 옮긴다.

## 결정이 필요한 부분

### `gdt` 명령(`git-diff-tree`)을 살릴지, 버릴지

- **지금 상태**: `gdt` alias가 부르는 `git-diff-tree`는 지금 이 맥에서도 이미 깨져 있다. 실행하면 "Cannot find module" 에러가 난다. 계획에는 "pnpm 전역 패키지 목록에 없는 단독 셸 스크립트"라고 적혀 있었지만 실제로는 `~/projects/diff-tree`라는 로컬 프로젝트를 `pnpm link --global`로 연결한 껍데기였고, 그 프로젝트 폴더가 지금 없다.
- **왜 막히는지**: 저장소로 옮겨도 동작하지 않는다. 저 껍데기 파일은 자기 위치 기준으로 `~/Library/pnpm/global/5/node_modules/git-diff-tree`를 찾기 때문에 `~/.local/bin`으로 옮기면 그것마저 못 찾는다.
- **선택지**
  - A안: `gdt` alias를 지운다 → 새 맥에서 없는 명령을 부르는 alias가 사라진다. 지금도 안 되던 기능이라 잃는 게 없다.
  - B안: `~/projects/diff-tree` 프로젝트를 어디선가 복구해서 별도 저장소로 살린다 → `gdt`가 다시 동작하지만, dotfiles와 무관한 별개 작업이 생긴다.
- **추천**: A안. 이미 쓰지 못하고 있던 명령이고, 프로젝트 소스를 찾는 일은 이 계획의 범위 밖이다.

### `docs/` 폴더를 public 저장소에 함께 올릴지

- **지금 상태**: 이 계획 문서 두 개(`tasks.md`, `spec.md`)가 저장소에 커밋돼 있다. 안에는 회사 GitHub 계정 이름(`AeiYo`), 회사 SSH 키 파일명, 사내 인증서를 쓴다는 사실, 회사 저장소용 alias 이름이 적혀 있다. 실제 이메일·키·토큰 값은 없다.
- **왜 막히는지**: 저장소가 public이라 push하는 순간 누구나 읽을 수 있고, 크롤러에도 잡힌다. 나중에 지워도 히스토리에 남는다.
- **선택지**
  - A안: 그대로 올린다 → 새 맥에서 저장소만 clone하면 왜 이렇게 만들었는지까지 따라온다. 대신 회사 계정 이름과 키 파일명이 공개된다.
  - B안: `.gitignore`에 `docs/`를 넣고 로컬에만 둔다 → 공개되는 게 설정 파일뿐이다. 대신 새 맥에서는 계획 문서를 볼 수 없고, 백업도 안 된다.
  - C안: 저장소를 private으로 바꾸고 `docs/`를 유지한다 → 둘 다 지키지만 `curl | bash` 한 줄 설치가 깨진다. 토큰 인증이 필요해진다.
- **추천**: A안. 노출되는 건 GitHub 계정 이름과 키 파일명뿐이고 둘 다 그 자체로는 접근 권한이 없다. `curl | bash` 한 줄이 이 계획의 핵심 목표라 C안은 목적을 무너뜨린다.
