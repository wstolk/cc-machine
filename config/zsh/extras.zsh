# ---------------------------------------------------------------------------
# cc-machine: extra ZSH configuration
# Sourced at the end of ~/.zshrc by home-manager's ZSH config.
# Contains initialisation for tools installed outside Nix
# (SDKMan, rustup, uv, etc.)
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# SDKMan (Java, Kotlin, Gradle, Maven, …)
# ---------------------------------------------------------------------------
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

# ---------------------------------------------------------------------------
# Rust / Cargo (installed via rustup)
# ---------------------------------------------------------------------------
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"
export PATH="$HOME/.cargo/bin:$PATH"

# ---------------------------------------------------------------------------
# uv (Python package & project manager)
# ---------------------------------------------------------------------------
export PATH="$HOME/.local/bin:$PATH"
[ -f "$HOME/.local/bin/uv" ] && eval "$(uv generate-shell-completion zsh 2>/dev/null)"

# Default Python via uv
alias python="uv run python"
alias pip="uv pip"

# ---------------------------------------------------------------------------
# Go (set GOPATH if not already defined by Nix)
# ---------------------------------------------------------------------------
export GOPATH="${GOPATH:-$HOME/go}"
export PATH="$GOPATH/bin:$PATH"

# ---------------------------------------------------------------------------
# Node / npm global packages (Claude Code lives here)
# ---------------------------------------------------------------------------
export PATH="$HOME/.npm-global/bin:$PATH"

# ---------------------------------------------------------------------------
# Zellij auto-start: open Zellij when entering a new interactive shell
# (skip if already inside Zellij or a tmux session)
# ---------------------------------------------------------------------------
# Ensure Nix-managed binaries (including zellij) are on PATH
for _p in "$HOME/.nix-profile/bin" \
          "/nix/var/nix/profiles/default/bin" \
          "$HOME/.local/state/nix/profiles/home-manager/home-path/bin"; do
  [[ -d "$_p" ]] && [[ ":$PATH:" != *":$_p:"* ]] && export PATH="$_p:$PATH"
done
unset _p

if [[ -z "$ZELLIJ" ]] && [[ -z "$TMUX" ]] && [[ "$TERM_PROGRAM" != "vscode" ]]; then
  if command -v zellij &>/dev/null; then
    # Attach to an existing session named 'main', or create it
    exec zellij attach --create main
  fi
fi
