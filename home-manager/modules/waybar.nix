{ pkgs, ... }:

let
zscroll-script = pkgs.writeShellScriptBin "zscroll-mpris" ''
    export PATH=${pkgs.zscroll}/bin:${pkgs.playerctl}/bin:${pkgs.coreutils}/bin:$PATH
    PLAYER_OPTS="--ignore-player firefox"
    
    pkill -u $(id -u) -x zscroll || true
    
    zscroll -l 30 \
        --delay 0.3 \
        --match-command "playerctl $PLAYER_OPTS status" \
        --match-text "Playing" "--scroll 1" \
        --match-text "Paused" "--scroll 0" \
        --update-check true \
        "playerctl $PLAYER_OPTS metadata --format '{{ title }} - {{ artist }}'" 2>/dev/null
  '';
in
{
  programs.waybar = {
    enable = true;
    systemd.enable = true;
  };

  home.packages = with pkgs; [
    playerctl
    zscroll
    zscroll-script
  ];

  xdg.configFile."waybar/config".source = ./waybar/config;
  xdg.configFile."waybar/style.css".source = ./waybar/style.css;
}