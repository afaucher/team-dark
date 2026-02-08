# Team Dark

A twin-stick shooter with drop-in multiplayer, procedural hex maps, and modular mount points.

## Prerequisites

To build the game (using `./release.ps1`), you must have **Export Templates** installed for your Godot version:
1. Open the project in the Godot Editor.
2. Go to **Editor -> Manage Export Templates**.
3. Click **Download and Install**.

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
    ./TeamDark.exe --server
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
| Fire Left | Q | **L2 / LT (Trigger)** |
| Fire Right | E | **R2 / RT (Trigger)** |
| Fire Front | Space | A / Cross |
| Toggle Debug | F3 | - |
| Quit | Esc | - |

## CLI Commands

We provide PowerShell scripts for a streamlined development workflow:

### Quick Play (Unified)
Kills existing processes and launches both a **Dedicated Server** and a **Client** instance simultaneously.
```powershell
./run.ps1
```

### Build & Release
Packages the game into a Windows executable and a ZIP archive in the `build/` directory.
```powershell
./release.ps1
```

### Validate Scripts
Checks all `.gd` scripts for syntax errors using Godot's headless mode.
```powershell
./validate.ps1
```

### Dedicated Server
Starts only a dedicated server instance.
```powershell
./run_server.ps1
```

### Visual Testing
Automatically captures a screenshot of a generated map for visual verification.
```powershell
./run_visual_test.ps1
```
Screenshots are saved to `docs/screenshots/`.

## Deployment
1. Run `./release.ps1`.
2. Find the packaged ZIP in `./build/TeamDark_Windows.zip`.
3. Distribute the ZIP to players.
