{ config, ... }: {

  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "cheesecake";
  networking.domain = "opcc.tk";

  security.sudo.wheelNeedsPassword = false;

  users.users = import ./users.nix;

  services.openssh.enable = true;
  services.openssh.openFirewall = false;

  environment.etc."ssh/ca.pub".text = ''
    ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBN6wnMAe+DI5VQXfqlII/fAYCI0AMTz7T9CrH0QM14199qbsKMm1nmHe+ai/PPjK4d2OT0p3fC+rEXPy5gIFL3w= open-ssh-ca@cloudflareaccess.org
  '';

  services.openssh.extraConfig = ''
    TrustedUserCAKeys /etc/ssh/ca.pub
  '';

  services.upnpc.enable = true;

  time.timeZone = "America/Toronto";

  boot.loader.systemd-boot.enable = true;

  boot.enableContainers = true;

  networking.nat.enable = true;
  networking.nat.externalInterface = "enp2s0f1";
  networking.nat.internalInterfaces = [ "wg0" ];

  networking.firewall.allowedUDPPorts = [ 25565 ];
  networking.firewall.interfaces."wg0".allowedTCPPorts = [ 22 ];

  age.secrets.wg.file = ../../secrets/wg.age;

  networking.wireguard.interfaces.wg0 = {
    ips = [ "10.100.0.1/24" ];
    listenPort = 25565;
    privateKeyFile = config.age.secrets.wg.path;
    peers = import ./wg-peers.nix;
  };

  virtualisation.podman.enable = true;
  virtualisation.podman.dockerCompat = true;

  programs.bash.promptInit = ''
    PS1="\n\[\033[1;32m\]\u@\h:\w\[\033[36m\]\$\[\033[0m\] "
  '';

  age.secrets.cloudflared = {
    file = ../../secrets/06cafcb6-9210-469b-bfff-42397ef69ce3.json.age;
    owner = "cloudflared";
  };

  services.cloudflared.enable = true;
  services.cloudflared.tunnels = {
    "06cafcb6-9210-469b-bfff-42397ef69ce3" = {
      credentialsFile = config.age.secrets.cloudflared.path;
      default = "http_status:404";
      ingress = {
        "cheesecake.opcc.tk" = {
          service = "ssh://localhost:22";
        };
      };
    };
  };

  services.openssh.settings.Macs = [
    "hmac-sha2-512"
  ];

  system.stateVersion = "24.05";

}
