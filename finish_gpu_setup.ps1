# finish_gpu_setup.ps1
$ErrorActionPreference = "Stop"
$gpuVenvDir = "$PSScriptRoot\gpu_venv"
$pipExe = "$gpuVenvDir\Scripts\pip.exe"

Write-Host "Finishing GPU Environment Setup..."
& $pipExe install stable-baselines3 godot-rl shimmy tensorboard

Write-Host "Verifying installations..."
& "$gpuVenvDir\Scripts\python.exe" -c "import torch; print(f'Torch: {torch.__version__}, CUDA: {torch.cuda.is_available()}')"
& "$gpuVenvDir\Scripts\python.exe" -c "import godot_rl; print(f'Godot RL: {godot_rl.__version__}')"
