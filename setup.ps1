# setup.ps1 - Initialize Project Dependencies
$ErrorActionPreference = "Stop"

$externalDir = Join-Path $PSScriptRoot "external"
$godotVersion = "4.4.1-stable"
# Note: Version string for templates folder is slightly different (no -stable, just .stable)
$godotTemplateVer = "4.4.1.stable"
$godotSteamUrl = "https://codeberg.org/godotsteam/godotsteam/archive/1a975d21440025be4b90952394de86053893813f.zip"

if (-not (Test-Path $externalDir)) {
    New-Item -ItemType Directory -Path $externalDir | Out-Null
}

# --- 1. Download Godot Engine ---
$godotZip = Join-Path $externalDir "godot.zip"
$godotExe = Join-Path $externalDir "Godot_v$godotVersion`_win64.exe"

if (-not (Test-Path $godotExe)) {
    Write-Host "Downloading Godot $godotVersion..." -ForegroundColor Cyan
    $godotUrl = "https://github.com/godotengine/godot/releases/download/$godotVersion/Godot_v$godotVersion`_win64.exe.zip"
    Invoke-WebRequest -Uri $godotUrl -OutFile $godotZip
    
    Write-Host "Extracting Godot..."
    Expand-Archive -Path $godotZip -DestinationPath $externalDir -Force
    Remove-Item $godotZip
}
else {
    Write-Host "Godot found at $godotExe" -ForegroundColor Green
}

# --- 2. Download GodotSteam ---
$steamAddonDir = Join-Path $PSScriptRoot "addons/godotsteam"

if (-not (Test-Path $steamAddonDir)) {
    Write-Host "Downloading GodotSteam..." -ForegroundColor Cyan
    $steamZip = Join-Path $externalDir "godotsteam.zip"
    Invoke-WebRequest -Uri $godotSteamUrl -OutFile $steamZip
    
    Write-Host "Extracting GodotSteam..."
    $tempExtract = Join-Path $externalDir "godotsteam_temp"
    Expand-Archive -Path $steamZip -DestinationPath $tempExtract -Force
    
    # Move to addons
    if (-not (Test-Path "addons")) { New-Item -ItemType Directory -Path "addons" | Out-Null }
    $archiveRoot = Get-ChildItem -Path $tempExtract | Select-Object -First 1
    Copy-Item -Path "$tempExtract/$($archiveRoot.Name)/addons/godotsteam" -Destination "addons" -Recurse -Force
    
    # Also copy steam_api64.dll to external for run_game.ps1
    Copy-Item -Path "addons/godotsteam/win64/steam_api64.dll" -Destination $externalDir -Force

    # Cleanup
    Remove-Item $tempExtract -Recurse -Force
    Remove-Item $steamZip
}
else {
    Write-Host "GodotSteam already installed in addons/godotsteam" -ForegroundColor Green
}

# --- 3. Download Export Templates (Required for release.ps1) ---
$templateDir = "$env:APPDATA\Godot\export_templates\$godotTemplateVer"
if (-not (Test-Path $templateDir)) {
    Write-Host "Downloading Export Templates for Godot $godotVersion..." -ForegroundColor Cyan
    $templateUrl = "https://github.com/godotengine/godot/releases/download/$godotVersion/Godot_v$godotVersion`_export_templates.tpz"
    $templateZip = Join-Path $externalDir "templates.zip"
    
    # Note: .tpz is just a zip
    Invoke-WebRequest -Uri $templateUrl -OutFile $templateZip
    
    Write-Host "Installing Export Templates..."
    $tempTemplateExtract = Join-Path $externalDir "template_extract"
    Expand-Archive -Path $templateZip -DestinationPath $tempTemplateExtract -Force
    
    New-Item -ItemType Directory -Path $templateDir -Force | Out-Null
    # Extract puts things in a 'templates' subfolder
    Copy-Item -Path "$tempTemplateExtract/templates/*" -Destination $templateDir -Recurse -Force
    
    Remove-Item $tempTemplateExtract -Recurse -Force
    Remove-Item $templateZip
    Write-Host "Export Templates installed to $templateDir" -ForegroundColor Green
}
else {
    Write-Host "Export Templates already installed." -ForegroundColor Green
}

Write-Host "----------------------------------------------------"
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "Usage:"
Write-Host "  Launch Game:  .\run_game.ps1"
Write-Host "  Create Build: .\release.ps1"
Write-Host "----------------------------------------------------"
