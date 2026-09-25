[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$PackagePath,
    [Parameter(Mandatory)][string]$ExpectedUserSid,
    [Parameter(Mandatory)][string]$LogPath,
    [string]$StatusPath
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$transcribing = $false
try {
    # Never register a per-user package under alternate administrator credentials.
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    if ($identity.User.Value -ne $ExpectedUserSid) { exit 10 }
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { exit 11 }
    Start-Transcript -Path $LogPath -NoClobber | Out-Null
    $transcribing = $true
    if ($StatusPath) { [IO.File]::WriteAllText($StatusPath, 'installing') }
    # Recheck after crossing the elevation boundary.
    $signature = Get-AuthenticodeSignature -LiteralPath $PackagePath
    if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch '(?i)\bAnthropic\b') {
        throw 'Claude package signature is not valid or is not from Anthropic.'
    }
    Add-AppxPackage -Path $PackagePath -ErrorAction Stop
    exit 0
} catch {
    Write-Host ($_ | Out-String)
    exit 1
} finally {
    if ($transcribing) { Stop-Transcript | Out-Null }
}
