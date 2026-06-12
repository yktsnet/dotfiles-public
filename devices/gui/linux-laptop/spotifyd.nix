{
  services.spotifyd = {
    enable = true;
    customSettings = {
      device_name = "linux-laptop";
      backend = "pulseaudio";
    };
  };
}
