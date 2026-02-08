# release.ps1 - Build and package Team Dark for release
$godotPath = "C:\Users\alexa\Downloads\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe"
$projectPath = "$PSScriptRoot\project.godot"
$buildDir = "$PSScriptRoot\build"
$windowsBuildDir = "$buildDir\windows"

# 1. Verification
if (-not (Test-Path $godotPath)) {
    Write-Error "Godot executable not found at $godotPath"
    exit 1
}

# 2. Prepare Build Directory
if (Test-Path $buildDir) {
    Write-Host "Cleaning existing build directory..." -ForegroundColor Yellow
    Remove-Item -Path $buildDir -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $windowsBuildDir | Out-Null

# 3. Export Windows Desktop Build
Write-Host "Exporting Windows Desktop build..." -ForegroundColor Cyan
# We use --headless to avoid popping up a window during export
$exportResult = & $godotPath --path $PSScriptRoot --headless --export-release "Windows Desktop" "$windowsBuildDir\TeamDark.exe" 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "----------------------------------------------------" -ForegroundColor Red
    Write-Host "BUILD FAILED!" -ForegroundColor Red
    Write-Host "Reason: Likely missing Export Templates for $(& $godotPath --version)."
    Write-Host "Fix: Open the Godot Editor, go to 'Editor -> Manage Export Templates', and install them."
    Write-Host "----------------------------------------------------" -ForegroundColor Red
    Write-Host $exportResult
    exit 1
}

Write-Host "Export successful!" -ForegroundColor Green

# 4. Packaging
$zipName = "TeamDark_Windows.zip"
$zipPath = "$buildDir\$zipName"

Write-Host "Packaging build into $zipName..." -ForegroundColor Cyan
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

Compress-Archive -Path "$windowsBuildDir\*" -DestinationPath $zipPath -Force

Write-Host "----------------------------------------------------"
Write-Host "Build Complete!" -ForegroundColor Green
Write-Host "Artifacts location: $buildDir"
Write-Host "Executable: $windowsBuildDir\TeamDark.exe"
Write-Host "ZIP: $zipPath"
Write-Host "----------------------------------------------------"
