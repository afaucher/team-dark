# release.ps1 - Build and package Team Dark for release
$godotPath = "C:\Users\alexa\Downloads\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe"
$buildDir = "$PSScriptRoot\build"
$windowsBuildDir = "$buildDir\windows"
$exportPath = "$windowsBuildDir\TeamDark.exe"
$godotVersion = & $godotPath --version

# 1. Verification
if (-not (Test-Path $godotPath)) {
    Write-Error "Godot executable not found at $godotPath"
    exit 1
}

# 2. Prepare Build Directory
Write-Host "Preparing build directory: $buildDir" -ForegroundColor Cyan
if (Test-Path $buildDir) {
    Write-Host "Cleaning existing build directory..." -ForegroundColor Yellow
    Remove-Item -Path $buildDir -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $windowsBuildDir | Out-Null

# 3. Export Windows Desktop Build
Write-Host "Exporting Windows Desktop build to $exportPath..." -ForegroundColor Cyan

# Using the call operator & instead of Start-Process as it handles quoted arguments more reliably in PowerShell
& $godotPath --path $PSScriptRoot --headless --export-release "Windows Desktop" "$exportPath"

if ($LASTEXITCODE -ne 0 -or -not (Test-Path $exportPath)) {
    Write-Host "----------------------------------------------------" -ForegroundColor Red
    Write-Host "BUILD FAILED!" -ForegroundColor Red
    if (-not (Test-Path $exportPath)) {
        Write-Host "Error: The export completed, but the executable was not found at $exportPath."
    }
    Write-Host "Reason: Likely missing Export Templates for version $godotVersion."
    Write-Host "Fix: Open the Godot Editor, go to 'Editor -> Manage Export Templates', and install them."
    Write-Host "----------------------------------------------------" -ForegroundColor Red
    exit 1
}

Write-Host "Export successful!" -ForegroundColor Green

# 4. Packaging
$zipName = "TeamDark_Windows.zip"
$zipPath = "$buildDir\$zipName"

Write-Host "Packaging build into $zipPath..." -ForegroundColor Cyan

if (-not (Test-Path $exportPath)) {
    Write-Error "Executable missing, cannot package!"
    exit 1
}

Compress-Archive -Path "$windowsBuildDir\*" -DestinationPath $zipPath -Force

Write-Host "----------------------------------------------------"
Write-Host "Build Complete!" -ForegroundColor Green
Write-Host "Artifacts location: $buildDir"
Write-Host "Executable: $exportPath"
Write-Host "ZIP: $zipPath"
Write-Host "----------------------------------------------------"
