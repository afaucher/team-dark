$godotExe = "$PSScriptRoot\external\Godot_v4.4.1-stable_win64.exe"

if (-not (Test-Path $godotExe)) {
    Write-Error "Godot executable not found at $godotExe"
    exit 1
}

Write-Host "Using Godot: $godotExe"

# Find all .gd scripts in scenes and scripts directories
$scripts = Get-ChildItem -Path "$PSScriptRoot" -Filter "*.gd" -Recurse

foreach ($script in $scripts) {
    Write-Host "Checking $($script.Name)..." -NoNewline
    # Use --headless --check-only and -s (script)
    # We must be careful with relative paths if the script depends on res://
    # Using --path to set the project root is safer.
    
    # Note: Godot's -s command runs a script. To check errors for a script that extends Node, 
    # we might just want to load it. --check-only does syntax check.
    
    # Use --path to ensure res:// resolves correctly
    $output = & $godotExe --headless --path "$PSScriptRoot" --check-only -s $script.FullName 2>&1
    $exitCode = $LASTEXITCODE
    
    if ($exitCode -eq 0) {
        Write-Host " OK" -ForegroundColor Green
    }
    else {
        Write-Host " FAIL ($exitCode)" -ForegroundColor Red
        if ($output) {
            Write-Host "$output" -ForegroundColor Yellow
        }
        else {
            Write-Host "No output captured." -ForegroundColor Yellow
        }
    }
}
