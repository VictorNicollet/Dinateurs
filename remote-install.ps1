param(
    [switch]$Deploy,
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Host
)

$ErrorActionPreference = "Stop"

$RemoteUser = "root"
$RemoteRepo = "/etc/nixos"
$PatchFile = "$env:TEMP\nixos-local.patch"

try {
    Write-Host "Creating patch..."
    git diff --binary HEAD > $PatchFile

    Write-Host "Uploading patch..."
    scp $PatchFile "${RemoteUser}@${Host}:/tmp/nixos-local.patch"

    $Action = if ($Deploy) { "switch" } else { "test" }

    Write-Host "Running nixos-rebuild $Action on $Host..."

    $RemoteScript = @"
set -euo pipefail

cd $RemoteRepo

git reset --hard HEAD
git clean -fd

git apply /tmp/nixos-local.patch

nixos-rebuild $Action --flake .#$(hostname)
"@

    ssh "${RemoteUser}@${Host}" $RemoteScript

    Write-Host "Success."
}
finally {
    Remove-Item $PatchFile -ErrorAction SilentlyContinue
}