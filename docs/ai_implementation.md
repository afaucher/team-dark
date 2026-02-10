# AI Player Autoplay Implementation

## Overview
This document outlines the implementation of the AI Player Autoplay system, designed to allow automated testing and headless simulations of player behavior. The system uses the **Beehave** behavior tree plugin to drive player actions.

## Architecture

### 1. Player Autoplay Controller
- **Script:** `scripts/ai/controllers/player_autoplay_controller.gd`
- **Inheritance:** Extends `AIController` via explicit file path (to support headless mode).
- **Core Logic:**
  - Instantiates a Beehave behavior tree at runtime.
  - Sets the `actor` for the behavior tree to the player node.
  - Updates input vectors (`move_vector`, `aim_vector`) based on behavior tree execution.
  - **Key Fix:** Does NOT reset input vectors in `update_actions()`, allowing async Beehave updates to persist.

### 2. Behavior Tree Structure
The AI uses a `Selector` root with two main branches:

1.  **Combat Sequence** (Highest Priority):
    - **Condition:** Enemy within range.
    - **Action:** `AttackNearestEnemy` - Aims and fires at the nearest enemy while maintaining distance.

2.  **Mission Sequence** (Fallback):
    - **Action:** `FindMissionTarget` - Locates the nearest Gem or Extraction Point.
        - Adds target position to `blackboard`.
        - Prioritizes collected Gems until `MAX_GEMS` is reached.
    - **Action:** `NavigateToTarget` - Moves the player toward the `mission_target_pos`.

### 3. Key Components
- **`run_game.ps1` / `test_autoplay.ps1`**: Scripts to launch the game in headless mode with autoplay enabled.
- **Headless Compatibility**:
    - Uses runtime `load()` for Beehave classes to avoid parse errors in headless mode.
    - `GameManager` automatically starts the game when running as a dedicated server.
- **Pickup System**:
    - Gems are now added to a specific `"gems"` group for easy AI detection.

## Implementation Details

### Beehave Integration
Due to Godot's headless mode limitations with `class_name` indexing:
- Beehave classes (`BeehaveTree`, `Blackboard`, etc.) are loaded via `load("res://addons/beehave/...")` instead of `preload` or class names.
- The `actor` reference is assigned *after* the tree is added to the scene to ensure correct `get_parent()` resolution.

### Testing
Automated testing is supported via `test_autoplay.ps1`, which:
1.  Starts a headless server.
2.  Starts a headless client with `--autoplay`.
3.  Captures logs from both processes (`autoplay_server.log`, `autoplay_client.log`).
4.  Verifies AI ticking and navigation logic.

## Future Improvements
- **Obstacle Avoidance**: Currently uses direct vector movement. Needs pathfinding (e.g., `NavigationAgent2D`) for complex maps.
- **State Machine Integration**: Could replace or augment the behavior tree for more complex states (e.g., "Reviving Teammate").
