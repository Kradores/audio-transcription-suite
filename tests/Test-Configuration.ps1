$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot '..\installer\Configure-Claude.ps1')
$root = Join-Path $PSScriptRoot ('scratch-' + [guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Path $root
function Assert($Condition, [string]$Message) { if (-not $Condition) { throw $Message } }
try {
    $path = Join-Path $root 'claude_desktop_config.json'
    $server = 'C:\Users\Test User\Apps\CoreMcp.Server.exe'
    $database = 'C:\Users\Test User\data;archive\transcripts.db'
    Update-ClaudeConfiguration $path $server $database
    $config = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
    Assert ($config.mcpServers.coremcp.command -ceq $server) 'Wrong server path'
    Assert ($config.mcpServers.coremcp.args -is [array]) 'args must be an array'
    Assert ($config.mcpServers.coremcp.args.Count -eq 0) 'args must be empty'
    Assert ($config.mcpServers.coremcp.env.COREMCP_TRANSCRIPTS_CONNECTION_STRING -ceq ('Data Source="' + $database + '"')) 'Wrong connection string'
    $original = '{"theme":"dark","mcpServers":{"other":{"command":"other.exe"},"coremcp":{"command":"old.exe","env":{"KEEP":"yes"}}}}'
    [IO.File]::WriteAllText($path, $original)
    Update-ClaudeConfiguration $path $server $database
    $config = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
    Assert ($config.theme -eq 'dark') 'Lost other settings'
    Assert ($config.mcpServers.other.command -eq 'other.exe') 'Lost another server'
    Assert ($config.mcpServers.coremcp.env.KEEP -eq 'yes') 'Lost unrelated environment'
    $backups = @(Get-ChildItem -LiteralPath $root -Filter '*.backup-*')
    Assert ($backups.Count -eq 1) 'Missing backup'
    Assert ([IO.File]::ReadAllText($backups[0].FullName) -ceq $original) 'Backup differs'
    $before = [IO.File]::ReadAllText($path)
    Update-ClaudeConfiguration $path $server $database
    Assert ([IO.File]::ReadAllText($path) -ceq $before) 'Repeated setup changed content'
    foreach ($bad in @('{bad', '[]', 'null', '{"mcpServers":null}', '{"mcpServers":[]}', '{"mcpServers":{"coremcp":{"env":[]}}}')) {
        [IO.File]::WriteAllText($path, $bad)
        $failed = $false
        try { Update-ClaudeConfiguration $path $server $database } catch { $failed = $true }
        Assert $failed 'Invalid configuration was accepted'
        Assert ([IO.File]::ReadAllText($path) -ceq $bad) 'Invalid configuration was modified'
    }
    Write-Host 'PASS: new config, merge, backup, repeat setup, escaped paths, and malformed configuration protection.'
} finally {
    $resolved = [IO.Path]::GetFullPath($root)
    if ((Split-Path -Parent $resolved) -ne [IO.Path]::GetFullPath($PSScriptRoot)) { throw 'Unexpected test directory' }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
