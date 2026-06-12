{ pkgs, ... }:

{
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    udev-gothic
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
  ];

  xdg.configFile."fontconfig/conf.d/99-brave-comic.conf".text = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
    <fontconfig>
      <match target="pattern">
        <test name="prgname" compare="eq">
          <string>brave</string>
        </test>
        <test name="family">
          <string>monospace</string>
        </test>
        <edit name="family" mode="prepend" binding="strong">
          <string>Comic Mono</string>
        </edit>
      </match>
    </fontconfig>
  '';
}