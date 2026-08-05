{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ../home.nix
    ../../../home-manager/modules/ctx.nix
  ];

  home.packages = [
    inputs.claude-history.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
