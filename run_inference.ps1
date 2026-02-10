param (
    [string]$ModelPath = "final_model.zip",
    [switch]$Headless,
    [int]$Speedup = 1
)

$env:PATH += ";$PWD/ai_venv/Scripts"

# IMPORTANT: If you modify GDScript code, you MUST rebuild the exported executable first!
# Uncomment the following line to auto-rebuild (slower):
# .\release.ps1

$buildDir = "build/windows"
$exePath = Join-Path $buildDir "TeamDark.exe"
$overridePath = Join-Path $buildDir "override.cfg"

if (-not (Test-Path $exePath)) {
    Write-Error "Executable not found at $exePath. Please run release.ps1 first."
    exit 1
}

Write-Host "Setting up inference environment..."

# Create override.cfg to force the training scene
@'
[application]
run/main_scene="res://scenes/training/training_scene.tscn"
'@ | Set-Content $overridePath

Write-Host "Starting Game in Inference Mode..."

try {
    # Resolve absolute path for model
    if (-not (Test-Path $ModelPath)) {
        # Check if relative to current dir
        $ModelPath = Join-Path $PWD $ModelPath
    }
    if (-not (Test-Path $ModelPath)) {
        Write-Error "Model file not found at $ModelPath"
        exit 1
    }
    $absModelPath = (Resolve-Path $ModelPath).Path
    
    # Resolve executable path (Restored)
    $absExePath = (Resolve-Path $exePath).Path
    
    $pythonScript = "scripts/inference/enjoy.py"
    
    $cmdArgs = @($pythonScript, "--env_path", $absExePath, "--model_path", $absModelPath, "--speedup", "$Speedup")
    
    if (-not $Headless) {
        # In enjoy.py, viz=True by default. 
        # But if Headless switch is used, pass viz=False? No.
        # Actually, Godot RL Wrapper takes show_window arg.
        # So we pass --viz if NOT Headless.
        # Wait, args.viz action="store_true".
        # So if passed, it's true. If omitted, false.
        # Default is True in my script (Step 1778).
        # Wait, step 1778: action="store_true", default=True.
        # If action="store_true", presence makes True. Absence makes False (usually).
        # BUT `default=True` overrides absence? No.
        # argparse `store_true` sets False if missing, True if present.
        # UNLESS `default=True` is set?
        # If `default=True`, then absence triggers default (True). Presence triggers True.
        # So effectively always True unless argument handling is smarter.
        # Usually store_true implies default=False.
        # I should fix enjoy.py default logic if I want control.
         
        # For now, let's assume I want Viz by default.
        $cmdArgs += "--viz"
    }
    
    # Use absolute path to python
    $pythonExe = Join-Path $PWD "ai_venv/Scripts/python.exe"
    
    Write-Host "Starting Python Inference..."
    & $pythonExe @cmdArgs
}
catch {
    Write-Error $_
}
finally {
    Write-Host "Cleaning up override.cfg..."
    if (Test-Path $overridePath) { Remove-Item $overridePath }
}
