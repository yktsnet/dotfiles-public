{ ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user.name = "yktsnet";
      user.email = "<YOUR_EMAIL>";
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      pull.rebase = true;
    };
  };
}
