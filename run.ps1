$godotExe = "$PSScriptRoot\external\Godot_v4.4.1-stable_win64.exe"

if (-not (Test-Path $godotExe)) {
    Write-Host "Godot binary not found. Please run .\setup.ps1 first."
    exit 1
}

if ($args[0] -eq "editor") {
    & $godotExe -e --path .
}
else {
    & $godotExe --path .
}
