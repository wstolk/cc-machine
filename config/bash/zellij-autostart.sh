# ---------------------------------------------------------------------------
# cc-machine: Bash fallback for Zellij auto-start
# Sourced from ~/.bashrc when the login shell is still bash
# (e.g. chsh to zsh failed or hasn't taken effect yet).
# ---------------------------------------------------------------------------

# Ensure Nix-managed binaries (including zellij) are on PATH
for _p in "$HOME/.nix-profile/bin" \
          "/nix/var/nix/profiles/default/bin" \
          "$HOME/.local/state/nix/profiles/home-manager/home-path/bin"; do
  [[ -d "$_p" ]] && [[ ":$PATH:" != *":$_p:"* ]] && export PATH="$_p:$PATH"
done
unset _p

# Auto-start Zellij (skip if already inside Zellij, tmux, or VSCode)
if [[ -z "$ZELLIJ" ]] && [[ -z "$TMUX" ]] && [[ "$TERM_PROGRAM" != "vscode" ]]; then
  if command -v zellij &>/dev/null; then
    exec zellij attach --create main
  fi
fi
