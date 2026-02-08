# run.ps1 - Unified launcher for Team Dark
$godotPath = "C:\Users\alexa\Downloads\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe"

# 1. Kill existing Godot processes to ensure clean state
$godotProcesses = Get-Process -Name "Godot*" -ErrorAction SilentlyContinue
if ($godotProcesses) {
    Write-Host "Killing $($godotProcesses.Count) existing Godot process(es)..." -ForegroundColor Yellow
    $godotProcesses | Stop-Process -Force
}

# 2. Start Server
Write-Host "Starting Server..." -ForegroundColor Cyan
# Start as a background job/process we can track
# We use Start-Process with -PassThru to get the process object
# We do NOT use -NoExit because we want to be able to kill it cleanly, 
# or we want it to close when we tell it to.
# Actually, to see server logs, we might want it in a separate window.
# Let's start it in a new window, but keep a handle to it if possible.
# PowerShell's Start-Process returns a process object for the NEW window's shell if we launch powershell.
# A simpler way for the server to "clean up" is if we launch Godot directly. 
# But user wants "server to clean up its terminal". 
# If we launch Godot headless, there is no terminal window unless we make one.

# Let's launch the server in a new console window so logs are visible
$serverProcess = Start-Process powershell -ArgumentList "-Command", "& '$godotPath' --path '$PSScriptRoot' --headless --server; Read-Host 'Server Stopped. Press Enter to close...'" -PassThru

# Wait a moment for server to initialize
Start-Sleep -Seconds 2

# 3. Start Client
Write-Host "Starting Client..." -ForegroundColor Green
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$clientLogOut = "game_${timestamp}_out.log"
$clientLogErr = "game_${timestamp}_err.log"
# We run the client directly in THIS terminal (blocking), OR in a new one?
# User said "quits everything when the game quits".
# So `run.ps1` should wait for the game to exit.
$clientProcess = Start-Process $godotPath -ArgumentList "--path", "$PSScriptRoot", "scenes/game.tscn" -PassThru -NoNewWindow -RedirectStandardOutput $clientLogOut -RedirectStandardError $clientLogErr

# 4. Wait for Client to Exit
$clientProcess.WaitForExit()

# 5. Cleanup
Write-Host "Game exited. Cleaning up..." -ForegroundColor Yellow
if (-not $serverProcess.HasExited) {
    Stop-Process -Id $serverProcess.Id -Force
    Write-Host "Server process terminated." -ForegroundColor Green
}
else {
    Write-Host "Server already exited."
}

Write-Host "Done."
