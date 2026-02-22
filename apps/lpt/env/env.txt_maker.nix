{
  dotfiles = [ "home-manager" "devices" "zsh" ];
  "dotfiles/apps" = [ "lpt" "trading_engine" "notification_service" "data_pipeline" "zsh" ];
  "projects/web_app" = {
    exclude = [ "node_modules" ".astro" "dist" "package-lock.json" ];
  };
}
