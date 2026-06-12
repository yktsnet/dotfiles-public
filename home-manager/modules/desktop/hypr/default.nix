{ pkgs, ... }:

{
  home.file.".config/hypr/scripts/workspace_colors.sh" = {
    source = ./workspace_colors.sh;
    executable = true;
  };

  home.file.".config/hypr/scripts/mute_handler.sh" = {
    source = ./mute_handler.sh;
    executable = true;
  };

  wayland.windowManager.hyprland = {
    enable = true;
    extraConfig = builtins.readFile ./hyprland.conf;
  };
}
