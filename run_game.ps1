$godotPath = "C:\Users\alexa\Downloads\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe"
$projectPath = "$PSScriptRoot\project.godot"

if (-not (Test-Path $godotPath)) {
    Write-Error "Godot executable not found at $godotPath"
    exit 1
}

# Cleanup previous instances
Get-Process "Godot*" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 1

# Run the project. The main scene is defined in project.godot, but we can be explicit.
# Passing --path to ensure it uses the script's directory as project root.
# Launch the game and wait, redirecting output to a timestamped log file
$logFile = "game_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
& $godotPath --path $PSScriptRoot "scenes/game.tscn" 2>&1 | Tee-Object -FilePath $logFile

Write-Host "Game exited. Log saved to $logFile"

Write-Host "Game exited."
# Read-Host "Press Enter to close..."
