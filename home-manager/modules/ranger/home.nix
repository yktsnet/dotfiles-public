{ pkgs, ... }:

let
  patched-ranger-devicons = pkgs.stdenv.mkDerivation {
    name = "ranger-devicons-patched";
    src = pkgs.fetchFromGitHub {
      owner = "alexanderjeurissen";
      repo = "ranger_devicons";
      rev = "master";
      hash = "sha256-0000000000000000000000000000000000000000000=";
    };
    installPhase = ''
      mkdir -p $out
      cp -r . $out
      sed -i "s/^[[:space:]]*'py'[[:space:]]*:[[:space:]]*'',/&\n    'astro': '',/" $out/devicons.py
      sed -i "s/^[[:space:]]*'ts'[[:space:]]*:[[:space:]]*'',/&\n    'tsx': '',/" $out/devicons.py
    '';
  };

  python-with-pillow = pkgs.python3.withPackages (ps: with ps; [
    pillow
  ]);

  custom-ranger = pkgs.symlinkJoin {
    name = "ranger";
    paths = [ pkgs.ranger ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      rm $out/bin/ranger
      makeWrapper ${pkgs.ranger}/bin/ranger $out/bin/ranger \
        --prefix PATH : "${python-with-pillow}/bin"
    '';
  };
in
{
  imports = [ ./ranger-conf.nix ];

  home.packages = with pkgs; [
    ueberzugpp
    file
    trash-cli
    sioyek
    highlight
    ripgrep
    fzf
    fd
    bat
    xclip
    visidata
    glow
  ];

  programs.ranger = {
    enable = true;
    package = custom-ranger;
  };

  xdg.configFile."ranger/plugins/devicons".source = patched-ranger-devicons;
  xdg.configFile."ranger/commands.py".text = builtins.readFile ./commands.py;
  xdg.configFile."ranger/colorschemes/poimandres.py".text = builtins.readFile ./poimandres.py;

  xdg.configFile."ranger/scope.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      FILE_PATH="$1"
      PV_WIDTH="$2"
      PV_HEIGHT="$3"
      IMAGE_CACHE_PATH="$4"
      PV_MAX_LOAD="$5"

      if [[ -z "$PV_WIDTH" ]] || [[ "$PV_WIDTH" -lt 20 ]]; then
          PV_WIDTH=80
      fi
      
      PV_WIDTH=$((PV_WIDTH - 1))

      EXTENSION="''${FILE_PATH##*.}"
      case "''${EXTENSION,,}" in
          jpg|jpeg|png|gif|bmp) exit 1 ;;
          csv|parquet) vd -b "$FILE_PATH" -o - -f text && exit 5 ;;
          json|jsonl) bat --color=always --style=plain --theme=base16 --wrap character --terminal-width="$PV_WIDTH" "$FILE_PATH" && exit 5 ;;
          md|astro) CLICOLOR_FORCE=1 glow -s dark -w "$PV_WIDTH" "$FILE_PATH" && exit 5 ;;
          *)
              MIME_TYPE=$(file --brief --mime-type "$FILE_PATH")
              if [[ "$MIME_TYPE" == text/* || "$MIME_TYPE" == "application/json" || "$MIME_TYPE" == "application/javascript" ]]; then
                  bat --color=always --style=plain --theme=base16 --wrap character --terminal-width="$PV_WIDTH" "$FILE_PATH" && exit 5
              fi
              ;;
      esac
      exit 1
    '';
  };
}
