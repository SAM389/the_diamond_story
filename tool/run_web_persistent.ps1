$ErrorActionPreference = 'Stop'

$workspace = Split-Path -Parent $PSScriptRoot
$profilePath = Join-Path $env:LOCALAPPDATA 'DiamondStoryChromeProfile'
$hostName = '127.0.0.1'
$port = 7357
$url = "http://${hostName}:${port}"

if (-not (Test-Path $profilePath)) {
  New-Item -ItemType Directory -Path $profilePath | Out-Null
}

$chromeCandidates = @(
  (Join-Path $env:ProgramFiles 'Google\Chrome\Application\chrome.exe'),
  (Join-Path ${env:ProgramFiles(x86)} 'Google\Chrome\Application\chrome.exe'),
  (Join-Path $env:ProgramFiles 'Microsoft\Edge\Application\msedge.exe'),
  (Join-Path ${env:ProgramFiles(x86)} 'Microsoft\Edge\Application\msedge.exe')
) | Where-Object { $_ -and (Test-Path $_) }

if (-not $chromeCandidates) {
  throw 'Neither Chrome nor Edge was found. Install an up-to-date browser or open the URL manually after starting the web server.'
}

$browserPath = $chromeCandidates[0]

$serverCommand = "Set-Location '$workspace'; flutter run -d web-server --web-hostname $hostName --web-port $port"
Start-Process powershell -ArgumentList '-NoExit', '-Command', $serverCommand | Out-Null

for ($i = 0; $i -lt 60; $i++) {
  Start-Sleep -Seconds 1
  try {
    $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 2
    if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 500) {
      break
    }
  } catch {
  }
}

Start-Process -FilePath $browserPath -ArgumentList "--user-data-dir=$profilePath", $url | Out-Null

Write-Host "Flutter web server starting at $url"
Write-Host "Browser launched with persistent profile: $profilePath"
