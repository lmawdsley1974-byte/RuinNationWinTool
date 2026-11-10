param(
    [switch]$Terminal
)

$ErrorActionPreference = 'Stop'

if ($Terminal) {
    if ([string]::IsNullOrWhiteSpace($PSScriptRoot)) {
        throw 'The terminal interface requires the local Ruin Nation script folder.'
    }

    $terminalScript = Join-Path $PSScriptRoot 'RuinNation-Terminal.ps1'
    if (-not (Test-Path -LiteralPath $terminalScript -PathType Leaf)) {
        throw "The optional terminal interface was not found at '$terminalScript'."
    }

    & $terminalScript
    return
}

$appExecutable = 'RuinNationStore.exe'
$candidatePaths = @()

if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
    $candidatePaths += Join-Path $PSScriptRoot $appExecutable
    $candidatePaths += Join-Path $PSScriptRoot "bin\Debug\net10.0-windows\$appExecutable"
    $candidatePaths += Join-Path $PSScriptRoot "bin\Release\net10.0-windows\$appExecutable"
    $candidatePaths += Join-Path $PSScriptRoot "publish\RuinNationWinTool\$appExecutable"
}

$candidatePaths += Join-Path $env:LOCALAPPDATA "Programs\RuinNationWinTool\$appExecutable"

$resolvedExecutable = $candidatePaths |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and (Test-Path -LiteralPath $_ -PathType Leaf) } |
    Select-Object -First 1

if (-not $resolvedExecutable) {
    $installPath = Join-Path $env:LOCALAPPDATA "Programs\RuinNationWinTool\$appExecutable"
    throw "Ruin Nation is not installed. Install it first, or run this script from the app's published folder. Expected install location: '$installPath'."
}

try {
    Start-Process -FilePath $resolvedExecutable -WorkingDirectory (Split-Path -Parent $resolvedExecutable)
}
catch {
    throw "Could not open Ruin Nation: $($_.Exception.Message)"
}
