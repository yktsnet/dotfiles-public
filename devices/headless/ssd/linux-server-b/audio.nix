{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    usbutils
    alsa-utils
    wireplumber
  ];
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };
}
