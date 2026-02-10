param (
    [string]$SourceModel = "final_model.zip",
    [string]$OutputName = "policy.onnx"
)

Write-Host "`n=== [Finalizing AI Model: Level 3] ===" -ForegroundColor Cyan

$pythonExe = "ai_venv\Scripts\python.exe"
$exportScript = "scripts/training/export_to_onnx.py"
$outputDir = "models"
$outputPath = Join-Path $outputDir $OutputName

if (-not (Test-Path $SourceModel)) {
    Write-Error "Source model not found: $SourceModel"
    exit 1
}

if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir
}

Write-Host "Exporting $SourceModel to $outputPath..." -ForegroundColor Yellow
& $pythonExe $exportScript --model_path $SourceModel --output_path $outputPath

if ($LASTEXITCODE -eq 0) {
    Write-Host "Successfully finalized $OutputName!" -ForegroundColor Green
    Write-Host "Move this file to your production folder if needed."
}
else {
    Write-Error "Export failed!"
}
