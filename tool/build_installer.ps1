param(
  [string]$Publisher = "TheDiamondStorySetup",
  [string]$AppName = "The Diamond Story"
)

$ErrorActionPreference = "Stop"

function Write-Step {
  param([string]$Message)
  Write-Host "[setup] $Message" -ForegroundColor Cyan
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $repoRoot

$pubspecPath = Join-Path $repoRoot "pubspec.yaml"
if (-not (Test-Path $pubspecPath)) {
  throw "pubspec.yaml not found at $pubspecPath"
}

$pubspecContent = Get-Content $pubspecPath
$versionLine = $pubspecContent | Where-Object { $_ -match '^version:\s*' } | Select-Object -First 1
if (-not $versionLine) {
  throw "Could not find version in pubspec.yaml"
}

$rawVersion = ($versionLine -replace '^version:\s*', '').Trim()
$appVersion = ($rawVersion -split '\+')[0]

Write-Step "Detected app version: $appVersion"

$issPath = Join-Path $repoRoot "windows\installer\the_diamond_story.iss"
if (-not (Test-Path $issPath)) {
  throw "Installer script not found at $issPath"
}

Write-Step "Building Windows release"
flutter build windows --release
if ($LASTEXITCODE -ne 0) {
  throw "Flutter Windows release build failed."
}

$releaseDir = Join-Path $repoRoot "build\windows\x64\runner\Release"
if (-not (Test-Path $releaseDir)) {
  throw "Release folder not found at $releaseDir"
}

$exePath = Join-Path $releaseDir "the_diamond_story.exe"
if (-not (Test-Path $exePath)) {
  throw "Main EXE not found at $exePath"
}

$innoCandidates = @(
  "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
  "$env:ProgramFiles\Inno Setup 6\ISCC.exe"
)

$iscc = $innoCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $iscc) {
  $isccFromPath = Get-Command iscc -ErrorAction SilentlyContinue
  if ($isccFromPath) {
    $iscc = $isccFromPath.Source
  }
}

if (-not $iscc) {
  throw "Inno Setup compiler (ISCC) not found. Install Inno Setup 6 and rerun this script."
}

Write-Step "Compiling installer using ISCC"
& $iscc "/DMyAppVersion=$appVersion" "/DMyAppPublisher=$Publisher" "/DMyAppName=$AppName" $issPath
if ($LASTEXITCODE -ne 0) {
  throw "ISCC failed to compile installer."
}

$installerDir = Join-Path $repoRoot "dist\installer"
Write-Step "Installer build complete"
Write-Host "Output directory: $installerDir" -ForegroundColor Green
