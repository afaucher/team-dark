# Team Dark

A multiplayer Godot 4 game.

## Setup

1.  **Run Setup Script**: This downloads the Godot 4.3 Engine and the GodotSteam plugin.
    ```powershell
    .\setup.ps1
    ```

2.  **Run the Game**: Use the provided script to launch the project with the correct Godot binary.
    ```powershell
    .\run.ps1
    ```

## Development
-   **Release**: Run `.\release.ps1` to build a release package.
-   **Validate**: Run `.\validate.ps1` to check for GDScript errors.

## Controls

| Action | Keyboard | Gamepad |
| :--- | :--- | :--- |
| **Move** | `W`, `A`, `S`, `D` | Left Stick |
| **Aim** | Arrow Keys | Right Stick |
| **Shoot Left** | `Q` | X / Square |
| **Shoot Right** | `E` | B / Circle |
| **Shoot Front** | `Space` | A / Cross |
| **Shoot All** | - | Right Trigger / RB |
| **Pickup / Swap** | **Hold** Fire Button (0.5s) | **Hold** Fire Button (0.5s) |
| **Toggle Debug** | `F3` | - |
| **Quit Game** | `Esc` | - |

## AI Training (Reinforcement Learning)

The game includes a training environment for Godot RL Agents.

### Training Setup

1.  **Python Environment**: Training requires Python 3.11+ and PyTorch.
    *   **Automated GPU Setup**: If you have an NVIDIA GPU, run the following to create a 3.11 environment with CUDA 12.1:
        ```powershell
        .\setup_gpu_env.ps1
        ```
    *   **Manual Setup**: Ensure you have Python 3.11 installed. Install dependencies:
        ```powershell
        pip install torch stable-baselines3 godot-rl shimmy tensorboard
        ```

2.  **Run Training**: Use the unified script to rebuild the game and start training in one command.
    ```powershell
    # Standard CPU Run
    .\rebuild_and_train.ps1 -Parallel 8 -TotalTimesteps 1000000
    
    # GPU Accelerated Run (after running setup_gpu_env.ps1)
    # The script will detect the 'gpu_venv' and use CUDA automatically.
    .\rebuild_and_train.ps1 -Parallel 24 -TotalTimesteps 10000000
    ```

### Monitoring Progress
1.  **TensorBoard**: Track metrics (rewards, kills, gems) in real-time:
    ```powershell
    .\gpu_venv\Scripts\tensorboard.exe --logdir logs/sb3
    ```
2.  **Visualization**: Watch the agent train in a visible window:
    ```powershell
    .\rebuild_and_train.ps1 -Viz -Parallel 1
    ```

*Note: Since the game logic is deterministic relative to the physics tick, you can use high `-Parallel` counts and `speedup` (default 20x) without losing simulation integrity.*

## Hosting
This game uses P2P networking via Steamworks.
-   **Host**: One player acts as the Listen Server.
-   **Join**: Other players join via the Server Browser or Steam Friends list.
