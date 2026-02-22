{ lib, osConfig, config, ... }:

let
  host = osConfig.networking.hostName;
  hostColor =
    if host == "t14" then "#c792ea"
    else if host == "het" then "#5de4c7"
    else if host == "pi2" then "#addb67"
    else "DYNAMIC";
in
{
  programs.zsh = {
    enable = true;
    dotDir = lib.mkForce "${config.home.homeDirectory}/.config/zsh";
    initContent = ''
      unset __HM_ZSH_S_SOURCED

      local final_host_color
      if [[ "${hostColor}" != "DYNAMIC" ]]; then
        final_host_color="${hostColor}"
      elif [[ -n "$HOST_COLOR" ]]; then
        final_host_color="$HOST_COLOR"
      else
        local colors=("#82aaff" "#7fdbca" "#c792ea" "#ffeb95" "#f78c6c" "#addb67")
        final_host_color="$\{colors[$((RANDOM % $\{#colors[@]\} + 1))] \}"
      fi

      autoload -U promptinit
      promptinit
      zstyle :prompt:pure:path color "#d6deeb"
      zstyle :prompt:pure:prompt:success color "$final_host_color"
      
      prompt pure
      
      PROMPT="%F{$final_host_color}%B${host}%b%f $PROMPT"
    '';
  };
}
