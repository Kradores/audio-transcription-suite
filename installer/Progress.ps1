# ATS_PROGRESS|stage(1..6)|active/done/failed|bytes|total(-1=unknown)
function Write-SuiteProgress {
    param([ValidateRange(1,6)][int]$Stage, [ValidateSet('active','done','failed')][string]$State = 'active', [long]$Bytes = 0, [long]$Total = -1)
    [Console]::Out.WriteLine("ATS_PROGRESS|$Stage|$State|$Bytes|$Total")
    [Console]::Out.Flush()
}
function Copy-DownloadStream {
    param([IO.Stream]$InputStream, [IO.Stream]$OutputStream, [long]$Total = -1)
    $buffer = New-Object byte[] 65536
    $received = 0L
    $clock = [Diagnostics.Stopwatch]::StartNew()
    Write-SuiteProgress 1 active 0 $Total
    while (($count = $InputStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
        $OutputStream.Write($buffer, 0, $count)
        $received += $count
        if ($clock.ElapsedMilliseconds -ge 250) {
            Write-SuiteProgress 1 active $received $Total
            $clock.Restart()
        }
    }
    if ($Total -ge 0 -and $received -ne $Total) { throw 'Claude download was incomplete. Retry setup.' }
    Write-SuiteProgress 1 active $received $Total
}
function Open-ClaudeDownloadResponse {
    $uri = [uri]'https://claude.ai/api/desktop/win32/x64/msix/latest/redirect'
    for ($redirect = 0; $redirect -lt 10; $redirect++) {
        if ($uri.Scheme -ne 'https') { throw 'Claude download requires HTTPS.' }
        $request = [Net.HttpWebRequest]::Create($uri)
        $request.AllowAutoRedirect = $false
        $request.Timeout = 60000
        $request.ReadWriteTimeout = 60000
        $response = $request.GetResponse()
        if ([int]$response.StatusCode -in @(301,302,303,307,308)) {
            try {
                $location = $response.Headers['Location']
                if (-not $location) { throw 'Claude download redirect has no destination.' }
                $uri = [uri]::new($uri, $location)
            } finally { $response.Dispose() }
        } else { return $response }
    }
    throw 'Claude download exceeded the redirect limit.'
}
function Save-ClaudeDownload {
    param([string]$Destination)
    $response = $null
    $inputStream = $null
    $outputStream = $null
    $complete = $false
    try {
        $response = Open-ClaudeDownloadResponse
        if ($response.ResponseUri.Scheme -ne 'https') { throw 'Claude download did not resolve to HTTPS.' }
        $inputStream = $response.GetResponseStream()
        $outputStream = [IO.File]::Create($Destination)
        Copy-DownloadStream $inputStream $outputStream $response.ContentLength
        $complete = $true
    } finally {
        if ($null -ne $outputStream) { $outputStream.Dispose() }
        if ($null -ne $inputStream) { $inputStream.Dispose() }
        if ($null -ne $response) { $response.Dispose() }
        if (-not $complete -and (Test-Path -LiteralPath $Destination)) { Remove-Item -LiteralPath $Destination -Force }
    }
}
