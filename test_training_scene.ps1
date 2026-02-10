$godot_exe = "c:\Users\alexa\.gemini\antigravity\scratch\team-dark\bin\godot.exe"
if (-not (Test-Path $godot_exe)) {
    Write-Error "Godot executable not found at $godot_exe"
    exit 1
}

& $godot_exe --path . "res://scenes/training/training_scene.tscn"
