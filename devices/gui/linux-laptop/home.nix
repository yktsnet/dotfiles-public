{ pkgs, ... }:

{
  imports = [
    ../home.nix
    ../../../home-manager/modules/desktop/swww-random.nix
    ./monitor.nix
  ];

  programs.foot = {
    enable = true;
    settings = {
      main = {
        allow-osc52 = "always";
      };
    };
  };

  home.packages = with pkgs; [
    (brave.override {
      commandLineArgs = [
        "--enable-features=UseOzonePlatform"
        "--ozone-platform=wayland"
        "--force-dark-mode"
        "--enable-features=WebUIDarkMode"
      ];
    })
  ];
}
