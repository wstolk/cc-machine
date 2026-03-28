# cc-machine

One-command setup for an **Ubuntu 24 LTS** vibe-coding machine with Claude Code at the centre.

## What gets installed

| Component | Tool / Version |
|---|---|
| Package manager | [Nix](https://nixos.org) (multi-user daemon) + [Home Manager](https://github.com/nix-community/home-manager) |
| Terminal multiplexer | [Zellij](https://zellij.dev) |
| Shell | ZSH + [oh-my-zsh](https://ohmyz.sh) |
| AI coding assistant | [Claude Code](https://docs.anthropic.com/en/docs/claude-code) (`@anthropic-ai/claude-code`) |
| Claude Code plugins | [impeccable](https://github.com/pbakaus/impeccable) · [superpowers](https://github.com/obra/superpowers) |
| Browser testing | [agent-browser](https://github.com/vercel-labs/agent-browser) (Playwright-based) |
| Rust | [rustup](https://rustup.rs) (stable toolchain) |
| Java / Kotlin | [SDKMan](https://sdkman.io) → JDK 21 LTS (Temurin) · Kotlin · Gradle · Maven |
| Go | Nix (`nixpkgs` – latest stable) |
| TypeScript / Node.js | Nix (Node 22 LTS) + npm |
| Python | [uv](https://github.com/astral-sh/uv) + Python 3.12 |
| Dev utilities | `git`, `gh`, `fzf`, `bat`, `eza`, `ripgrep`, `fd`, `jq`, `direnv`, `just`, `neovim`, … |

## Quick start

```bash
# Clone the repo
git clone https://github.com/wstolk/cc-machine.git
cd cc-machine

# Run the installer (regular user, not root)
./install.sh
```

> **Note:** The installer will use `sudo` for steps that require elevated privileges (apt packages, Nix daemon setup, `chsh`).  You will be prompted for your password.

After installation completes, **open a new terminal** (or log out and back in) so the new ZSH configuration and Nix paths take effect.

Then authenticate Claude Code:

```bash
claude login
```

## Repository structure

```
cc-machine/
├── install.sh                  # Main orchestration script
├── flake.nix                   # Nix flake (reproducible package inputs)
├── home.nix                    # Home Manager config (ZSH, Zellij, packages)
└── config/
    ├── zellij/
    │   └── config.kdl          # Zellij keybindings & theme
    ├── zsh/
    │   └── extras.zsh          # SDKMan, rustup, uv, Go PATH init
    └── claude/
        └── CLAUDE.md           # Machine-level Claude Code agent preferences
```

## Machine-level Claude Code preferences

The file `config/claude/CLAUDE.md` is copied to `~/.claude/CLAUDE.md` during installation. Claude Code reads this file on every startup in every project on this machine. It instructs Claude to:

- **Plan first** – create an explicit numbered plan and get approval before coding.
- **Test-Driven Development** – write failing tests first, then implement, then refactor.
- **Meaningful tests** – tests must verify real behaviour, not trivial implementation details.
- **Document thoroughly** – all public APIs get doc comments; explain *why* not just *what*.
- Follow language-specific tooling preferences (uv, rustup, SDKMan, etc.).

Edit `~/.claude/CLAUDE.md` after installation to personalise further.

## Claude Code plugins

### impeccable
A set of slash commands for comprehensive code review, installed to `~/.claude/plugins/impeccable` and symlinked into `~/.claude/commands/`.

Usage inside Claude Code:
```
/review
```

### superpowers
Extended tools and capabilities for Claude Code, installed to `~/.claude/plugins/superpowers`.

## agent-browser

[agent-browser](https://github.com/vercel-labs/agent-browser) is installed to `~/.local/share/agent-browser`.  It provides a Playwright-based browser automation tool so Claude Code can run end-to-end tests against local or remote web apps.

To use it inside Claude Code, reference the tool in your project's `CLAUDE.md` or as part of a test command.

## Zellij

Zellij starts automatically when you open a new terminal and attaches to (or creates) a session named `main`.

Key bindings (see `config/zellij/config.kdl` for the full list):

| Key | Action |
|---|---|
| `Ctrl p` | New pane |
| `Ctrl w` | Close focused pane |
| `Ctrl h/j/k/l` | Move focus between panes |
| `Ctrl t` | New tab |
| `Alt [`/`]` | Previous / next tab |
| `Ctrl f` | Enter scroll / search mode |
| `Ctrl z` | Toggle full-screen for focused pane |

## Language tooling

### Rust
```bash
rustup update stable       # update toolchain
cargo new my-project       # new project
```

### Java / Kotlin (SDKMan)
```bash
sdk list java              # available JDK versions
sdk install java 21.0.3-tem
sdk use java 17.0.11-tem   # switch for current session

sdk install kotlin
sdk install gradle
sdk install maven
```

### Python (uv)
```bash
uv init my-project         # new project with pyproject.toml
uv add requests            # add a dependency
uv run python main.py      # run with project venv
uv tool install ruff       # install a global tool
```

### Go
```bash
go mod init example.com/myapp
go build ./...
go test ./...
```

### TypeScript / Node.js
```bash
npx create-next-app my-app
npm install
npm run dev
```

## Updating

Re-run `install.sh` at any time – every step is idempotent and will skip components that are already up-to-date, or update them if they support it.

```bash
cd cc-machine
git pull
./install.sh
```

## Nix flake

The `flake.nix` and `home.nix` files expose a Home Manager configuration that you can also apply directly:

```bash
# Apply with flakes (after `nix-command` and `flakes` are enabled)
home-manager switch --flake .#default
```

Or use the included dev shell:

```bash
nix develop   # drops into a shell with all Nix-managed tools
```

## Requirements

- Ubuntu 24.04 LTS (x86_64)
- A non-root user with `sudo` access
- Internet connection
