Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Update-ClaudeConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ConfigPath,
        [Parameter(Mandatory)][string]$ServerPath,
        [Parameter(Mandatory)][string]$DatabasePath
    )
    foreach ($path in @($ServerPath, $DatabasePath)) {
        if (-not [IO.Path]::IsPathRooted($path) -or $path.Contains('"')) {
            throw "An absolute Windows path without double quotes is required: $path"
        }
    }
    $exists = Test-Path -LiteralPath $ConfigPath
    $original = $null
    if ($exists) {
        $original = [IO.File]::ReadAllText($ConfigPath)
        $config = ConvertFrom-Json -InputObject $original -ErrorAction Stop
        if ($null -eq $config -or $config -isnot [pscustomobject]) {
            throw 'Claude configuration must contain a JSON object. Existing file was not changed.'
        }
    } else { $config = [pscustomobject]@{} }
    if (-not $config.PSObject.Properties['mcpServers']) {
        $config | Add-Member NoteProperty mcpServers ([pscustomobject]@{})
    }
    if ($config.mcpServers -isnot [pscustomobject]) {
        throw 'mcpServers must be a JSON object. Existing file was not changed.'
    }
    $server = [pscustomobject]@{}
    if ($config.mcpServers.PSObject.Properties['coremcp']) {
        if ($config.mcpServers.coremcp -isnot [pscustomobject]) { throw 'coremcp must be a JSON object.' }
        $server = $config.mcpServers.coremcp
    }
    if (-not $server.PSObject.Properties['env']) {
        $server | Add-Member NoteProperty env ([pscustomobject]@{})
    }
    if ($server.env -isnot [pscustomobject]) { throw 'coremcp.env must be a JSON object.' }
    $server | Add-Member NoteProperty command $ServerPath -Force
    $server | Add-Member NoteProperty args @() -Force
    # Quote the SQLite value to handle semicolons in directory names.
    $server.env | Add-Member NoteProperty COREMCP_TRANSCRIPTS_CONNECTION_STRING ('Data Source="' + $DatabasePath + '"') -Force
    $config.mcpServers | Add-Member NoteProperty coremcp $server -Force
    $json = ConvertTo-Json -InputObject $config -Depth 100
    $null = ConvertFrom-Json -InputObject $json
    $directory = Split-Path -Parent $ConfigPath
    $null = New-Item -ItemType Directory -Path $directory -Force
    $temporary = Join-Path $directory ([IO.Path]::GetRandomFileName())
    try {
        [IO.File]::WriteAllText($temporary, $json, (New-Object Text.UTF8Encoding $false))
        if ($exists) {
            if ([IO.File]::ReadAllText($ConfigPath) -cne $original) {
                throw 'Claude configuration changed during setup. Close Claude and retry.'
            }
            $backup = $ConfigPath + '.backup-' + [guid]::NewGuid().ToString('N')
            [IO.File]::Replace($temporary, $ConfigPath, $backup)
            Write-Host "Configuration backup: $backup"
        } else { [IO.File]::Move($temporary, $ConfigPath) }
    } finally {
        if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary }
    }
    Write-Host "Configured Claude: $ConfigPath"
}
