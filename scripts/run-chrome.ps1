Set-Location $PSScriptRoot\..

$workspaceRoot = Split-Path -Parent (Get-Location)

$env:APPDATA = Join-Path $workspaceRoot '.dart-appdata'
$env:PUB_CACHE = Join-Path $workspaceRoot '.pub-cache'
$env:GIT_CONFIG_GLOBAL = Join-Path $workspaceRoot '.gitconfig-codex'

& (Join-Path $workspaceRoot '.flutter-sdk\flutter\bin\flutter.bat') run -d chrome --no-pub
