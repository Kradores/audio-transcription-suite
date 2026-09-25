[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$PayloadDirectory,
    [Parameter(Mandatory)][string]$ServerPath,
    [Parameter(Mandatory)][string]$DatabasePath,
    [Parameter(Mandatory)][string]$LogPath
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
. (Join-Path $PSScriptRoot 'Configure-Claude.ps1')
. (Join-Path $PSScriptRoot 'Claude-Deployment.ps1')
. (Join-Path $PSScriptRoot 'Progress.ps1')
$script:currentStage = 1
$transcribing = $false
try {
    $null = New-Item -ItemType Directory -Path (Split-Path -Parent $LogPath) -Force
    Start-Transcript -Path $LogPath -NoClobber | Out-Null
    $transcribing = $true
    if (Get-Process -Name Claude -ErrorAction SilentlyContinue) {
        throw 'Quit Claude from its tray icon, then run suite setup again.'
    }
    if (-not (Test-Path -LiteralPath $ServerPath -PathType Leaf)) { throw 'MCP executable is missing.' }
    # Obtain the latest official package at install time, never a pinned release.
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $msix = Join-Path $PayloadDirectory 'Claude.msix'
    Write-Host 'Downloading the latest Claude for Windows...'
    Write-SuiteProgress 1
    Save-ClaudeDownload -Destination $msix
    Write-SuiteProgress 1 done
    $script:currentStage = 2
    Write-SuiteProgress 2
    $signature = Get-AuthenticodeSignature -LiteralPath $msix
    if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch '(?i)\bAnthropic\b') {
        throw 'Claude package signature is not valid or is not from Anthropic.'
    }
    $claudeLog = Join-Path (Split-Path -Parent $LogPath) 'claude-install.log'
    Write-SuiteProgress 2 done
    $script:currentStage = 3
    Write-SuiteProgress 3
    Install-ClaudePackage -PackagePath $msix -HelperPath (Join-Path $PSScriptRoot 'Install-ClaudeElevated.ps1') -LogPath $claudeLog -OnInstalling {
        Write-SuiteProgress 3 done
        $script:currentStage = 4
        Write-SuiteProgress 4
    }
    # Query registration in the original process/user, not in the elevated helper.
    $packages = @(Get-AppxPackage -Name Claude | Where-Object { $_.Publisher -match '(?i)\bAnthropic\b' })
    if ($packages.Count -ne 1) { throw 'Cannot determine the Claude package registered for the original Windows user.' }
    Write-SuiteProgress 4 done
    $script:currentStage = 5
    Write-SuiteProgress 5
    Write-Host 'Installing Audio Transcription Service...'
    $serviceInstaller = Join-Path $PayloadDirectory 'AudioTranscriptionService-Setup.exe'
    $serviceLog = Join-Path (Split-Path -Parent $LogPath) 'audio-service-setup.log'
    $process = Start-Process -FilePath $serviceInstaller -ArgumentList @('/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', '/SP-', ('/LOG="' + $serviceLog + '"')) -Wait -PassThru -WindowStyle Hidden
    if ($process.ExitCode -ne 0) { throw "Audio service setup failed (exit $($process.ExitCode)). See $serviceLog" }
    Write-SuiteProgress 5 done
    $script:currentStage = 6
    Write-SuiteProgress 6
    if (Get-Process -Name Claude -ErrorAction SilentlyContinue) { throw 'Close Claude and run setup again to finish configuration.' }
    $configPath = Join-Path $env:LOCALAPPDATA ('Packages\' + $packages[0].PackageFamilyName + '\LocalCache\Roaming\Claude\claude_desktop_config.json')
    # Preserve legacy settings when migrating to MSIX for the first time.
    $legacy = Join-Path $env:APPDATA 'Claude\claude_desktop_config.json'
    if (-not (Test-Path -LiteralPath $configPath) -and (Test-Path -LiteralPath $legacy)) {
        $null = New-Item -ItemType Directory -Path (Split-Path -Parent $configPath) -Force
        Copy-Item -LiteralPath $legacy -Destination $configPath
    }
    Update-ClaudeConfiguration -ConfigPath $configPath -ServerPath $ServerPath -DatabasePath $DatabasePath
    Write-SuiteProgress 6 done
    Write-Host 'All components installed. Start Audio Transcription Service to create the database, then open Claude.'
    exit 0
} catch {
    Write-SuiteProgress $script:currentStage failed
    Write-Host ('SETUP FAILED: ' + $_.Exception.Message)
    Write-Host 'Setup may be partially complete. Resolve the error and run setup again.'
    exit 1
} finally {
    if ($transcribing) { Stop-Transcript | Out-Null }
}
