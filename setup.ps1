# setup.ps1 - Initialize Project Dependencies

$ErrorActionPreference = "Stop"

$externalDir = Join-Path $PSScriptRoot "external"
$godotVersion = "4.4.1-stable"
$godotSteamUrl = "https://codeberg.org/godotsteam/godotsteam/archive/1a975d21440025be4b90952394de86053893813f.zip"

if (-not (Test-Path $externalDir)) {
    New-Item -ItemType Directory -Path $externalDir | Out-Null
}

# --- 1. Download Godot Engine ---
$godotZip = Join-Path $externalDir "godot.zip"
$godotExe = Join-Path $externalDir "Godot_v$godotVersion`_win64.exe"

if (-not (Test-Path $godotExe)) {
    Write-Host "Downloading Godot $godotVersion..."
    $godotUrl = "https://github.com/godotengine/godot/releases/download/$godotVersion/Godot_v$godotVersion`_win64.exe.zip"
    Invoke-WebRequest -Uri $godotUrl -OutFile $godotZip
    
    Write-Host "Extracting Godot..."
    Expand-Archive -Path $godotZip -DestinationPath $externalDir -Force
    Remove-Item $godotZip
}
else {
    Write-Host "Godot found at $godotExe"
}

# --- 2. Download GodotSteam ---
$steamAddonDir = Join-Path $PSScriptRoot "addons/godotsteam"

if (-not (Test-Path $steamAddonDir)) {
    Write-Host "Downloading GodotSteam..."
    $steamZip = Join-Path $externalDir "godotsteam.zip"
    Invoke-WebRequest -Uri $godotSteamUrl -OutFile $steamZip
    
    Write-Host "Extracting GodotSteam..."
    $tempExtract = Join-Path $externalDir "godotsteam_temp"
    Expand-Archive -Path $steamZip -DestinationPath $tempExtract -Force
    
    # Move to addons
    if (-not (Test-Path "addons")) { New-Item -ItemType Directory -Path "addons" | Out-Null }
    # The archive structure is <branch_name_or_commit>/addons/godotsteam
    $archiveRoot = Get-ChildItem -Path $tempExtract | Select-Object -First 1
    Copy-Item -Path "$tempExtract/$($archiveRoot.Name)/addons/godotsteam" -Destination "addons" -Recurse -Force
    
    # Cleanup
    Remove-Item $tempExtract -Recurse -Force
    Remove-Item $steamZip
}
else {
    Write-Host "GodotSteam already installed in addons/godotsteam"
}

Write-Host "Setup Complete!"
Write-Host "Run the game using: .\run.ps1"
