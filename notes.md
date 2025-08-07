Perfect — thanks for clarifying. If you’re **not using Homebrew on WSL**, we’ll update your Oh My Zsh-based `.zshrc` accordingly to:

* ✅ Use **standard Linux paths**
* ✅ Avoid any `brew` references
* ✅ Assume tools like `zsh-autosuggestions`, `fzf`, `bat`, `eza`, etc. are installed via `apt`, `curl`, `git`, or manually

---

### ✅ Final `.zshrc` for **WSL + Oh My Zsh (No Homebrew)**

```zsh
# ---- Oh My Zsh base ----
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  thefuck
)

source $ZSH/oh-my-zsh.sh

# ---- Powerlevel10k Instant Prompt ----
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

alias reload-zsh="source ~/.zshrc"
alias edit-zsh="nvim ~/.zshrc"

# ---- History Settings ----
HISTFILE=$HOME/.zhistory
SAVEHIST=1000
HISTSIZE=999
setopt share_history
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_verify

# ---- Arrow Key History Search ----
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

# ---- Node (nvm) ----
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

# ---- Ruby (rbenv) ----
export PATH="$HOME/.rbenv/shims:$PATH"
eval "$(rbenv init - zsh)"

# ---- Python (pyenv) ----
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# ---- TheFuck aliases ----
eval "$(thefuck --alias)"
eval "$(thefuck --alias fk)"

# ---- FZF + fd + previews ----
export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

_fzf_compgen_path() { fd --hidden --exclude .git . "$1"; }
_fzf_compgen_dir()  { fd --type=d --hidden --exclude .git . "$1"; }

show_file_or_dir_preview="if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi"

export FZF_CTRL_T_OPTS="--preview '$show_file_or_dir_preview'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

_fzf_comprun() {
  local command=$1; shift
  case "$command" in
    cd) fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
    export|unset) fzf --preview "eval 'echo \${}'" "$@" ;;
    ssh) fzf --preview 'dig {}' "$@" ;;
    *) fzf --preview "$show_file_or_dir_preview" "$@" ;;
  esac
}

# ---- zoxide (better cd) ----
eval "$(zoxide init zsh)"
alias cd='z'

# ---- Eza and Bat ----
export BAT_THEME=tokyonight_night
alias ls="eza --icons=always"

# ---- Git + Editor ----
export EDITOR="nvim"

# ---- Yazi integration ----
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}
```

---

### ✅ To Use This

1. Save it:

   ```sh
   nvim ~/.zshrc
   ```

2. Reload:

   ```sh
   source ~/.zshrc
   ```

---

### 🧰 Requirements

Make sure these are installed in WSL:

| Tool                        | Install Command                                                                                                                                         |        |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| **Oh My Zsh**               | `sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"`                                                       |        |
| **Powerlevel10k**           | `git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k`                                             |        |
| **zsh-autosuggestions**     | `git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions`                                            |        |
| **zsh-syntax-highlighting** | `git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting`                                |        |
| **nvm, pyenv, rbenv**       | Install manually or via `curl/git`                                                                                                                      |        |
| **fd**                      | `sudo apt install fd-find` (symlink it to `fd` with `ln -s $(which fdfind) ~/.local/bin/fd`)                                                            |        |
| **bat**                     | `sudo apt install bat` (or symlink `batcat` to `bat`)                                                                                                   |        |
| **eza**                     | `cargo install eza` or from .deb                                                                                                                        |        |
| **fzf**                     | `sudo apt install fzf`                                                                                                                                  |        |
| **zoxide**                  | \`curl -sS [https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh](https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh) | bash\` |
| **thefuck**                 | `pip install thefuck`                                                                                                                                   |        |
| **yazi**                    | \`curl -sS [https://raw.githubusercontent.com/sxyazi/yazi/main/install.sh](https://raw.githubusercontent.com/sxyazi/yazi/main/install.sh)               | bash\` |

---
`No module named distutils` during a `pyenv`-installed Python run (often triggered by `pipx` or `pip`) means your **Python installation is missing `distutils`**, which is a common issue on **Ubuntu/WSL with pyenv**.

---

### 🧠 Why This Happens

Ubuntu (and many distros) now **split Python packaging tools** into separate packages. Pyenv compiles Python from source and **doesn’t bundle `distutils`** by default unless the right system packages are installed **before** the build.

---

### ✅ Fix It

You need to install the **`python3-distutils` and related dev packages**, then **reinstall the Python version using pyenv**.

---

### 🔧 Step-by-Step Fix

#### 1. **Install missing build dependencies**

```sh
sudo apt update
sudo apt install -y \
  build-essential \
  libssl-dev \
  zlib1g-dev \
  libbz2-dev \
  libreadline-dev \
  libsqlite3-dev \
  libncursesw5-dev \
  libffi-dev \
  liblzma-dev \
  tk-dev \
  uuid-dev \
  libnss3-dev \
  libgdbm-dev \
  libdb-dev \
  python3-distutils \
  curl
```

#### 2. **Reinstall Python with pyenv (to include distutils)**

For example, if you were using Python 3.12.3:

```sh
pyenv uninstall 3.12.3
pyenv install 3.12.3
pyenv global 3.12.3
```

You must **reinstall** because the missing dependencies prevent `distutils` from being included in the original build.

#### 3. **Verify**

After reinstall:

```sh
python3 -m ensurepip --upgrade
python3 -m pip install --upgrade pip setuptools
```

✅ Then test again:

```sh
python3 -m pipx ensurepath
pipx install thefuck
```

Should now install cleanly with no `distutils` error.

---

### 💡 Optional: Avoid This in the Future

Before using `pyenv install`, always make sure you’ve installed **all Python build dependencies**.

You can also install the **pyenv plugin** [`pyenv-doctor`](https://github.com/yyuu/pyenv-doctor) to help you identify missing deps:

```sh
git clone https://github.com/yyuu/pyenv-doctor.git ~/.pyenv/plugins/pyenv-doctor
pyenv doctor
```



