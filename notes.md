# Customization

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

### To Use This

1. Save it:

   ```sh
   nvim ~/.zshrc
   ```

2. Reload:

   ```sh
   source ~/.zshrc
   ```

---

### Requirements

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

### Why This Happens

Ubuntu (and many distros) now **split Python packaging tools** into separate packages. Pyenv compiles Python from source and **doesn’t bundle `distutils`** by default unless the right system packages are installed **before** the build.

---

### Fix It

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

Then test again:

```sh
python3 -m pipx ensurepath
pipx install thefuck
```

---
# Verify AWS
---

### 1) Check your current principal

```bash
aws sts get-caller-identity \
  --query Arn --output text
```

Keep that ARN handy (we’ll call it `$CALLER_ARN` below) and note the Account ID portion.

---

### 2) Simulate whether you can call `iam:CreateRole`

Replace `<ACCOUNT_ID>` with your AWS account ID and `<ROLE_NAME>` with `test-role`:

```bash
CALLER_ARN=$(aws sts get-caller-identity --query Arn --output text)
ACCOUNT_ID=$(echo $CALLER_ARN | cut -d: -f5)
ROLE_NAME="test-role"

aws iam simulate-principal-policy \
  --policy-source-arn "$CALLER_ARN" \
  --action-names iam:CreateRole \
  --resource-arns arn:aws:iam::$ACCOUNT_ID:role/$ROLE_NAME \
  --query 'EvaluationResults[0].EvalDecision' \
  --output text
```

* If this prints `allowed`, you have permission to create that role.
* If it prints `explicitDeny` (or `implicitDeny`), you do not.

---

### 3) (Optional) Actually create the role

If you get `allowed` and want to test it:

```bash
cat > trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"Service": "ecs-tasks.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }]
}
EOF

aws iam create-role \
  --role-name $ROLE_NAME \
  --assume-role-policy-document file://trust-policy.json
```

If that succeeds, you now have a role called `test-role`.

---

### 4) Delete the role

If you created it (and it has no policies attached), simply:

```bash
aws iam delete-role --role-name $ROLE_NAME
```

If you attached any managed policies first, you must detach them:

```bash
aws iam detach-role-policy \
  --role-name $ROLE_NAME \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
```

Or for inline policies:

```bash
aws iam delete-role-policy \
  --role-name $ROLE_NAME \
  --policy-name MyInlinePolicy
```

Then run the `delete-role` command again.

---

###  Use AWS CLI to Get Subnet CIDR and Count Used IPs

You can get the subnet CIDR:

```bash
aws ec2 describe-subnets --subnet-ids subnet-xxxxxxx --query 'Subnets[0].CidrBlock' --output text
```

Calculate how many IPs are available total (CIDR block size minus AWS reserved IPs).

---

### List All ENIs in the Subnet (Shows Used IPs)

```bash
aws ec2 describe-network-interfaces --filters Name=subnet-id,Values=subnet-xxxxxxx --query 'NetworkInterfaces[*].PrivateIpAddress' --output text | wc -l
```

Count how many IPs are assigned.

---

### Check Secondary IPs on ENIs (Extra IP consumption)

```bash
aws ec2 describe-network-interfaces --filters Name=subnet-id,Values=subnet-xxxxxxx --query 'NetworkInterfaces[*].SecondaryPrivateIpAddressCount' --output text | awk '{s+=$1} END {print s}'
```

---
```bash
jq -r '
"resource \"aws_security_group\" \"" + .name + "\" {\n  name = \"" + .values.name + "\"\n  description = \"" + .values.description + "\"\n  vpc_id = \"" + .values.vpc_id + "\"\n\n" +
(.values.ingress[]? | "  ingress {\n    from_port = \(.from_port)\n    to_port = \(.to_port)\n    protocol = \"\(.protocol)\"\n    cidr_blocks = [\(.cidr_blocks | map("\""+.+"\"") | join(", "))]\n  }\n") +
(.values.egress[]? | "  egress {\n    from_port = \(.from_port)\n    to_port = \(.to_port)\n    protocol = \"\(.protocol)\"\n    cidr_blocks = [\(.cidr_blocks | map("\""+.+"\"") | join(", "))]\n  }\n") +
"  tags = {\n" + (.values.tags | to_entries[] | "    \(.key) = \"\(.value)\"") + "\n  }\n}"
' sg.json
```
---
```
# Memberlist is needed for ECS/EKS multi-task deployments
memberlist:
  join_members:
    - loki-memberlist  # adjust if you use a different service discovery setup

# Schema v13 (latest as of now)
schema_config:
  configs:
    - from: 2022-06-01
      store: tsdb               # uses TSDB index store
      object_store: s3
      schema: v13
      index:
        prefix: index_
        period: 24h

storage_config:
  aws:
    s3: s3://<your-bucket-name>
    region: us-east-1           # adjust region
    s3forcepathstyle: false     # set true only if using MinIO/localstack
  tsdb:
    dir: /var/loki/tsdb          # TSDB local cache directory
    retention_period: 336h       # 14 days
    wal_compression: true

compactor:
  working_directory: /var/loki/compactor
  shared_store: s3
  retention_enabled: true
  retention_delete_delay: 2h     # delay before actual deletion
  delete_request_cancel_period: 24h

limits_config:
  reject_old_samples: true
  reject_old_samples_max_age: 168h   # 7 days
  ingestion_rate_mb: 4
  ingestion_burst_size_mb: 8
  max_cache_freshness_per_query: 10m
```

