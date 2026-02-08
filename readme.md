# Team Dark

A twin-stick shooter with drop-in multiplayer, procedural hex maps, and modular mount points.

## How to Run

### Client
1.  Open the project in Godot 4.x.
2.  Press F5 (Play Main Scene).
3.  Enter your player name in the main menu.
4.  Join the game!

### Server
To run a dedicated server:

1.  Export the project for your platform (Linux/Windows).
2.  Run the exported executable with the `--server` flag:
    ```bash
    ./TeamDark.x86_64 --server
    ```
    Or run from the editor:
    ```bash
    godot --headless --server
    ```
3.  The server will listen on port `ENET_PORT` (default: 8910).

## Controls

| Action | Keyboard | Gamepad |
| :--- | :--- | :--- |
| Move | WASD | Left Stick |
| Aim | Arrows | Right Stick |
| Fire Left | Q | L1 / LB |
| Fire Right | E | R1 / RB |
| Fire Top | Space | A / Cross |
| Swap Weapon | Hold Fire Key | Hold Fire Button |

## CLI Commands

We provide PowerShell scripts for easy development and validation:

### Run Game
Launches the game using the local Godot executable.
```powershell
./run_game.ps1
```

### Validate Scripts
Checks all `.gd` scripts for syntax errors using Godot's headless mode.
```powershell
./validate.ps1
```

### Run Server
Starts a dedicated server instance.
```powershell
./run_server.ps1
```

### Visual Testing
Automatically captures a screenshot of a generated map for visual verification.
```powershell
./run_visual_test.ps1
```
Screenshots are saved to the `screenshots/` directory in the project root (or `%APPDATA%/Godot/app_userdata/Team Dark/screenshots` if run from editor).
