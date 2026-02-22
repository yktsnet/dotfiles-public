{ pkgs, ... }:

{
  programs.lazygit = {
    enable = true;
    settings = {
      gui = {
        sidePanelWidth = 0.2;
        showIcons = true;
      };
      git = {
        autoFetch = false;
        pagers = [ ];
      };
    };
  };

  home.packages = with pkgs; [
    lazygit
  ];
}
