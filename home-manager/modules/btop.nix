{ pkgs, ... }:

{
  programs.btop = {
    enable = true;
    settings = {
      color_theme = "night-owl";
      theme_background = false;
      truecolor = true;
      force_tty = false;
      presets = "cpu:0:default,mem:0:default,net:0:default,proc:0:default";
      vim_keys = true;
      update_ms = 2000;
      graph_symbol = "braille"; # ブロック表示をやめ、滑らかな点字描画へ
      rounded_corners = true;
    };
  };
}