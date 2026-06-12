{
  disko.devices = {
    disk = {
      main = {
        device = "/dev/nvme0n1";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                subvolumes = {
                  "/root" = {
                    mountpoint = "/";
                    mountOptions = [ "ssd" "discard=async" "space_cache=v2" ];
                  };
                  "/home" = {
                    mountpoint = "/home";
                    mountOptions = [ "ssd" "discard=async" "space_cache=v2" ];
                  };
                  "/nix" = {
                    mountpoint = "/nix";
                    mountOptions = [ "noatime" "ssd" "discard=async" "space_cache=v2" ];
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
