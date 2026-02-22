{ pkgs, lib, config, osConfig, ... }:

{
  imports = [
    ../../home-manager/modules/btop.nix
    ../../home-manager/modules/tmux.nix
    ../ssh.nix
    ../../home-manager/modules/keepassxc.nix
    ../../home-manager/modules/ranger/home.nix
    ../../home-manager/modules/zsh/ui.nix
    ../../home-manager/modules/glow.nix
    ../../home-manager/modules/fonts.nix
    ../../home-manager/modules/vscode.nix
    ../../home-manager/modules/kitty.nix
    ../../home-manager/modules/fcitx.nix
    ../../home-manager/modules/git.nix
    ../../home-manager/modules/desktop/gui-bundle.nix
    ../../home-manager/modules/firefox.nix
    ../../home-manager/modules/ntfy.nix
    ../../home-manager/modules/sioyek.nix
    ../../home-manager/modules/mpv.nix
    ../../home-manager/modules/helix.nix
  ];

  home.username = "yktsnet";
  home.homeDirectory = "/home/yktsnet";
  home.stateVersion = "23.11";

  home.activation.checkSopsKey = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
    if [ ! -f "${config.home.homeDirectory}/.config/sops/age/keys.txt" ]; then
      echo -e "\033[1;31m[CRITICAL ERROR] SOPS age key missing!\033[0m"
      echo -e "\033[1;31mLocation: ~/.config/sops/age/keys.txt\033[0m"
      echo -e "\033[1;31mActivation aborted to prevent inconsistent state.\033[0m"
      exit 1
    fi
  '';

  programs.zsh = {
    enable = lib.mkForce true;
    dotDir = "${config.xdg.configHome}/zsh";
  };

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    htop
    curl
    wget
    tree
    jq
    ripgrep
    fzf
    rsync
    unzip
    ncdu
    desktop-file-utils
    wl-clipboard
  ];
  home.file.".ssh/id_ed25519".source = config.lib.file.mkOutOfStoreSymlink osConfig.sops.secrets."common/id_ed25519.txt".path;

  home.file = {
    "dotfiles-hub/current-host-system".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/devices/gui/${osConfig.networking.hostName}/system.nix";
    "dotfiles-hub/current-host-home".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/devices/gui/${osConfig.networking.hostName}/home.nix";
  };

  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
  };
}
