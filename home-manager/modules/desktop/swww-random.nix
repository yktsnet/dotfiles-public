{ pkgs, ... }:

let
  scriptBody = ''
    export PATH=${pkgs.swww}/bin:${pkgs.coreutils}/bin:${pkgs.findutils}/bin:$PATH
    
    if [ "$1" = "anime" ]; then
        BASE_DIR="$HOME/Downloads/wallpapers/anime"
    else
        BASE_DIR="$HOME/Downloads/wallpapers"
    fi

    # デーモンが起動していなければ起動し、少し待機
    if ! swww query > /dev/null 2>&1; then
        swww-daemon &
        sleep 0.5
    fi

    SELECTED=$(find "$BASE_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) | shuf -n 1)

    if [ -n "$SELECTED" ]; then
        # transition-type を step から simple へ修正
        swww img "$SELECTED" --transition-type simple --resize crop
    fi
  '';

  swww-random-bin = pkgs.writeShellScriptBin "swww-random" scriptBody;
in
{
  home.packages = [ pkgs.swww swww-random-bin ];
}