{ ... }:

{
  programs.git = {
    enable = true;
    userName = "yktsnet";
    userEmail = "<YOUR_EMAIL>";
    extraConfig = {
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      pull.rebase = true;
    };
  };
}
