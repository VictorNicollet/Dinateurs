param(
    [switch]$Deploy,
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Target
)

$ErrorActionPreference = "Stop"

$RemoteUser = "root"
$RemoteRepo = "/etc/nixos"
$RemoteDeployDir = "/tmp/nixos-deploy"

Write-Host "Preparing target..."

$PrepareScript = @"
set -euo pipefail

if [ ! -f $RemoteRepo/configuration.nix ] || [ ! -f $RemoteRepo/hardware-configuration.nix ]; then
    echo "Missing $RemoteRepo/configuration.nix or $RemoteRepo/hardware-configuration.nix on target." >&2
    echo "Run nixos-generate-config on the target first, or provide target-specific base config files." >&2
    exit 1
fi

rm -rf $RemoteDeployDir
mkdir -p $RemoteDeployDir
cp $RemoteRepo/configuration.nix $RemoteDeployDir/configuration.nix
cp $RemoteRepo/hardware-configuration.nix $RemoteDeployDir/hardware-configuration.nix
"@
$PrepareScript = $PrepareScript -replace "`r`n", "`n"

ssh "${RemoteUser}@${Target}" $PrepareScript
if ($LASTEXITCODE -ne 0) {
    throw "ssh prepare failed with exit code $LASTEXITCODE."
}

Write-Host "Uploading flake..."
scp flake.nix dns.nix authorized_keys "${RemoteUser}@${Target}:${RemoteDeployDir}/"
if ($LASTEXITCODE -ne 0) {
    throw "scp failed with exit code $LASTEXITCODE."
}

$Action = if ($Deploy) { "switch" } else { "build" }

Write-Host "Running nixos-rebuild $Action on $Target..."

$RemoteScript = @"
set -euo pipefail

nixos-rebuild $Action --flake $RemoteDeployDir#target
"@
$RemoteScript = $RemoteScript -replace "`r`n", "`n"

ssh "${RemoteUser}@${Target}" $RemoteScript
if ($LASTEXITCODE -ne 0) {
    throw "ssh failed with exit code $LASTEXITCODE."
}

Write-Host "Success."
