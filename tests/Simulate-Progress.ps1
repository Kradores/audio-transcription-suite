param([switch]$Fail)
. (Join-Path $PSScriptRoot 'Progress.ps1')
foreach ($stage in 1..6) {
    Write-SuiteProgress $stage
    if ($stage -eq 1) {
        foreach ($received in 0..8) {
            Write-SuiteProgress 1 active ($received * 1048576) 8388608
            Start-Sleep -Milliseconds 300
        }
    } else { Start-Sleep -Milliseconds 800 }
    if ($Fail -and $stage -eq 4) { Write-SuiteProgress 4 failed; exit 1 }
    Write-SuiteProgress $stage done
}
exit 0
