{ pkgs, ... }:
{
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        padding = { x = 8; y = 8; };
        decorations = "None";
        opacity = 0.9;
        dynamic_padding = false;
        option_as_alt = "Both";
      };
      scrolling.history = 10000;
      font = {
        normal = {
          family = "JetBrainsMono Nerd Font";
          style = "Regular";
        };
        bold = {
          family = "JetBrainsMono Nerd Font";
          style = "Bold";
        };
        italic = {
          family = "JetBrainsMono Nerd Font";
          style = "Italic";
        };
        size = 14.0;
      };
      colors = {
        primary = {
          background = "#1b1e28";
          foreground = "#a6accd";
        };
        cursor = {
          text = "#1b1e28";
          cursor = "#a6accd";
        };
        selection = {
          text = "#a6accd";
          background = "#303340";
        };
        normal = {
          black   = "#1b1e28";
          red     = "#d0679d";
          green   = "#5de4c7";
          yellow  = "#addb67";
          blue    = "#89ddff";
          magenta = "#f087bd";
          cyan    = "#addb67";
          white   = "#ffffff";
        };
        bright = {
          black   = "#a6accd";
          red     = "#d0679d";
          green   = "#5de4c7";
          yellow  = "#addb67";
          blue    = "#89ddff";
          magenta = "#f087bd";
          cyan    = "#addb67";
          white   = "#ffffff";
        };
      };
      cursor = {
        style = {
          shape = "Block";
          blinking = "Off";
        };
      };
      mouse.hide_when_typing = true;
      terminal.osc52 = "CopyPaste";
    };
  };
}
