# تشغيل Chrome للتطوير مع بروكسي CORS محلي (localhost → coursy.sy)
$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)

$proxyPort = 5478
$proxyUrl = "http://127.0.0.1:$proxyPort"

function Test-ProxyUp {
  try {
    $tcp = New-Object System.Net.Sockets.TcpClient
    $tcp.Connect("127.0.0.1", $proxyPort)
    $tcp.Close()
    return $true
  } catch {
    return $false
  }
}

if (-not (Test-ProxyUp)) {
  Write-Host "Starting CORS dev proxy on $proxyUrl ..."
  Start-Process -FilePath "dart" -ArgumentList "run", "tool/dev_cors_proxy.dart" -WindowStyle Minimized
  $deadline = (Get-Date).AddSeconds(8)
  while ((Get-Date) -lt $deadline) {
    if (Test-ProxyUp) { break }
    Start-Sleep -Milliseconds 250
  }
  if (-not (Test-ProxyUp)) {
    Write-Error "CORS proxy did not start on port $proxyPort."
  }
} else {
  Write-Host "CORS dev proxy already running on $proxyUrl"
}

Write-Host "Launching Flutter on Chrome (API via proxy) ..."
flutter run -d chrome --web-port=7357 @args
