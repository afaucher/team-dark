$godotPath = "C:\Users\alexa\Downloads\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe"
$projectPath = "$PSScriptRoot\project.godot"

if (-not (Test-Path $godotPath)) {
    Write-Error "Godot executable not found at $godotPath"
    exit 1
}

# Check for existing Godot processes (simple check)
$godotProcesses = Get-Process -Name "Godot*" -ErrorAction SilentlyContinue
if ($godotProcesses) {
    Write-Host "Found $($godotProcesses.Count) running Godot process(es). Killing them..." -ForegroundColor Yellow
    $godotProcesses | Stop-Process -Force
    Write-Host "Old server/game instances stopped." -ForegroundColor Green
}

Write-Host "Starting Server..."

# Run the server in a new PowerShell window, keeping it open (-NoExit) for debugging errors.
Start-Process powershell -ArgumentList "-NoExit", "-Command", "`$Host.UI.RawUI.WindowTitle = 'Team Dark Server'; & '$godotPath' --path '$PSScriptRoot' --headless --server"
