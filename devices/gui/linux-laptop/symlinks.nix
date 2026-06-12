{ config, ... }:

{
  systemd.user.tmpfiles.rules = [
    "L+ %h/dotfiles/apps/ops/ops_data - - - - %h/ops_data"
    "L+ %h/dotfiles/apps/ops2/ops_data - - - - %h/ops_data"
  ];
}
