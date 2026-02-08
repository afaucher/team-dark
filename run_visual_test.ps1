$godotExe = "C:\Users\alexa\Downloads\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe"
$projectPath = "$PSScriptRoot"
$scenePath = "scenes/test/test_screenshot_scene.tscn"

# Ensure screenshots directory exists in user:// or project root for visibility
$screenshotDir = "$PSScriptRoot\docs\screenshots"
if (-not (Test-Path $screenshotDir)) {
    New-Item -ItemType Directory -Force -Path $screenshotDir | Out-Null
}

Write-Host "Running Visual Test Scene..."
# Run Godot. We use --headless if we want no window, but for visual test usually we need window for capture?
# Godot 4 headless CAN capture server-side viewports, but sometimes `get_viewport().get_texture().get_image()` requires a window.
# Let's try normal mode first to ensure it captures.
& $godotExe --path $projectPath $scenePath

Write-Host "Check $screenshotDir for results (if configured to save there) or %APPDATA%/Godot/app_userdata/Team Dark/screenshots"
