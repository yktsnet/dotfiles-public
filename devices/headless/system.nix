{ pkgs, inputs, lib, config, ... }:

{
  imports = [
    inputs.sops-nix.nixosModules.sops
    ../../zsh/init.nix
  ];

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    trusted-users = [ "root" "yktsnet" ];
  };

  time.timeZone = "Etc/UTC";
  i18n.defaultLocale = "en_US.UTF-8";

  networking.networkmanager.enable = true;
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
    trustedInterfaces = [ "tailscale0" ];
  };

  services.tailscale.enable = true;

  users.users.yktsnet = {
    isNormalUser = true;
    description = "yktsnet";
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    uid = 1000;
    hashedPassword = "*";
    linger = true;
  };

  users.defaultUserShell = pkgs.zsh;
  users.mutableUsers = true;
  security.sudo.wheelNeedsPassword = false;

  services.getty.autologinUser = "yktsnet";

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    curl
    python3
    rsync
    htop
    btop
    tree
    tailscale
    tmux
    kitty
    helix
  ];

  environment.variables = {
    COLORTERM = "truecolor";
    EDITOR = "hx";
  };

  console = {
    enable = true;
    earlySetup = true;
    font = "${pkgs.terminus_font}/share/consolefonts/ter-v16n.psf.gz";
    packages = with pkgs; [ terminus_font ];
    keyMap = "us";
  };

  sops = {
    validateSopsFiles = false;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs; osConfig = config; };
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    sharedModules = [ inputs.sops-nix.homeManagerModules.sops ];
  };

  system.stateVersion = "24.11";
}
