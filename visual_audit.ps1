param (
    [string]$Mode = "All" # Gallery, World, HUD, All
)

$godotExe = "external\Godot_v4.4.1-stable_win64.exe"
$projectPath = "$PSScriptRoot"

# Ensure screenshots directory exists
$screenshotDir = "$PSScriptRoot\docs\screenshots"
if (-not (Test-Path $screenshotDir)) {
    New-Item -ItemType Directory -Force -Path $screenshotDir | Out-Null
}

$scenes = @()
if ($Mode -eq "All") {
    $scenes = @("gallery_audit", "world_audit", "hud_audit", "four_up_hud_audit")
}
else {
    $scenes = @($Mode.ToLower() + "_audit")
}

foreach ($s in $scenes) {
    $scenePath = "scenes/test/$s.tscn"
    Write-Host ">>> Running Visual Audit: $s <<<" -ForegroundColor Cyan
    & $godotExe --path $projectPath $scenePath --quit-after 5000
}

Write-Host "Audit Complete. Check $screenshotDir for new captures." -ForegroundColor Green
