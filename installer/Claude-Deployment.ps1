function Install-ClaudePackage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$PackagePath,
        [Parameter(Mandatory)][string]$HelperPath,
        [Parameter(Mandatory)][string]$LogPath,
        [scriptblock]$OnInstalling = {}
    )
    $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    foreach ($path in @($PackagePath, $HelperPath, $LogPath)) {
        if ($path.Contains('"')) { throw 'Invalid installation path.' }
    }
    $statusPath = $LogPath + '.status'
    $arguments = '-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "' + $HelperPath +
        '" -PackagePath "' + $PackagePath + '" -ExpectedUserSid "' + $sid + '" -LogPath "' + $LogPath + '" -StatusPath "' + $statusPath + '"'
    Write-Host 'Approve the Windows administrator prompt to install Claude for this account.'
    try {
        $process = Start-Process -FilePath "$PSHOME\powershell.exe" -ArgumentList $arguments -Verb RunAs -WindowStyle Hidden -PassThru -ErrorAction Stop
    } catch {
        throw ('Could not start elevated Claude installation. Approve the Windows administrator prompt and retry. Details: ' + $_.Exception.Message)
    }
    $announced = $false
    try {
        do {
            $exited = $process.WaitForExit(250)
            if (-not $announced -and (Test-Path -LiteralPath $statusPath)) {
                try { $state = [IO.File]::ReadAllText($statusPath) } catch [IO.IOException] { $state = '' }
                if ($state -eq 'installing') { & $OnInstalling; $announced = $true }
            }
        } while (-not $exited)
        $null = $process.WaitForExit()
        $exitCode = $process.ExitCode
        if ($exitCode -eq 0 -and -not $announced) { & $OnInstalling }
    } finally { $process.Dispose() }
    switch ($exitCode) {
        0 { return }
        10 { throw 'Claude requires elevation for the same Windows account. Different administrator credentials were supplied; no Claude registration or configuration was performed by the helper. Use an administrator-enabled account for this suite installation.' }
        11 { throw 'Claude installation did not receive administrator privileges. Approve elevation and retry.' }
        default { throw "Claude installation failed (exit $exitCode). See $LogPath" }
    }
}
