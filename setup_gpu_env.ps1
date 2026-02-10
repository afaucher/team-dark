# setup_gpu_env.ps1
$ErrorActionPreference = "Stop"

$pythonVersion = "3.11.9"
$pythonUrl = "https://www.python.org/ftp/python/$pythonVersion/python-$pythonVersion-embed-amd64.zip"
$gpuEnvDir = "$PSScriptRoot\python_gpu"
$gpuVenvDir = "$PSScriptRoot\gpu_venv"

Write-Host "=== Setting up GPU-Ready Python Environment ===" -ForegroundColor Cyan

# 1. Download and Extract Python Embeddable
if (-not (Test-Path $gpuEnvDir)) {
    Write-Host "Downloading Python $pythonVersion Embeddable..."
    New-Item -ItemType Directory -Force -Path $gpuEnvDir | Out-Null
    $zipPath = "$gpuEnvDir\python.zip"
    Invoke-WebRequest -Uri $pythonUrl -OutFile $zipPath
    
    Write-Host "Extracting..."
    Expand-Archive -Path $zipPath -DestinationPath $gpuEnvDir -Force
    Remove-Item $zipPath
}
else {
    Write-Host "Python base directory already exists."
}

# 2. Enable pip support in ._pth file
$pthFile = "$gpuEnvDir\python311._pth"
if (Test-Path $pthFile) {
    Write-Host "Patching python311._pth to enable site-packages..."
    $content = Get-Content $pthFile
    $content = $content -replace "#import site", "import site"
    Set-Content -Path $pthFile -Value $content
}

# 3. Install pip
$getPipUrl = "https://bootstrap.pypa.io/get-pip.py"
$getPipPath = "$gpuEnvDir\get-pip.py"
if (-not (Test-Path "$gpuEnvDir\Scripts\pip.exe")) {
    Write-Host "Downloading get-pip.py..."
    Invoke-WebRequest -Uri $getPipUrl -OutFile $getPipPath
    
    Write-Host "Installing pip..."
    & "$gpuEnvDir\python.exe" $getPipPath --no-warn-script-location
}

# 4. Create Virtual Environment
if (-not (Test-Path $gpuVenvDir)) {
    Write-Host "Creating Virtual Environment 'gpu_venv'..."
    # We use the embed python to create the venv. It requires virtualenv package first.
    & "$gpuEnvDir\Scripts\pip.exe" install virtualenv --no-warn-script-location
    & "$gpuEnvDir\Scripts\virtualenv.exe" $gpuVenvDir
}
else {
    Write-Host "gpu_venv already exists."
}

# 5. Install GPU Torch and Dependencies
Write-Host "Installing PyTorch (CUDA 12.1) and Dependencies..."
$pipExe = "$gpuVenvDir\Scripts\pip.exe"

# Uninstall CPU torch if present
& $pipExe uninstall -y torch torchvision torchaudio

# Install GPU Torch
& $pipExe install torch --index-url https://download.pytorch.org/whl/cu121 --no-cache-dir

# Install RL Libs
& $pipExe install stable-baselines3 godot-rl shimmy variable-hyper-parameters tensorboard

Write-Host "`n=== GPU Environment Setup Complete! ===" -ForegroundColor Green
Write-Host "To use this environment for training:"
Write-Host "1. Edit rebuild_and_train.ps1"
Write-Host "2. Change pythonExe path to gpu_venv\Scripts\python.exe"
