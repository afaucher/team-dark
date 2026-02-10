param (
    [switch]$Viz,
    [int]$Parallel = 1,
    [int]$TotalTimesteps = 1000000,
    [string]$LoadPath,
    [string]$ExportPath = "models/policy.onnx"
)

$env:PATH += ";$PWD/ai_venv/Scripts"

# IMPORTANT: If you modify GDScript code, you MUST rebuild the exported executable first!
# Uncomment the following line to auto-rebuild (slower):
# .\release.ps1

# We need to place override.cfg next to the executable for it to be picked up by the exported build.
$buildDir = "build/windows"
$exePath = Join-Path $buildDir "TeamDark.exe"
$overridePath = Join-Path $buildDir "override.cfg"

if (-not (Test-Path $exePath)) {
    Write-Error "Executable not found at $exePath. Please run release.ps1 first."
    exit 1
}

Write-Host "Setting up training environment..."

# Create override.cfg to force the training scene
@'
[application]
run/main_scene="res://scenes/training/training_scene.tscn"
'@ | Set-Content $overridePath

Write-Host "Created override.cfg at $overridePath"
Write-Host "Starting Training with godot_rl..."

if ($Viz) {
    Write-Host "Window visible enabled via -Viz."
}
else {
    Write-Host "Running in Headless mode (No window)."
}

try {
    # Run gdrl
    # We use Resolve-Path to ensure absolute path is passed to gdrl
    $absExePath = (Resolve-Path $exePath).Path
    
    $cmdArgs = @("scripts/training/train.py", "--env_path", "$absExePath", "--speedup", "20", "--n_parallel", "$Parallel", "--total_timesteps", "$TotalTimesteps")
    if ($Viz) {
        $cmdArgs += "--viz"
    }
    if ($LoadPath) {
        $cmdArgs += "--load_path"
        $cmdArgs += "$LoadPath"
    }
    if ($ExportPath) {
        $cmdArgs += "--export_path"
        $cmdArgs += "$ExportPath"
    }

    # Run Python script
    # Use absolute path to ensure we use the venv python
    $pythonExe = Join-Path $PWD "ai_venv/Scripts/python.exe"
    & $pythonExe @cmdArgs
}
catch {
    Write-Error $_
}
finally {
    Write-Host "Cleaning up override.cfg..."
    if (Test-Path $overridePath) { Remove-Item $overridePath }
}
