{ pkgs, ... }:

{
  home.packages = with pkgs; [
    grim
    slurp
    wl-clipboard
    wireplumber
    brightnessctl
  ];

  xdg.configFile."hypr".source = ./hypr;
}
