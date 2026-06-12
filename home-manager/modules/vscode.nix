{ config, pkgs, ... }:

{
  programs.vscode = {
    enable = true;
    mutableExtensionsDir = true;
    profiles.default = {
      userSettings = {
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nil";
        "nix.formatterPath" = "nixpkgs-fmt";
        "nix.serverSettings" = {
          "nil" = {
            "flake" = {
              "autoArchive" = false;
            };
          };
        };
        "[nix]" = {
          "editor.defaultFormatter" = "jnoortheen.nix-ide";
          "editor.autoIndent" = "full";
        };
        "workbench.colorTheme" = "Night Owl (No Italics)";
        "workbench.iconTheme" = "catppuccin-mocha";
        "files.exclude" = {
          "**/.direnv" = true;
          "**/.git" = true;
        };
        "search.exclude" = {
          "**/.direnv" = true;
        };
        "terminal.integrated.shellIntegration.enabled" = false;
        "terminal.integrated.persistentSessionReviveProcess" = "never";
        "terminal.integrated.defaultProfile.linux" = "zsh";
        "terminal.integrated.profiles.linux" = {
          "zsh" = {
            "path" = "/run/current-system/sw/bin/zsh";
            "args" = [ "-l" ];
          };
        };
        "files.associations" = {
          "todo.txt" = "plaintext";
          "*.todo" = "plaintext";
        };
        "better-comments.highlightPlainText" = true;
        "window.commandCenter" = false;
        "editor.wordBasedSuggestions" = "off";
        "workbench.hover.delay" = 9999999999;
        "workbench.layoutControl.enabled" = false;
        "chat.commandCenter.enabled" = false;
        "workbench.sideBar.location" = "right";
        "workbench.secondarySideBar.defaultVisibility" = "hidden";
        "workbench.activityBar.location" = "hidden";
        "workbench.panel.showLabels" = false;
        "editor.fontSize" = 12;
        "editor.fontFamily" = "Fira Code";
        "terminal.integrated.fontSize" = 12;
        "editor.minimap.renderCharacters" = false;
        "editor.minimap.autohide" = "mouseover";
        "editor.lineHeight" = 18;
        "editor.suggestLineHeight" = 18;
        "workbench.startupEditor" = "none";
        "editor.minimap.size" = "fit";
        "extensions.ignoreRecommendations" = true;
        "remote.autoForwardPorts" = false;
        "remote.SSH.showLoginTerminal" = false;
        "remote.SSH.logLevel" = "trace";
        "remote.SSH.useLocalServer" = false;
        "security.workspace.trust.untrustedFiles" = "open";
        "terminal.integrated.stickyScroll.enabled" = false;
        "editor.stickyScroll.enabled" = false;
        "explorer.confirmDragAndDrop" = true;
        "files.autoSave" = "afterDelay";
        "terminal.integrated.enablePersistentSessions" = false;
        "explorer.confirmDelete" = false;
        "better-comments.tags" = [
          {
            "tag" = "!";
            "color" = "#f7768e";
            "strikethrough" = false;
            "underline" = false;
            "backgroundColor" = "transparent";
            "bold" = true;
            "italic" = false;
          }
          {
            "tag" = "@";
            "color" = "#9ece6a";
            "strikethrough" = false;
            "underline" = false;
            "backgroundColor" = "transparent";
            "bold" = true;
            "italic" = false;
          }
          {
            "tag" = "?";
            "color" = "#7aa2f7";
            "strikethrough" = false;
            "underline" = false;
            "backgroundColor" = "transparent";
            "bold" = true;
            "italic" = false;
          }
          {
            "tag" = "*";
            "color" = "#e0af68";
            "strikethrough" = false;
            "underline" = false;
            "backgroundColor" = "transparent";
            "bold" = true;
            "italic" = false;
          }
        ];
        "workbench.editor.editorActionsLocation" = "hidden";
        "editor.snippets.codeActions.enabled" = false;
        "workbench.statusBar.visible" = false;
        "window.menuBarVisibility" = "none";
        "window.customMenuBarAltFocus" = false;
        "editor.multiCursorModifier" = "ctrlCmd";
      };
      keybindings = [
        {
          "key" = "alt+d";
          "command" = "-deleteRight";
        }
        {
          "key" = "ctrl+alt+n";
          "command" = "workbench.action.terminal.new";
        }
        {
          "key" = "ctrl+alt+k";
          "command" = "workbench.action.terminal.kill";
        }
        {
          "key" = "ctrl+alt+g";
          "command" = "git-graph.view";
        }
        {
          "key" = "alt+escape";
          "command" = "workbench.action.files.setActiveEditorReadonlyInSession";
          "when" = "editorTextFocus && !editorReadonly";
        }
        {
          "key" = "alt+escape";
          "command" = "workbench.action.files.resetActiveEditorReadonlyInSession";
          "when" = "editorTextFocus && editorReadonly";
        }
      ];
      extensions = with pkgs.vscode-extensions;
      [
        sdras.night-owl
        catppuccin.catppuccin-vsc-icons
        jnoortheen.nix-ide
        mhutchie.git-graph
        aaron-bond.better-comments
        oderwat.indent-rainbow
        ms-vscode-remote.remote-ssh
      ];
    };
  };

  home.packages = with pkgs; [
    nil
    nixpkgs-fmt
  ];
}
