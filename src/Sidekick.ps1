# Helper script for those who want to run Sidekick without importing the module.
# Example run from PowerShell:
# .\sidekick.ps1 "task" "server" "database" "destination"

# Must match parameter definitions for sidekick.psm1/invoke-sidekick
# otherwise named parameter binding fails
[cmdletbinding()]
param(
    [Parameter(Position = 0, Mandatory = $true)]
    [string]$task,

    [Parameter(Position = 1, Mandatory = $true)]
    [string]$server,

    [Parameter(Position = 2, Mandatory = $true)]
    [string]$database,

    [Parameter(Position = 3, Mandatory = $false)]
    [string]$destination
)

# setting $scriptPath here, not as default argument, to support calling as "powershell -File sidekick.ps1"
if (-not $scriptPath) {
    $scriptPath = $(Split-Path -Path $MyInvocation.MyCommand.path -Parent)
}

Import-Module -Name (Join-Path -Path $scriptPath -ChildPath 'sidekick.psd1') -Verbose:$false
if ($help) {
    Get-Help -Name Invoke-sidekick -Full
    return
}

if ($buildFile -and (-not (Test-Path -Path $buildFile))) {
    $absoluteBuildFile = (Join-Path -Path $scriptPath -ChildPath $buildFile)
    if (Test-path -Path $absoluteBuildFile) {
        $buildFile = $absoluteBuildFile
    }
}

Invoke-sidekick $task $server $database $destination

if (!$sidekick.build_success) {
    exit 1
}