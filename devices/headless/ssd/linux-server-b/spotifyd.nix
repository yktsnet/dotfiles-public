{
  services.spotifyd = {
    settings = {
      global = {
        device_name = "linux-server-b";
        backend = "pulseaudio";
      };
    };
  };
}
