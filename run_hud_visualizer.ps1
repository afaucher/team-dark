$godotExe = "C:\Users\alexa\Downloads\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe"
$projectPath = "$PSScriptRoot"
$scenePath = "scenes/test/hud_visualizer.tscn"

Write-Host "Running HUD Visualizer..."
& $godotExe --path $projectPath $scenePath
