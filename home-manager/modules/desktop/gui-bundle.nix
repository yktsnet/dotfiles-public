{ pkgs, ... }:

{
  imports = [
    ./../lazygit.nix
    ./gtk.nix
    ../vscode.nix
    ../fonts.nix
    ./hypr/default.nix
    ../waybar.nix
  ];

  home.packages = with pkgs; [
    socat
    jq
    mosh
    wl-clipboard
    obsidian
    inkscape
  ];

  home.sessionVariables = {
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    GDK_BACKEND = "wayland";
  };
}
