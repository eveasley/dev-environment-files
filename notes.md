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

```
provider "grafana" {
  alias = "grafana_stack"
  url   = "https://grafana.${var.domain_name}" 
  auth  = var.grafana_api_key
}

#########################
# GRAF-CONF VARIABLES
#########################
variable "grafana_api_key" {
  description = "Grafana Instance API key (service account token)"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "Custom domain name (without prefix), e.g. example.com"
  type        = string
}

variable "oidc_name" {
  description = "Display name for OIDC provider in Grafana"
  type        = string
}

variable "oidc_auth_url" {
  description = "OIDC provider authorization URL"
  type        = string
}

variable "oidc_token_url" {
  description = "OIDC provider token URL"
  type        = string
}

variable "oidc_api_url" {
  description = "OIDC provider user info URL"
  type        = string
}

variable "oidc_client_id" {
  description = "OIDC client ID"
  type        = string
}

variable "oidc_client_secret" {
  description = "OIDC client secret"
  type        = string
  sensitive   = true
}

#########################
# NET
#########################
variable "vpc_id" {
  description = "VPC ID for consumer/non-routable network"
  type        = string
}

variable "consumer_subnet_id" {
  description = "Subnet ID for non-routable/private subnet (EFS mount target)"
  type        = string
}

variable "routable_subnet_id" {
  description = "Subnet ID for routable subnet (PrivateLink interface endpoint)"
  type        = string
}

variable "nlb_arn" {
  description = "ARN of the Network Load Balancer to expose via PrivateLink"
  type        = string
}



resource "grafana_sso_settings" "oidc" {
  provider_name = "generic_oauth"

  oauth2_settings {
    name              = var.oidc_name      # "Company OIDC"
    auth_url          = var.oidc_auth_url
    token_url         = var.oidc_token_url
    api_url           = var.oidc_api_url   # user info endpoint
    client_id         = var.oidc_client_id
    client_secret     = var.oidc_client_secret
    scopes            = "openid email profile"
    allow_sign_up     = false
    auto_login        = false
    use_pkce          = true
    use_refresh_token = true
    # allowed_domains or team/role mapping can be added as needed
  }
}

#########################
# NETWORKING CONT'D
#########################
resource "aws_vpc_endpoint_service" "this" {
  acceptance_required        = false
  network_load_balancer_arns = [aws_lb.your_nlb.arn]
}

-- # PrivateLink interface endpoint in routable subnet
resource "aws_vpc_endpoint" "this" {
  vpc_id              = aws_vpc.consumer.id
  service_name        = aws_vpc_endpoint_service.this.service_name
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.routable_subnet.id]
  private_dns_enabled = false
}


#########################
# EFS with encryption
#########################
resource "aws_efs_file_system" "this" {
  encrypted = true

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name = "private-efs"
  }
}

# Security group to allow ECS tasks to connect (NFS = port 2049)
resource "aws_security_group" "efs_sg" {
  name        = "efs-sg"
  description = "Allow NFS from ECS tasks"
  vpc_id      = aws_vpc.consumer.id   # replace with your non-routable VPC id

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.consumer.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EFS Mount Target in private subnet
resource "aws_efs_mount_target" "this" {
  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = aws_subnet.consumer_subnet.id   # your non-routable/private subnet
  security_groups = [aws_security_group.efs_sg.id]
}

# EFS Access Point (preferred for ECS)
resource "aws_efs_access_point" "this" {
  file_system_id = aws_efs_file_system.this.id

  posix_user {
    gid = 1000
    uid = 1000
  }

  root_directory {
    path = "/ecs"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "0755"
    }
  }
}

#########################
# Outputs
#########################
# EFS DNS name (use in ECS task volume)
output "efs_dns_name" {
  value = aws_efs_file_system.this.dns_name
}

output "efs_access_point" {
  value = aws_efs_access_point.this.id
}



-- "volumes": [
--   {
--     "name": "efs-volume",
--     "efsVolumeConfiguration": {
--       "fileSystemId": "<efs id>",
--       "transitEncryption": "ENABLED",
--       "authorizationConfig": {
--         "accessPointId": "<access point id>",
--         "iam": "DISABLED"
--       }
--     }
--   }
-- ],
-- "containerDefinitions": [
--   {
--     "name": "app",
--     "image": "nginx",
--     "mountPoints": [
--       {
--         "containerPath": "/mnt/data",
--         "sourceVolume": "efs-volume"
--       }
--     ]
--   }
-- ]

```

