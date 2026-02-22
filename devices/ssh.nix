{ config, lib, pkgs, ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identityFile = "${config.home.homeDirectory}/.ssh/id_github";
        extraOptions = {
          StrictHostKeyChecking = "accept-new";
          LogLevel = "QUIET";
          IdentitiesOnly = "yes";
          ControlMaster = "no";
        };
      };
      "pi2" = {
        hostname = "<PI2_IP_ADDRESS>";
        user = "pi";
        identityFile = "~/.ssh/id_ed25519";
        extraOptions = {
          StrictHostKeyChecking = "accept-new";
          LogLevel = "QUIET";
          IdentitiesOnly = "yes";
          ControlMaster = "no";
        };
      };
      "het" = {
        hostname = "<VPS_IP_ADDRESS>";
        user = "yktsnet";
        identityFile = "~/.ssh/id_ed25519";
        extraOptions = {
          StrictHostKeyChecking = "no";
          LogLevel = "QUIET";
          IdentitiesOnly = "yes";
          ControlMaster = "auto";
          ControlPath = "~/.ssh/mux-%r@%h:%p";
          ControlPersist = "4h";
        };
      };
      "*" = {
        setEnv = {
          TERM = "xterm-256color";
        };
        extraOptions = {
          UserKnownHostsFile = "~/.ssh/known_hosts";
          IdentitiesOnly = "yes";
          LogLevel = "QUIET";
          ControlMaster = "no";
        };
      };
    };
  };
}
