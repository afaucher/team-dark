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

## Hosting
This game uses P2P networking via Steamworks.
-   **Host**: One player acts as the Listen Server.
-   **Join**: Other players join via the Server Browser or Steam Friends list.
