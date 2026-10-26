# Запуск мок-API + Flutter Web (PR4).
# Требуется Node.js и Flutter в PATH.

$ErrorActionPreference = "Stop"
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
  [System.Environment]::GetEnvironmentVariable("Path", "User")

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$api = Join-Path $root "api"

Write-Host "API: http://localhost:8080/api  (origin http://localhost:5555)"
Start-Process -FilePath "node" -ArgumentList @(
  "mock-server.js", "--port", "8080", "--origin", "http://localhost:5555"
) -WorkingDirectory $api

Start-Sleep -Seconds 1
Set-Location $root
flutter run -d chrome --web-port=5555 --dart-define=API_BASE_URL=http://localhost:8080/api
