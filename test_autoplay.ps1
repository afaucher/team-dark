$godotPath = "c:\Users\alexa\.gemini\antigravity\scratch\team-dark\external\Godot_v4.4.1-stable_win64.exe"
$projectDir = "c:\Users\alexa\.gemini\antigravity\scratch\team-dark"
$serverLog = "autoplay_server.log"
$clientLog = "autoplay_client.log"

Write-Host "[Test] Cleaning up old logs..." -ForegroundColor Cyan
Remove-Item $serverLog -ErrorAction SilentlyContinue
Remove-Item $clientLog -ErrorAction SilentlyContinue

Write-Host "[Test] Killing any existing Godot processes..." -ForegroundColor Cyan
Get-Process "Godot*" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

Write-Host "[Test] Starting Headless Server..." -ForegroundColor Cyan
$serverProc = Start-Process -FilePath $godotPath -ArgumentList "--path `"$projectDir`" --server --headless --no-window" -PassThru -RedirectStandardOutput $serverLog -RedirectStandardError "autoplay_server_err.log" -WindowStyle Hidden
Start-Sleep -Seconds 5

Write-Host "[Test] Starting Autoplay Client..." -ForegroundColor Cyan
$clientProc = Start-Process -FilePath $godotPath -ArgumentList "--path `"$projectDir`" --autoplay --headless --no-window localhost" -PassThru -RedirectStandardOutput $clientLog -RedirectStandardError "autoplay_client_err.log" -WindowStyle Hidden

Write-Host "[Test] Running for 30 seconds... (Check logs for [AI] output)" -ForegroundColor Yellow
Start-Sleep -Seconds 30

Write-Host "[Test] Cleaning up processes..." -ForegroundColor Cyan
Stop-Process -Id $serverProc.Id -Force -ErrorAction SilentlyContinue
Stop-Process -Id $clientProc.Id -Force -ErrorAction SilentlyContinue

Write-Host "[Test] Done. Check $serverLog and $clientLog for results." -ForegroundColor Green
