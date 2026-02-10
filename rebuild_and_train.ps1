param (
    [switch]$Viz,
    [switch]$Turbo,
    [int]$Parallel = 24,
    [int]$Speedup = 20,
    [int]$TotalTimesteps = 10000000,
    [string]$LoadPath = "models/nav_warmstart.zip"
)

# Apply Turbo settings
if ($Turbo) {
    $Parallel = 48
    $Speedup = 100
    Write-Host ">>> TURBO MODE ENGAGED: Speedup 100x | Parallel 48 <<<" -ForegroundColor Green
}


$ErrorActionPreference = "Continue"

Write-Host " `n=== [Simplified Workflow: Rebuild & Train] ===" -ForegroundColor Cyan

# 1. Cleaning up existing processes
Write-Host "[1/4] Terminating existing game and training processes..." -ForegroundColor Yellow
taskkill /F /IM TeamDark.exe /T 2>$null
taskkill /F /IM python.exe /T 2>$null
taskkill /F /IM Godot* /T 2>$null

# 2. Build management (Handling folder locks)
Write-Host "[2/4] Managing environment and rebuilding..." -ForegroundColor Yellow
if (Test-Path "ai_venv") {
    Write-Host "Moving ai_venv to avoid Godot file locks..."
    if (Test-Path "..\ai_venv_tmp") { Remove-Item -Recurse -Force "..\ai_venv_tmp" }
    Move-Item "ai_venv" "..\ai_venv_tmp" -Force
}

try {
    # Run the release script
    .\release.ps1
}
catch {
    Write-Error "Build failed!"
}
finally {
    # Ensure venv is restored even if build fails
    if (Test-Path "..\ai_venv_tmp") {
        Write-Host "Restoring ai_venv..."
        if (Test-Path "ai_venv") { Remove-Item -Recurse -Force "ai_venv" }
        Move-Item "..\ai_venv_tmp" "ai_venv" -Force
    }
}

# 3. Start TensorBoard in background
Write-Host "[3/4] Relaunching TensorBoard (Port 6006)..." -ForegroundColor Yellow
$pythonExe = "ai_venv\Scripts\python.exe"
if (Test-Path $pythonExe) {
    Start-Process -FilePath $pythonExe -ArgumentList "-m", "tensorboard.main", "--logdir", "logs/sb3", "--port", "6006" -WindowStyle Hidden
}

# 4. Launch Training
Write-Host "[4/4] Starting $Parallel parallel training instances..." -ForegroundColor Yellow
$trainParams = @{
    Parallel       = $Parallel
    TotalTimesteps = $TotalTimesteps
}
if ($Viz) { $trainParams["Viz"] = $true }

# Actual execution
$pythonExe = "gpu_venv\Scripts\python.exe"
$envPath = "build\windows\TeamDark.exe"
& $pythonExe scripts\training\train.py --env_path $envPath --n_parallel $Parallel --total_timesteps $TotalTimesteps --speedup $Speedup --load_path $LoadPath $(if ($Viz) { "--viz" })

# 5. Finalize Model (Optional)
if ($Finalize) {
    Write-Host "`n[5/5] Finalizing model to production..." -ForegroundColor Yellow
    if (Test-Path ".\finalize_model.ps1") {
        .\finalize_model.ps1 -SourceModel "final_model.zip" -OutputName "policy.onnx"
    }
    else {
        Write-Warning "finalize_model.ps1 not found. Skipping finalization."
    }
}

Write-Host "=== [Workflow Complete] ===" -ForegroundColor Green
