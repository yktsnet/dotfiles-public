{ pkgs, ... }:

{
  programs.firefox = {
    enable = true;
    profiles.yktsnet = {

      search = {
        default = "ddg";
        force = true;
        engines = {
          "SearXNG" = {
            urls = [{
              template = "https://searx.be/search";
              params = [
                { name = "q"; value = "{searchTerms}"; }
                { name = "language"; value = "ja-JP"; }
              ];
            }];
            icon = "https://searx.be/static/themes/simple/img/favicon.png";
            definedAliases = [ "@s" ];
          };
          "google".metaData.hidden = true;
          "amazon-jp".metaData.hidden = true;
          "bing".metaData.hidden = true;
          "ebay".metaData.hidden = true;
          "ddg" = {
            urls = [{ template = "https://duckduckgo.com/?q={searchTerms}"; }];
            icon = "https://duckduckgo.com/favicon.ico";
            definedAliases = [ "@d" ];
          };
        };
      };

      settings = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "ui.key.menuAccessKeyFocuses" = false;
        "browser.tabs.drawInTitlebar" = true;
        "browser.toolbars.bookmarks.visibility" = "newtab";
        "font.name.sans-serif.ja" = "Noto Sans CJK JP";
        "font.name.monospace.ja" = "Noto Sans CJK JP";
        "layout.spellcheckDefault" = 0;
        "browser.startup.page" = 3;
        "browser.newtabpage.enabled" = false;
        "signon.rememberSignons" = false;
        "media.videocontrols.picture-in-picture.enabled" = true;
        "browser.search.suggest.enabled" = true;
        "extensions.activeThemeID" = "firefox-compact-dark@mozilla.org";
        "browser.tabs.warnOnClose" = true;
        "browser.sanitize.sanitizeOnShutdown" = false;
        "privacy.sanitize.sanitizeOnShutdown" = false;
        "privacy.clearOnShutdown.history" = false;
        "privacy.clearOnShutdown.formdata" = false;
        "privacy.clearOnShutdown.downloads" = false;
        "privacy.clearOnShutdown.cookies" = false;
        "privacy.clearOnShutdown.sessions" = false;
        "privacy.clearOnShutdown.offlineApps" = false;
        "network.cookie.lifetimePolicy" = 0;
        "browser.download.dir" = "/home/yktsnet/Downloads";
        "ui.use_gtk_cursors" = true;
        "ui.highlight" = "#1d3b53";
        "ui.highlighttext" = "#ffffff";
        "widget.non-native-theme.use-theme-accent" = true;
        "widget.content.allow-gtk-dark-theme" = true;
      };

      userChrome = ''
        :root {
          --night-owl-bg: #011627;
          --night-owl-fg: #d6deeb;
          --night-owl-accent: #82aaff;
          --night-owl-border: #1d3b53;
          --tab-min-height: 32px !important;
        }

        * {
          font-family: "Comic Mono", "Noto Sans CJK JP" !important;
          font-size: 12px !important;
          font-weight: 400 !important;
        }

        #nav-bar, #TabsToolbar, #PersonalToolbar {
          background-color: var(--night-owl-bg) !important;
          border-color: var(--night-owl-border) !important;
        }

        .tab-background[selected="true"] {
          background-color: var(--night-owl-border) !important;
          border-bottom: 2px solid var(--night-owl-accent) !important;
        }

        #urlbar-background {
          background-color: #01121f !important;
          border: 1px solid var(--night-owl-border) !important;
        }

        .tabbrowser-tab {
          min-height: var(--tab-min-height) !important;
        }

        #urlbar-input-container {
          padding-block: 2px !important;
        }

        #tabs-newtab-button,
        #TabsToolbar .titlebar-buttonbox-container,
        #alltabs-button,
        .urlbar-history-dropmarker,
        #urlbar-search-button,
        .tab-close-button {
          display: none !important;
        }

        #PersonalToolbar {
          padding: 0 !important;
          margin: 0 !important;
        }
      '';

      extraConfig = ''
        user_pref("extensions.ublock-origin.adminSettings", "{\"userSettings\":{\"advancedSettingsAllowed\":true,\"externalLists\":\"https://raw.githubusercontent.com/pixeltris/TwitchAdSolutions/master/video-swap-new/video-swap-new-ublock-origin.js\"}}");
      '';
    };
  };
}
