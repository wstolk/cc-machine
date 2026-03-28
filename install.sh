#!/usr/bin/env bash
# =============================================================================
# cc-machine install.sh
#
# One-command setup for an Ubuntu 24 LTS vibe-coding machine.
# If run as root, automatically creates a 'claude' user and re-runs as that user.
# Can also be run directly as a regular user (NOT root).
#
# Usage:
#   bash <(curl -fsSL https://raw.githubusercontent.com/wstolk/cc-machine/main/install.sh)
# or, after cloning:
#   ./install.sh
# =============================================================================
set -euo pipefail

# ── colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()    { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }
section() { echo -e "\n${CYAN}══ $* ══${NC}\n"; }

# ── helpers ───────────────────────────────────────────────────────────────────
have() { command -v "$1" &>/dev/null; }

# ── root handling: create claude user and re-exec ────────────────────────────
REPO_URL="https://github.com/wstolk/cc-machine.git"
TARGET_USER="claude"
TARGET_HOME="/home/${TARGET_USER}"

if [[ "$EUID" -eq 0 ]]; then
    section "Running as root – bootstrapping '$TARGET_USER' user"

    # 1. Create the user (idempotent)
    if ! id "$TARGET_USER" &>/dev/null; then
        info "Creating user '$TARGET_USER'…"
        useradd -m -s /bin/bash "$TARGET_USER"
    else
        info "User '$TARGET_USER' already exists – skipping creation."
    fi

    # 2. Grant passwordless sudo
    if [[ ! -f "/etc/sudoers.d/$TARGET_USER" ]]; then
        info "Granting passwordless sudo to '$TARGET_USER'…"
        echo "$TARGET_USER ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$TARGET_USER"
        chmod 0440 "/etc/sudoers.d/$TARGET_USER"
    fi

    # 3. Copy SSH authorized_keys so the user can log in via SSH
    if [[ -f /root/.ssh/authorized_keys ]]; then
        TARGET_SSH_DIR="$TARGET_HOME/.ssh"
        mkdir -p "$TARGET_SSH_DIR"
        cp /root/.ssh/authorized_keys "$TARGET_SSH_DIR/authorized_keys"
        chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_SSH_DIR"
        chmod 700 "$TARGET_SSH_DIR"
        chmod 600 "$TARGET_SSH_DIR/authorized_keys"
        info "Copied root's SSH authorized_keys to $TARGET_USER."
    else
        warn "No /root/.ssh/authorized_keys found – skipping SSH key copy."
        warn "You will need to set up SSH access for '$TARGET_USER' manually."
    fi

    # 4. Clone the repo into the claude user's home
    CC_REPO_DIR="$TARGET_HOME/cc-machine"
    if [[ -d "$CC_REPO_DIR/.git" ]]; then
        info "cc-machine repo already exists at $CC_REPO_DIR – pulling latest."
        sudo -u "$TARGET_USER" git -C "$CC_REPO_DIR" pull --ff-only \
            || warn "git pull failed – using existing checkout."
    else
        info "Cloning cc-machine into $CC_REPO_DIR…"
        apt-get update -qq
        apt-get install -y --no-install-recommends git
        sudo -u "$TARGET_USER" git clone "$REPO_URL" "$CC_REPO_DIR"
    fi

    # 5. Re-execute as the claude user (exec replaces this process)
    info "Re-executing install.sh as '$TARGET_USER'…"
    exec sudo -u "$TARGET_USER" bash "$CC_REPO_DIR/install.sh" "$@"
fi

# ── resolved identity (always a non-root user at this point) ─────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USERNAME="${USER:-$(id -un)}"
HOME_DIR="${HOME:-/home/$USERNAME}"
cd "$HOME_DIR" || error "Cannot change to home directory '$HOME_DIR'"

# =============================================================================
# 0. System prerequisites
# =============================================================================
section "System prerequisites"
sudo apt-get update -qq
sudo apt-get install -y --no-install-recommends \
    curl wget git build-essential pkg-config libssl-dev \
    zsh unzip ca-certificates gnupg lsb-release \
    software-properties-common apt-transport-https

