# Initial SSH setup

If the target machine does not already have `sshd` enabled, use local console
access on the target and add the following to `/etc/nixos/configuration.nix`:

```nix
services.openssh = {
  enable = true;
  settings.PermitRootLogin = "prohibit-password";
};

users.users.root.openssh.authorizedKeys.keys = [
  "ssh-rsa AAAA..."
];
```

Replace the placeholder key with the contents of this repo's `authorized_keys`
file.

Then apply the configuration:

```bash
sudo nixos-rebuild switch
sudo systemctl status sshd
```

Once `sshd` is running, remote deployment from this repo can be used:

```powershell
.\remote-install.ps1 <host>
```

The default action only builds the configuration on the target. To activate it:

```powershell
.\remote-install.ps1 -Deploy <host>
```
