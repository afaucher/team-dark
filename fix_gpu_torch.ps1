# fix_gpu_torch.ps1
$ErrorActionPreference = "Stop"
$gpuVenvDir = "$PSScriptRoot\gpu_venv"
$pipExe = "$gpuVenvDir\Scripts\pip.exe"
$pythonExe = "$gpuVenvDir\Scripts\python.exe"

Write-Host "Forcing Re-install of CUDA Torch..."
& $pipExe uninstall -y torch torchvision torchaudio
& $pipExe uninstall -y torch torchvision torchaudio # Run twice to be sure

# Install specific CUDA wheel for Python 3.11
# We use the direct link to avoid any ambiguity
$torchUrl = "https://download.pytorch.org/whl/cu121/torch-2.1.2%2Bcu121-cp311-cp311-win_amd64.whl"
# Actually, let's use the index-url which is safer for dependencies
Write-Host "Installing Torch from CUDA 12.1 Index..."
& $pipExe install torch --index-url https://download.pytorch.org/whl/cu121 --no-cache-dir --force-reinstall

Write-Host "Verifying..."
& $pythonExe -c "import torch; print(f'Torch: {torch.__version__}, CUDA: {torch.cuda.is_available()}')"
