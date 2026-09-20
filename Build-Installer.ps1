[CmdletBinding()]
param(
    [ValidateSet('Nvidia', 'Amd')][string]$Gpu = 'Nvidia',
    [string]$Compiler = $env:INNO_SETUP_COMPILER
)
$ErrorActionPreference = 'Stop'
if (-not $Compiler) {
    $candidates = @(
        "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe",
        "$env:LOCALAPPDATA\Programs\Inno Setup 7\ISCC.exe",
        "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
        "${env:ProgramFiles(x86)}\Inno Setup 7\ISCC.exe"
    )
    $Compiler = $candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
}
if (-not $Compiler) { throw 'Install Inno Setup or pass -Compiler with the path to ISCC.exe.' }
$serviceInstaller = "AudioTranscriptionService-$Gpu-Setup-0.1.0.exe"
foreach ($name in @($serviceInstaller, 'CoreMcp.Server.exe')) {
    if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot $name))) { throw "Missing payload: $name" }
}
& $Compiler "/DSuiteRoot=$PSScriptRoot" "/DGpu=$Gpu" (Join-Path $PSScriptRoot 'installer\AudioTranscriptionSuite.iss')
if ($LASTEXITCODE -ne 0) { throw "Installer compilation failed: $LASTEXITCODE" }
Get-FileHash -LiteralPath (Join-Path $PSScriptRoot "dist\AudioTranscriptionSuite-$Gpu-Setup-0.1.0.exe") -Algorithm SHA256
