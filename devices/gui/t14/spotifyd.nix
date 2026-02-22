{
  services.spotifyd = {
    enable = true;
    customSettings = {
      device_name = "t14";
      backend = "pulseaudio";
    };
  };
}