# =============================================================================
# 1. Nix (multi-user / daemon install)
# =============================================================================
section "Nix"
if have nix; then
    info "Nix already installed – skipping."
else
    info "Installing Nix (multi-user)…"
    # Clean up leftovers from any previous failed Nix install attempt.
    # 1. Stop the nix-daemon so the installer can overwrite binaries
    #    (avoids "Text file busy" errors).
    if sudo systemctl is-active --quiet nix-daemon.service 2>/dev/null; then
        sudo systemctl stop nix-daemon.socket nix-daemon.service
    fi
    # 2. Restore shell profile backups so the installer can create fresh ones.
    for f in /etc/bash.bashrc /etc/bashrc /etc/profile /etc/zshrc /etc/zsh/zshrc; do
        if [[ -f "${f}.backup-before-nix" ]]; then
            sudo mv "${f}.backup-before-nix" "$f"
        fi
    done
    curl -fsSL https://nixos.org/nix/install | sh -s -- --daemon --yes
    # Source Nix in this script session
    # shellcheck disable=SC1091
    source /etc/profile.d/nix.sh
fi

# Make nix available in the current shell if the daemon just started
if [[ -f /etc/profile.d/nix.sh ]]; then
    # shellcheck disable=SC1091
    source /etc/profile.d/nix.sh
fi

# Enable flakes + nix-command for the installing user
NIX_CONF_DIR="$HOME_DIR/.config/nix"
mkdir -p "$NIX_CONF_DIR"
if ! grep -q "experimental-features" "$NIX_CONF_DIR/nix.conf" 2>/dev/null; then
    echo 'experimental-features = nix-command flakes' >> "$NIX_CONF_DIR/nix.conf"
    info "Enabled nix-command and flakes for $USERNAME."
fi

# =============================================================================
# 2. Home Manager
# =============================================================================
section "Home Manager"
if have home-manager; then
    info "Home Manager already installed – skipping."
else
    info "Installing Home Manager…"
    nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
    nix-channel --update
    # shellcheck disable=SC1091
    nix-shell '<home-manager>' -A install
fi

# Copy our home.nix (with the correct username / home baked in) and apply it
info "Applying Home Manager configuration…"
HM_CONFIG_DIR="$HOME_DIR/.config/home-manager"
mkdir -p "$HM_CONFIG_DIR"

# Substitute the actual username / home dir into home.nix before copying
sed \
    -e "s|username ? \"user\"|username ? \"${USERNAME}\"|g" \
    -e "s|homeDirectory ? \"/home/user\"|homeDirectory ? \"${HOME_DIR}\"|g" \
    "$SCRIPT_DIR/home.nix" > "$HM_CONFIG_DIR/home.nix"

# Copy supporting config files referenced by home.nix
mkdir -p "$HM_CONFIG_DIR/config/zellij"
cp "$SCRIPT_DIR/config/zellij/config.kdl" "$HM_CONFIG_DIR/config/zellij/config.kdl"

home-manager switch || warn "Home Manager switch had non-fatal errors – continuing."

# =============================================================================
# 3. ZSH as default shell
# =============================================================================
section "ZSH default shell"
ZSH_PATH="$(which zsh 2>/dev/null || echo "$HOME_DIR/.nix-profile/bin/zsh")"
if [[ "$SHELL" != "$ZSH_PATH" ]]; then
    # Add zsh to /etc/shells if not already present
    if ! grep -qF "$ZSH_PATH" /etc/shells; then
        echo "$ZSH_PATH" | sudo tee -a /etc/shells
    fi
    sudo chsh -s "$ZSH_PATH" "$USERNAME"
    info "Default shell changed to $ZSH_PATH."
else
    info "ZSH is already the default shell."
fi

