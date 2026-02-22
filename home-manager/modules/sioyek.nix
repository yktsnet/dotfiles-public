{ pkgs, ... }:

{
  programs.sioyek = {
    enable = true;
    config = {
      "background_color" = "0.0 0.0 0.0";
      "dark_mode_contrast" = "0.8";
      "text_highlight_color" = "1.0 1.0 0.0";
    };
  };
}