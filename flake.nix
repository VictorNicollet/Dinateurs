{
  description = "NixOS configuration";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { nixpkgs, ... }:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations.target = nixpkgs.lib.nixosSystem {
        inherit system;

        modules = [
          ./configuration.nix
          ({ pkgs, ... }: {
            networking.networkmanager.enable = true;

            services.xserver.enable = true;
            services.xserver.displayManager.gdm.enable = true;
            services.xserver.desktopManager.gnome.enable = true;

            services.gnome.gnome-keyring.enable = true;
            security.pam.services.login.enableGnomeKeyring = true;

            environment.systemPackages = with pkgs; [
              bind.dnsutils
              git
              iproute2
              nettools
              seahorse
            ];

            services.unbound = {
              enable = true;
              settings.server = {
                interface = [
                  "127.0.0.1"
                  "::1"
                ];
                access-control = [
                  "127.0.0.0/8 allow"
                  "::1 allow"
                ];
              };
            };

            networking.nameservers = [
              "127.0.0.1"
              "::1"
            ];

            services.openssh = {
              enable = true;
              settings = {
                PasswordAuthentication = false;
                PermitRootLogin = "prohibit-password";
              };
            };

            users.users.root.openssh.authorizedKeys.keyFiles = [
              ./authorized_keys
            ];

            system.stateVersion = "25.11";
          })
        ];
      };
    };
}
