{ pkgs, config, ... }:

{
  home.packages = [
    pkgs.nightfox-gtk-theme
    pkgs.posy-cursors
  ];

  home.pointerCursor = {
    package = pkgs.posy-cursors;
    name = "Posy_Cursor_Black";
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  gtk = {
    enable = true;
    theme = {
      name = "Carbonfox";
      package = pkgs.nightfox-gtk-theme;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    font = {
      name = "Noto Sans CJK JP";
      size = 11;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
    gtk3.extraCss = ''
      @define-color selected_bg_color #1d3b53;
      @define-color selected_fg_color #ffffff;
    '';
  };
  dconf.enable = true;
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };

  xdg.configFile."gtk-4.0/assets".source = "${pkgs.nightfox-gtk-theme}/share/themes/Carbonfox/gtk-4.0/assets";
  xdg.configFile."gtk-4.0/gtk.css".text = ''
    @import url("${pkgs.nightfox-gtk-theme}/share/themes/Carbonfox/gtk-4.0/gtk.css");
    @define-color selected_bg_color #1d3b53;
    @define-color selected_fg_color #ffffff;
  '';
  xdg.configFile."gtk-4.0/gtk-dark.css".text = ''
    @import url("${pkgs.nightfox-gtk-theme}/share/themes/Carbonfox/gtk-4.0/gtk-dark.css");
    @define-color selected_bg_color #1d3b53;
    @define-color selected_fg_color #ffffff;
  '';

  qt = {
    enable = true;
    platformTheme.name = "gtk";
    style.name = "adwaita-dark";
  };
}
