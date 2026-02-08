$godotExe = "C:\Users\alexa\Downloads\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe"
$projectPath = "$PSScriptRoot"
$scenePath = "scenes/test/character_visualizer.tscn"

Write-Host "Running Character Visualizer..."
& $godotExe --path $projectPath $scenePath
