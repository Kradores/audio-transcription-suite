$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\installer\Progress.ps1')
function Assert($Condition, $Message) { if (-not $Condition) { throw $Message } }
$original = [Console]::Out
$capture = New-Object IO.StringWriter
try {
    [Console]::SetOut($capture)
    foreach ($total in @(4, -1)) {
        $inputStream = [IO.MemoryStream]::new([byte[]](1,2,3,4))
        $outputStream = [IO.MemoryStream]::new()
        try {
            Copy-DownloadStream $inputStream $outputStream $total
            Assert ($outputStream.Length -eq 4) 'Download stream lost bytes'
        } finally { $inputStream.Dispose(); $outputStream.Dispose() }
    }
    $inputStream = [IO.MemoryStream]::new([byte[]](1,2))
    $outputStream = [IO.MemoryStream]::new()
    $failed = $false
    try { Copy-DownloadStream $inputStream $outputStream 4 } catch { $failed = $true }
    finally { $inputStream.Dispose(); $outputStream.Dispose() }
    Assert $failed 'Truncated download accepted'
    Assert ($capture.ToString().Contains('ATS_PROGRESS|1|active|4|4')) 'Known-size event missing'
    Assert ($capture.ToString().Contains('ATS_PROGRESS|1|active|4|-1')) 'Unknown-size event missing'
} finally { [Console]::SetOut($original); $capture.Dispose() }
Write-Host 'PASS: streaming bytes, known/unknown size, premature EOF, and progress events.'
$destination = Join-Path $PSScriptRoot ('partial-' + [guid]::NewGuid().ToString('N') + '.tmp')
function Open-ClaudeDownloadResponse {
    $fake = [pscustomobject]@{ ResponseUri = [uri]'https://example.test/Claude.msix'; ContentLength = 20 }
    $fake | Add-Member ScriptMethod GetResponseStream { return [IO.MemoryStream]::new([byte[]](1,2)) }
    $fake | Add-Member ScriptMethod Dispose {}
    return $fake
}
try {
    $failed = $false
    try { Save-ClaudeDownload $destination } catch { $failed = $true }
    Assert $failed 'Interrupted download accepted'
    Assert (-not (Test-Path -LiteralPath $destination)) 'Partial download was not removed'
} finally { if (Test-Path -LiteralPath $destination) { Remove-Item -LiteralPath $destination } }
Write-Host 'PASS: interrupted download removes partial file.'
