# Home Manager configuration for cc-machine
# Applied automatically by install.sh
{ config, pkgs, lib, username ? "user", homeDirectory ? "/home/user", ... }:

{
  home.username = username;
  home.homeDirectory = homeDirectory;

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # ---------------------------------------------------------------------------
  # Core packages
  # ---------------------------------------------------------------------------
  home.packages = with pkgs; [
    # Shell & terminal utilities
    zsh
    fzf
    bat
    eza          # modern ls replacement
    ripgrep
    fd
    jq
    yq-go
    htop
    btop
    tree
    tmux
    unzip
    zip
    wget
    curl
    gnupg
    openssh

    # Version control
    git
    git-lfs
    gh               # GitHub CLI

    # Build essentials
    gcc
    gnumake
    cmake
    pkg-config
    openssl
    openssl.dev

    # Languages managed by Nix
    go                  # Golang
    nodejs_22           # Node.js (TypeScript / Claude Code npm)
    nodePackages.npm
    nodePackages.typescript
    nodePackages.ts-node

    # Zellij terminal multiplexer
    zellij

    # Container & cloud tools
    docker-compose
    kubectl

    # Misc dev tools
    direnv
    shellcheck
    just              # command runner (Justfile)
    watchexec
  ];

  # ---------------------------------------------------------------------------
  # Git configuration
  # ---------------------------------------------------------------------------
  programs.git = {
    enable = true;
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      core.editor = "nvim";
    };
  };

  # ---------------------------------------------------------------------------
  # ZSH + oh-my-zsh
  # ---------------------------------------------------------------------------
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;

    history = {
      size = 50000;
      save = 50000;
      ignoreDups = true;
      share = true;
    };

    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [
        "git"
        "docker"
        "kubectl"
        "rust"
        "golang"
        "node"
        "npm"
        "python"
        "fzf"
        "direnv"
        "sudo"
        "z"
        "colored-man-pages"
        "command-not-found"
      ];
    };

    # Extra aliases
    shellAliases = {
      ls  = "eza --icons";
      ll  = "eza -la --icons";
      lt  = "eza --tree --icons";
      cat = "bat";
      grep = "rg";
      find = "fd";
      g   = "git";
      k   = "kubectl";
      dc  = "docker-compose";
    };

    # Source extra ZSH configuration (SDKMan, uv, rustup, etc.)
    initExtra = ''
      # Load extra configuration managed outside Nix
      [ -f "$HOME/.config/zsh/extras.zsh" ] && source "$HOME/.config/zsh/extras.zsh"

      # Nix & home-manager paths
      [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ] && source "$HOME/.nix-profile/etc/profile.d/nix.sh"

      # direnv hook
      eval "$(direnv hook zsh)"

      # fzf keybindings & completion
      [ -f "${pkgs.fzf}/share/fzf/key-bindings.zsh" ]  && source "${pkgs.fzf}/share/fzf/key-bindings.zsh"
      [ -f "${pkgs.fzf}/share/fzf/completion.zsh" ]     && source "${pkgs.fzf}/share/fzf/completion.zsh"
    '';
  };

  # ---------------------------------------------------------------------------
  # Zellij
  # ---------------------------------------------------------------------------
  programs.zellij = {
    enable = true;
    # Auto-start zellij when opening a terminal
    enableZshIntegration = true;
    settings = {};
  };

  # Copy our Zellij config
  xdg.configFile."zellij/config.kdl".source = ./config/zellij/config.kdl;

  # ---------------------------------------------------------------------------
  # direnv
  # ---------------------------------------------------------------------------
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  # ---------------------------------------------------------------------------
  # fzf
  # ---------------------------------------------------------------------------
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "fd --type f --hidden --follow --exclude .git";
    defaultOptions = [ "--height 40%" "--border" "--preview 'bat --color=always {}'" ];
  };

  # ---------------------------------------------------------------------------
  # Neovim (lightweight fallback editor)
  # ---------------------------------------------------------------------------
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;
  };

  # This value determines the Home Manager release that your configuration is
  # compatible with. Do not change it.
  home.stateVersion = "24.05";
}