# Deploy extra ZSH config sourced at the end of .zshrc
mkdir -p "$HOME_DIR/.config/zsh"
cp "$SCRIPT_DIR/config/zsh/extras.zsh" "$HOME_DIR/.config/zsh/extras.zsh"

# =============================================================================
# 4. Rust (via rustup)
# =============================================================================
section "Rust / rustup"
if have rustup; then
    info "rustup already installed – updating toolchain."
    rustup update stable
else
    info "Installing rustup…"
    curl -fsSL https://sh.rustup.rs | sh -s -- -y --default-toolchain stable --profile default
    # shellcheck disable=SC1091
    source "$HOME_DIR/.cargo/env"
fi

# =============================================================================
# 5. SDKMan → Java 21 LTS + Kotlin + Gradle + Maven
# =============================================================================
section "SDKMan (Java / Kotlin / Gradle / Maven)"
if [[ -d "$HOME_DIR/.sdkman" ]]; then
    info "SDKMan already installed – sourcing."
else
    info "Installing SDKMan…"
    curl -fsSL https://get.sdkman.io | bash
fi

# shellcheck disable=SC1091
source "$HOME_DIR/.sdkman/bin/sdkman-init.sh"

_sdk_install() {
    local candidate="$1"; shift
    local version="${1:-}"
    if sdk list "$candidate" 2>/dev/null | grep -q "installed"; then
        info "$candidate already installed via SDKMan."
    elif [[ -n "$version" ]]; then
        sdk install "$candidate" "$version" || warn "SDKMan install $candidate $version failed."
    else
        sdk install "$candidate" || warn "SDKMan install $candidate failed."
    fi
}

_sdk_install java   "21.0.3-tem"
_sdk_install kotlin
_sdk_install gradle
_sdk_install maven

# =============================================================================
# 6. uv (Python manager)
# =============================================================================
section "uv (Python)"
if have uv; then
    info "uv already installed – skipping."
else
    info "Installing uv…"
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi
# Install a stable Python via uv
"$HOME_DIR/.local/bin/uv" python install 3.12 2>/dev/null || true

# =============================================================================
# 7. Claude Code (npm global package)
# =============================================================================
section "Claude Code"

# Configure npm to use a user-writable global prefix (no sudo needed)
NPM_GLOBAL="$HOME_DIR/.npm-global"
mkdir -p "$NPM_GLOBAL"
npm config set prefix "$NPM_GLOBAL"

if have claude; then
    info "Claude Code already installed – updating."
    npm update -g @anthropic-ai/claude-code
else
    info "Installing Claude Code…"
    npm install -g @anthropic-ai/claude-code
fi

# =============================================================================
# 8. Claude Code plugins: impeccable + superpowers
# =============================================================================
section "Claude Code plugins"
CLAUDE_DIR="$HOME_DIR/.claude"
COMMANDS_DIR="$CLAUDE_DIR/commands"
mkdir -p "$COMMANDS_DIR"

# ── impeccable ────────────────────────────────────────────────────────────────
IMPECCABLE_DIR="$CLAUDE_DIR/plugins/impeccable"
if [[ -d "$IMPECCABLE_DIR" ]]; then
    info "Updating impeccable…"
    git -C "$IMPECCABLE_DIR" pull --ff-only || warn "Could not update impeccable."
else
    info "Cloning impeccable…"
    git clone https://github.com/pbakaus/impeccable "$IMPECCABLE_DIR" \
        || warn "Failed to clone impeccable – skipping."
fi

