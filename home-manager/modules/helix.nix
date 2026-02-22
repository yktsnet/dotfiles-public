{ pkgs, inputs, ... }:

{
  programs.helix = {
    enable = true;
    settings = {
      theme = "poimandres";
      editor = {
        line-number = "relative";
        cursorline = true;
        color-modes = true;
        mouse = true;
        clipboard-provider = "wayland";
        bufferline = "always";
        soft-wrap = {
          enable = true;
          wrap-at-text-width = false;
        };
        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "block";
        };
        indent-guides = {
          render = true;
          character = "╎";
        };
        lsp = {
          display-messages = true;
          display-inlay-hints = true;
        };
        statusline = {
          left = [ "mode" "spacer" "file-absolute-path" "spacer" "read-only-indicator" "file-modification-indicator" ];
          center = [ ];
          right = [ "diagnostics" "selections" "position" "position-percentage" "file-encoding" "file-type" ];
          mode.normal = "NORMAL";
          mode.insert = "INSERT";
          mode.select = "SELECT";
        };
      };
      keys.normal = {
        "A-h" = "move_char_left";
        "A-j" = "move_line_down";
        "A-k" = "move_line_up";
        "A-l" = "move_char_right";
        "A-g" = "goto_line_start";
        "A-;" = "goto_line_end";
        "A-n" = "page_down";
        "A-p" = "page_up";
        "A-z" = "undo";
        "A-d" = "delete_char_forward";
        "A-c" = "yank_main_selection_to_clipboard";
        "A-v" = "paste_clipboard_after";
        "esc" = [ "collapse_selection" "keep_primary_selection" ];
        "A-a" = "select_all";
        "A-f" = "search";
        "A-o" = "symbol_picker";
        "A-w" = "move_char_right";
        "A-e" = "move_next_word_end";
        "A-J" = "move_line_down";
        "A-K" = "move_line_up";
        "S-j" = "move_line_down";
        "S-k" = "move_line_up";
      };
      keys.select = {
        "A-h" = "move_char_left";
        "A-j" = "move_line_down";
        "A-k" = "move_line_up";
        "A-l" = "move_char_right";
        "A-;" = "goto_line_end";
        "A-z" = "undo";
        "A-c" = "yank_to_clipboard";
        "A-a" = "select_all";
      };
      keys.insert = {
        "A-h" = "move_char_left";
        "A-j" = "move_line_down";
        "A-k" = "move_line_up";
        "A-l" = "move_char_right";
        "A-;" = "goto_line_end";
        "A-z" = "undo";
      };
    };
    languages = {
      language = [
        {
          name = "nix";
          auto-format = true;
          formatter = { command = "nixpkgs-fmt"; };
          language-servers = [ "nixd" ];
        }
        {
          name = "python";
          auto-format = true;
          formatter = { command = "black"; args = [ "--quiet" "-" ]; };
          language-servers = [ "pyright" ];
        }
      ];
      language-server.nixd = {
        command = "nixd";
        config.nixd = {
          formatting.command = [ "nixpkgs-fmt" ];
          options = {
            nixos.expr = "(builtins.getFlake \"/etc/nixos\").nixosConfigurations.default.options";
          };
        };
      };
    };
    extraPackages = with pkgs; [
      nixd
      nixpkgs-fmt
      wl-clipboard
      nodePackages.typescript-language-server
      pyright
      black
    ];
  };
}
