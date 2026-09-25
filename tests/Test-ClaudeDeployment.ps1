$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot '..\installer\Claude-Deployment.ps1')
function Assert($Condition, [string]$Message) { if (-not $Condition) { throw $Message } }
$script:exitCode = 0
$script:cancel = $false
$script:statusTest = $false
function Start-Process {
    param($FilePath, $ArgumentList, $Verb, $WindowStyle, [switch]$Wait, [switch]$PassThru, $ErrorAction)
    Assert ($Verb -eq 'RunAs') 'Missing elevation request'
    Assert ((-not $Wait) -and $PassThru) 'Must poll the helper for live status'
    Assert ($WindowStyle -eq 'Hidden') 'Helper should run hidden'
    Assert ($ArgumentList.Contains('-ExpectedUserSid "' + [Security.Principal.WindowsIdentity]::GetCurrent().User.Value + '"')) 'Missing original user identity'
    Assert ($ArgumentList.Contains('-PackagePath "C:\Test User\Claude.msix"')) 'Package path is not quoted'
    if ($script:cancel) { throw 'The operation was canceled by the user' }
    $mock = [pscustomobject]@{ ExitCode = $script:exitCode }
    $mock | Add-Member ScriptMethod WaitForExit {
        param($timeout)
        if ($script:statusTest -and $null -ne $timeout) {
            $script:pollCount++
            [IO.File]::WriteAllText($script:testStatusPath, 'installing')
            return ($script:pollCount -gt 1)
        }
        return $true
    }
    $mock | Add-Member ScriptMethod Dispose {}
    $mock
}
$parameters = @{
    PackagePath = 'C:\Test User\Claude.msix'
    HelperPath = 'C:\Test User\Install-ClaudeElevated.ps1'
    LogPath = 'C:\Test User\claude-install.log'
}
Install-ClaudePackage @parameters
$script:announced = $false
Install-ClaudePackage @parameters -OnInstalling { $script:announced = $true }
Assert $script:announced 'Successful fast helper must announce installation'
$script:testStatusPath = Join-Path $PSScriptRoot ('helper-' + [guid]::NewGuid().ToString('N') + '.status')
$script:statusTest = $true
$script:pollCount = 0
$script:announcedWhileRunning = $false
try {
    Install-ClaudePackage -PackagePath $parameters.PackagePath -HelperPath $parameters.HelperPath -LogPath ($script:testStatusPath -replace '\.status$', '') -OnInstalling { $script:announcedWhileRunning = $script:pollCount -eq 1 }
    Assert $script:announcedWhileRunning 'Installation stage not relayed while helper was running'
} finally {
    $script:statusTest = $false
    if (Test-Path -LiteralPath $script:testStatusPath) { Remove-Item -LiteralPath $script:testStatusPath }
}
foreach ($scenario in @(
    @{ Code = 10; Text = 'Different administrator credentials' },
    @{ Code = 11; Text = 'did not receive administrator privileges' },
    @{ Code = 1; Text = 'Claude installation failed' }
)) {
    $script:exitCode = $scenario.Code
    $message = ''
    try { Install-ClaudePackage @parameters } catch { $message = $_.Exception.Message }
    Assert ($message.Contains($scenario.Text)) ('Incorrect failure handling: ' + $scenario.Code)
}
$script:cancel = $true
$message = ''
try { Install-ClaudePackage @parameters } catch { $message = $_.Exception.Message }
Assert ($message.Contains('Approve the Windows administrator prompt')) 'UAC cancellation is not explained'
# Exercise the actual helper's identity guard without elevation or package installation.
$helper = Join-Path $PSScriptRoot '..\installer\Install-ClaudeElevated.ps1'
& "$PSHOME\powershell.exe" -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $helper -PackagePath 'C:\missing.msix' -ExpectedUserSid 'S-1-0-0' -LogPath 'C:\must-not-create.log'
Assert ($LASTEXITCODE -eq 10) 'Alternate identity was not rejected before side effects'
Write-Host 'PASS: elevation request, quoted paths, user identity guard, cancellation, success and deployment failures.'
