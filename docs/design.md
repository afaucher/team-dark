# Team Dark - Design Document

**Genre:** Twin-stick shooter with drop-in multiplayer.
**Platform:** Web (PC/Gamepad).
**Engine:** Godot 4.x.

## Core Gameplay
*   **Player Character:** A ball with three mount points (Left, Right, Top).
*   **Goal:** Explore a hexagonal vector-art landscape, find three power gems, and extract.
*   **Multiplayer:** Drop-in/local or remote. Players spawn near teammates out of combat.
*   **Combat:** Twin-stick controls (Move + Aim). "Friendly fire" splits damage between target and shooter.

## Equipment & Mount Points
*   **Weapons:** Pellet gun (starter), machine gun, shotgun, grenades, etc.
*   **Utilities:** Shields, healing, ammo dispenser, jump pack.
*   **Mechanic:** Holding the fire button swaps the equipment at that mount point with a pickup.

## Art Style
*   **Visuals:** 2D vector art.
*   **Layering:** Elements have mild depth; layers are outlined in bright solid colors with black fill.
*   **Debugging:** Modes to render all animations for verification.

## World Generation
*   **Map:** Procedurally generated hexagonal grid.
*   **Terrain:** Flat areas, height differences (1 unit blocks view), destructible obstacles (rocks, trees).
*   **Navigation:** Players can step up 2 height units. Walls > 1 unit are impassable edges.
*   **Layout:** Finite size, ~2-3 mins to cross. Spawn, Gems, and Extraction are minimal distances apart.

## Enemies
*   **Spawning:** Clusters or solo depending on type.
*   **Variety:** Tiers of enemies. "Gray" is basic. Others have unique color schemes per round to obscure abilities.

## UI/UX
*   **Style:** Vector style, complementary light/dark colors.
*   **HUD:** Health, Mount statuses (reload progress), Teammate indicators (direction/status).
*   **Lobby:** Name entry -> Immediate "Global Game" join.
