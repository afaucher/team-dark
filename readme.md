# Team Dark

A twin-stick shooter with drop-in multiplayer, procedural hex maps, and modular mount points.

## Prerequisites

To build the game (using `./release.ps1`), you must have **Export Templates** installed for your Godot version:
1. Open the project in the Godot Editor.
2. Go to **Editor -> Manage Export Templates**.
3. Click **Download and Install**.

## How to Play

### Option 1: Host a Game (Listen Server)
1. Run `TeamDark.exe`.
2. Enter your name and click **"Host Game"**.
3. Share your IP address with friends.
4. You're now playing AND hosting!

### Option 2: Join a Game
1. Run `TeamDark.exe`.
2. Enter your name.
3. Enter the host's IP address (or leave blank for localhost).
4. Click **"Join Game"**.

### Option 3: Dedicated Server
For a standalone server (no player on the host machine):
```bash
TeamDark.exe --server --headless
```
Clients then connect using the dedicated server's IP.

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

## CLI Commands (Development)

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

### Run Single Instance
Launches just the game (useful for testing host/join flow manually).
```powershell
./run_game.ps1
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
4. Players can **Host** or **Join** using the in-game menu—no separate server required!
