$ErrorActionPreference = "Stop"

function Invoke-Flutter {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$FlutterArguments
    )

    & flutter @FlutterArguments
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter komutu başarısız: flutter $($FlutterArguments -join ' ')"
    }
}

$clientRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$backupRoot = Join-Path ([System.IO.Path]::GetTempPath()) (
    "project-relay-client-" + [System.Guid]::NewGuid().ToString("N")
)

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw "Flutter bulunamadı. Flutter 3.44 kararlı sürümünü kurup PATH'e ekleyin."
}

New-Item -ItemType Directory -Path $backupRoot | Out-Null
Copy-Item (Join-Path $clientRoot "lib") $backupRoot -Recurse
Copy-Item (Join-Path $clientRoot "test") $backupRoot -Recurse
Copy-Item (Join-Path $clientRoot "assets") $backupRoot -Recurse
Copy-Item (Join-Path $clientRoot "pubspec.yaml") $backupRoot
Copy-Item (Join-Path $clientRoot "analysis_options.yaml") $backupRoot

Push-Location $clientRoot
try {
    $createArguments = @(
        "create"
        "."
        "--platforms=android,web"
        "--project-name=project_relay_client"
        "--org=com.projectrelay"
    )
    Invoke-Flutter @createArguments

    Remove-Item (Join-Path $clientRoot "lib") -Recurse -Force
    Remove-Item (Join-Path $clientRoot "test") -Recurse -Force
    Remove-Item (Join-Path $clientRoot "assets") -Recurse -Force
    Copy-Item (Join-Path $backupRoot "lib") $clientRoot -Recurse -Force
    Copy-Item (Join-Path $backupRoot "test") $clientRoot -Recurse -Force
    Copy-Item (Join-Path $backupRoot "assets") $clientRoot -Recurse -Force
    Copy-Item (Join-Path $backupRoot "pubspec.yaml") $clientRoot -Force
    Copy-Item (Join-Path $backupRoot "analysis_options.yaml") $clientRoot -Force

    Invoke-Flutter pub get
    Invoke-Flutter analyze
    Invoke-Flutter test
}
finally {
    Pop-Location
    Remove-Item $backupRoot -Recurse -Force
}

Write-Host ""
Write-Host "Project Relay istemcisi hazır."
Write-Host "Web: flutter run -d edge --dart-define=RELAY_API_URL=http://127.0.0.1:8000"
