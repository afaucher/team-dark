# release.ps1 - Build and package Team Dark for release
$godotPath = "$PSScriptRoot\external\Godot_v4.4.1-stable_win64.exe"
$buildDir = "$PSScriptRoot\build"
$windowsBuildDir = "$buildDir\windows"
$exportPath = "$windowsBuildDir\TeamDark.exe"

# 1. Verification
if (-not (Test-Path $godotPath)) {
    Write-Error "Godot executable not found at $godotPath. Please run setup.ps1 first."
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

# We use --headless to avoid opening a window
$godotArgs = "--path `"$PSScriptRoot`" --headless --export-release `"Windows Desktop`" `"$exportPath`""

# Run Godot export
$process = Start-Process -FilePath $godotPath -ArgumentList $godotArgs -Wait -PassThru -NoNewWindow

# 4. Copy Steam Dependencies
Write-Host "Copying Steam dependencies..." -ForegroundColor Cyan
$steamDll = "$PSScriptRoot\external\steam_api64.dll"
$steamAppId = "$PSScriptRoot\steam_appid.txt"

if (Test-Path $steamDll) {
    Copy-Item $steamDll -Destination $windowsBuildDir
}
else {
    Write-Warning "steam_api64.dll not found in external/! Building without it may fail."
}

if (Test-Path $steamAppId) {
    Copy-Item $steamAppId -Destination $windowsBuildDir
}

# 5. Check if export succeeded
if ($process.ExitCode -ne 0 -or -not (Test-Path $exportPath)) {
    Write-Host "----------------------------------------------------" -ForegroundColor Red
    Write-Host "BUILD FAILED!" -ForegroundColor Red
    Write-Host "Error: The executable was not created at $exportPath."
    Write-Host ""
    Write-Host "Common causes:"
    Write-Host "  1. Missing Export Templates - Open Godot Editor -> Editor -> Manage Export Templates -> Download"
    Write-Host "  2. export_presets.cfg missing or corrupted"
    Write-Host "  3. Godot version mismatch (Expected v4.4.1)"
    Write-Host "----------------------------------------------------" -ForegroundColor Red
    exit 1
}

Write-Host "Export successful!" -ForegroundColor Green

# 6. Packaging
$zipName = "TeamDark_Windows.zip"
$zipPath = "$buildDir\$zipName"

Write-Host "Packaging build into $zipPath..." -ForegroundColor Cyan

# Remove .tmp file if present (Godot temp file)
$tmpFile = "$windowsBuildDir\TeamDark.tmp"
if (Test-Path $tmpFile) {
    Remove-Item $tmpFile -Force
}

Compress-Archive -Path "$windowsBuildDir\*" -DestinationPath $zipPath -Force

$exeSize = [math]::Round((Get-Item $exportPath).Length / 1MB, 1)
$zipSize = [math]::Round((Get-Item $zipPath).Length / 1MB, 1)

Write-Host "----------------------------------------------------"
Write-Host "Build Complete!" -ForegroundColor Green
Write-Host "Executable: $exportPath ($exeSize MB)"
Write-Host "ZIP: $zipPath ($zipSize MB)"
Write-Host "----------------------------------------------------"
