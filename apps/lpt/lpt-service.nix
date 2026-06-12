{ config
, pkgs
, lib
, ...
}:

let
  cfg = config.yktsnet.apps.lpt;
  envCtx = import ../env-context.nix { inherit pkgs; };
  pythonEnv = pkgs.python3.withPackages envCtx.pythonPackages;
  pythonBin = "${pythonEnv}/bin/python3";
  homeDir = config.users.users.yktsnet.home;
  appsDir = "${homeDir}/dotfiles/apps/lpt";
  opsDataRoot = "${homeDir}/ops_data";
  commonEnv = envCtx.commonEnv homeDir appsDir opsDataRoot;
in
{
  options.yktsnet.apps.lpt = {
    enable = lib.mkEnableOption "LPT Service Base";
    envTxtMaker = lib.mkEnableOption "Env Text Maker Timer";
    resultHarvest = lib.mkEnableOption "Result Harvest Timer";
    dailyBackup = lib.mkEnableOption "Daily Backup Timer (14 days retention)";
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.yktsnet.home.packages = [ pkgs.restic ];

    systemd.user.services = {


      lpt-daily-backup = lib.mkIf (cfg.enable && cfg.dailyBackup) {
        description = "LPT Daily Backup Service (Internal SSD Buffer)";
        path = [ pkgs.restic ];
        serviceConfig = {
          Type = "oneshot";
          Environment = [
            "RESTIC_REPOSITORY=/home/yktsnet/.local/share/restic-buffer"
            "RESTIC_PASSWORD_FILE=/run/secrets/common/restic_password"
            "BACKUP_TARGETS=/home/yktsnet/ops_data,/home/yktsnet/dotfiles"
          ];
          ExecStart = "${pythonBin} ${appsDir}/core/backup_manager.py --internal";
        };
      };

      lpt-env-txt-maker = lib.mkIf (cfg.enable && cfg.envTxtMaker) {
        description = "LPT Env Txt Maker Service";
        serviceConfig = {
          Type = "oneshot";
          Environment = commonEnv;
          ExecStart = "${pythonBin} ${appsDir}/core/env_txt_maker.py --config ${appsDir}/env/env.txt_maker.nix";
        };
      };

      lpt-result-harvest = lib.mkIf (cfg.enable && cfg.resultHarvest) {
        description = "LPT Result Harvest Service (Pull from linux-server-a)";
        path = [ pkgs.rsync pkgs.openssh ];
        serviceConfig = {
          Type = "oneshot";
          Environment = commonEnv;
          ExecStart = "${pythonBin} ${appsDir}/core/result_harvest.py";
        };
      };


    };

    systemd.user.timers = {


      lpt-env-txt-maker = lib.mkIf (cfg.enable && cfg.envTxtMaker) {
        description = "Run Env Txt Maker every 20 seconds";
        timerConfig = {
          OnBootSec = "10sec";
          OnCalendar = "*:*:0/20";
          AccuracySec = "1sec";
          Persistent = true;
        };
        wantedBy = [ "default.target" ];
      };

      lpt-result-harvest = lib.mkIf (cfg.enable && cfg.resultHarvest) {
        description = "Timer for Result Harvest every 1 minute";
        timerConfig = {
          OnBootSec = "1min";
          OnUnitInactiveSec = "1min";
          AccuracySec = "1sec";
        };
        wantedBy = [ "timers.target" ];
      };

      lpt-daily-backup = lib.mkIf (cfg.enable && cfg.dailyBackup) {
        description = "Timer for 2x Daily Backup (02:00, 14:00 UTC)";
        timerConfig = {
          OnCalendar = "*-*-* 02,14:00:00";
          Persistent = true;
          AccuracySec = "1sec";
        };
        wantedBy = [ "timers.target" ];
      };


    };
  };
}
