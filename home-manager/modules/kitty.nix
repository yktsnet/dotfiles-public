{ pkgs, ... }:

{
  programs.kitty = {
    enable = true;
    font = {
      name = "Fira Code";
      size = 12;
    };
    settings = {
      clipboard_control = "write-clipboard write-primary read-clipboard read-primary";
      allow_remote_control = "yes";
    };
    extraConfig = builtins.readFile ./kitty/kitty.conf;
  };
}