# Symlink any slash-command .md files into ~/.claude/commands/
if [[ -d "$IMPECCABLE_DIR/commands" ]]; then
    for cmd_file in "$IMPECCABLE_DIR/commands"/*.md; do
        [[ -f "$cmd_file" ]] || continue
        ln -sf "$cmd_file" "$COMMANDS_DIR/$(basename "$cmd_file")" 2>/dev/null || true
    done
fi

# ── superpowers ───────────────────────────────────────────────────────────────
SUPERPOWERS_DIR="$CLAUDE_DIR/plugins/superpowers"
if [[ -d "$SUPERPOWERS_DIR" ]]; then
    info "Updating superpowers…"
    git -C "$SUPERPOWERS_DIR" pull --ff-only || warn "Could not update superpowers."
else
    info "Cloning superpowers…"
    git clone https://github.com/obra/superpowers "$SUPERPOWERS_DIR" \
        || warn "Failed to clone superpowers – skipping."
fi

# Install superpowers dependencies if a package.json is present
if [[ -f "$SUPERPOWERS_DIR/package.json" ]]; then
    info "Installing superpowers npm dependencies…"
    (cd "$SUPERPOWERS_DIR" && npm install) \
        || warn "superpowers npm install failed."
fi

# Symlink superpowers slash commands
if [[ -d "$SUPERPOWERS_DIR/commands" ]]; then
    for cmd_file in "$SUPERPOWERS_DIR/commands"/*.md; do
        [[ -f "$cmd_file" ]] || continue
        ln -sf "$cmd_file" "$COMMANDS_DIR/$(basename "$cmd_file")" 2>/dev/null || true
    done
fi

# =============================================================================
# 9. agent-browser (Vercel Labs – browser automation for Claude Code testing)
# =============================================================================
section "agent-browser"
AGENT_BROWSER_DIR="$HOME_DIR/.local/share/agent-browser"
if [[ -d "$AGENT_BROWSER_DIR" ]]; then
    info "Updating agent-browser…"
    git -C "$AGENT_BROWSER_DIR" pull --ff-only || warn "Could not update agent-browser."
else
    info "Cloning agent-browser…"
    git clone https://github.com/vercel-labs/agent-browser "$AGENT_BROWSER_DIR" \
        || warn "Failed to clone agent-browser – skipping."
fi

if [[ -f "$AGENT_BROWSER_DIR/package.json" ]]; then
    info "Installing agent-browser npm dependencies…"
    (cd "$AGENT_BROWSER_DIR" && npm install) || warn "agent-browser npm install failed."
    if grep -q '"build"' "$AGENT_BROWSER_DIR/package.json"; then
        (cd "$AGENT_BROWSER_DIR" && npm run build) || warn "agent-browser build failed."
    fi
fi

# Install Playwright browsers if Playwright is a dependency
if [[ -f "$AGENT_BROWSER_DIR/node_modules/.bin/playwright" ]]; then
    info "Installing Playwright browsers…"
    (cd "$AGENT_BROWSER_DIR" && npx playwright install --with-deps chromium) \
        || warn "Playwright browser install failed."
fi

# =============================================================================
# 10. Machine-level Claude Code agent configuration
# =============================================================================
section "Claude Code agent configuration"
mkdir -p "$CLAUDE_DIR"
cp "$SCRIPT_DIR/config/claude/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
info "Wrote machine-level agent config to $CLAUDE_DIR/CLAUDE.md"

# =============================================================================
# Done
# =============================================================================
section "Setup complete 🎉"
cat <<'EOF'

  Next steps:
  1. Log out and back in (or open a new terminal) so ZSH becomes active.
  2. Authenticate Claude Code:
       claude login
  3. (Optional) Configure your Git identity:
       git config --global user.name  "Your Name"
       git config --global user.email "you@example.com"
  4. (Optional) Install additional Java versions with SDKMan:
       sdk install java 17.0.11-tem

  Installed components:
    ✓ Nix (multi-user)
    ✓ Home Manager + ZSH + oh-my-zsh + Zellij
    ✓ Rust (rustup / stable)
    ✓ Java 21 LTS + Kotlin + Gradle + Maven (SDKMan)
    ✓ Go (Nix)
    ✓ TypeScript / Node.js 22 (Nix)
    ✓ Python (uv)
    ✓ Claude Code (npm)
    ✓ impeccable (Claude Code slash commands)
    ✓ superpowers (Claude Code tools)
    ✓ agent-browser (browser automation)
    ✓ Machine-level Claude Code agent config (~/.claude/CLAUDE.md)

EOF
