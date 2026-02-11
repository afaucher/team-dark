# Team-Dark: Wave Game Modes & Engagement Strategy

This document outlines the high-priority game modes (Waves) for **team-dark**. Each wave shifts the fundamental rules of the game, forcing players to adapt their strategy.

---

## 0. Baseline: The "Fetch" Wave (Existing)
**Concept:** The standard "Seek and Extract" loop. Collect items to unlock the path home.
*   **Core Mechanics:** 
    *   3 Gems (High-visibility neon pickups) are scattered across the map.
    *   Collecting all gems activates the **Extraction Point**.
    *   The Extraction Point is a stationary zone that requires the player(s) to stay within it for a short duration.
*   **Engagement Parameters:**
    *   `Gem_Count`: Number of gems required (standard is 3).
    *   `Extraction_Time`: How long the player must "Hold the Zone" to win.
    *   `Gem_Spawn_Grouping`: Whether gems are spread thin or clustered in danger zones.
*   **Evaluation & Test:**
    *   *Feasibility:* Implemented (Existing baseline).
    *   *Engagement Check:* Does the search for gems lead the player into interesting enemy encounters?

## 1. Environmental Heat Map (User Candidate)
**Concept:** The arena tiles glow red with increasing intensity. Darkness equals safety; red equals damage.
*   **Core Mechanics:** 
    *   Tiles transition through a gradient: Black -> Dim Red -> Burning Red -> White Hot.
    *   Damage is applied per second based on the "Heat" value of the tile the player is standing on.
*   **Engagement Parameters:**
    *   `Heat_Growth_Rate`: How fast tiles transition to dangerous states.
    *   `Safe_Tile_Percentage`: The minimum number of "safe" (black) tiles maintained at any time.
    *   `Pattern_Complexity`: Whether heat moves in waves, clusters, or random noise.
*   **Evaluation & Test:**
    *   *Feasibility:* High (Shader-based tile effects).
    *   *Engagement Check:* Does it feel like a dance? If the safe zones move too fast, it's frustrating; too slow, it's boring.

## 2. Layered Siege (User Candidate)
**Concept:** The exit zone is protected by concentric rings of distinct enemy archetypes.
*   **Core Mechanics:** 
    *   Ring 1 (Outer): Fast, weak swarmers.
    *   Ring 2 (Middle): Ranged snipers/turrets.
    *   Ring 3 (Inner): Heavy tanks or shield-bearers.
    *   Player must peel the "onion" to reach the extraction point.
*   **Engagement Parameters:**
    *   `Ring_Density`: How many enemies per layer.
    *   `Aggro_Radius`: Do all layers attack at once, or only when you breach their perimeter?
    *   `Layer_Respawn_Rate`: If you retreat, do the layers refill?
*   **Evaluation & Test:**
    *   *Feasibility:* High (Spawner logic).
    *   *Engagement Check:* Does it feel like a progression? The "breakthrough" moment when a layer collapses should be high-impact.

## 3. Sprint Races (User Candidate)
**Concept:** Periodically, a waypoint is marked far away. The player must reach it before a timer expires while under heavy fire.
*   **Core Mechanics:** 
    *   Winning 3 consecutive "sprints" triggers the wave victory.
    *   Enemies spawn primarily in the path of the race.
*   **Engagement Parameters:**
    *   `Sprint_Distance`: Fixed distance from the player's current coordinate.
    *   `Chase_Intensity`: Speed of enemies spawned behind the player vs. obstacles in front.
    *   `Win_Streak_Requirement`: Number of successful races needed.
*   **Evaluation & Test:**
    *   *Feasibility:* Medium (Requires dynamic path-finding check for waypoints).
    *   *Engagement Check:* Does the player feel "hunted"? The tension should come from the ticking clock.

## 4. Frequency Shift (Candidate 1)
**Concept:** The player and enemies pulse between Cyan and Magenta states.
*   **Core Mechanics:** 
    *   Damage is color-locked.
    *   Collision is color-inverted (you pass through walls of the opposite color).
*   **Engagement Parameters:**
    *   `Pulse_Interval`: Time between automatic shifts (e.g., 5-8 seconds).
    *   `Shift_Warning_Time`: Visual/audio "recharging" indicator before the flip.
*   **Evaluation & Test:**
    *   *Feasibility:* Medium (Visual shaders + collision layer swapping).
    *   *Engagement Check:* Does it create "planning" moments? Players should use the opposite-color walls as temporary escapes.

## 5. Kinetic Battery (Candidate 2)
**Concept:** Weapons only charge while moving fast. Speed = Firepower.
*   **Core Mechanics:** 
    *   HUD features a "Charge Bar" tied to the player's velocity vector.
    *   Low speed = low fire rate/damage. Max speed = "Overcharged" projectiles.
*   **Engagement Parameters:**
    *   `Velocity_Threshold`: Minimum speed required to fire at all.
    *   `Decay_Rate`: How fast the charge drops when you stop.
*   **Evaluation & Test:**
    *   *Feasibility:* High (Code-based weapon modifiers).
    *   *Engagement Check:* Does it feel fluid? The player should feel rewarded for "orbiting" the battle rather than "kiting" it.

## 6. Packet Loss / Glitch (Candidate 6)
**Concept:** Temporal snapping. Every X seconds, you are reverted to a previous position.
*   **Core Mechanics:** 
    *   The game tracks a 3-second buffer of the player's state.
    *   When the "Desync" hits, you snap back, but kills made during the buffer remain.
*   **Engagement Parameters:**
    *   `Snap_Frequency`: How often the glitch occurs.
    *   `Ghost_Shadow`: A visual trail showing where you were 3 seconds ago (the snap-back point).
*   **Evaluation & Test:**
    *   *Feasibility:* Medium-High (State management buffer).
    *   *Engagement Check:* Is it disorienting? We must ensure the "Ghost Shadow" is very clear so the player knows where they'll end up.

## 7. Fracture (Candidate 9)
**Concept:** Large geometric enemies that split into smaller, faster versions upon death.
*   **Core Mechanics:** 
    *   Initial Boss -> 2 Elites -> 4 Grunts -> 8 Shards.
    *   The shard count grows exponentially, flooding the screen.
*   **Engagement Parameters:**
    *   `Split_Factor`: How many children each level spawns.
    *   `Speed_Multiplier`: How much faster each successive generation becomes.
*   **Evaluation & Test:**
    *   *Feasibility:* High (Recursion-based spawning).
    *   *Engagement Check:* Does the player have the crowd control (CC) to handle the shards? This mode tests "Area of Effect" weapon efficiency.

---

# Evaluation Framework

To determine which modes "stick," we will use the following **Engagement Rubric**:

1.  **Deductive Clarity:** Can a new player understand the "Rule" within 10 seconds of the wave starting?
    *   *Metric:* Time to first successful interaction with the new mechanic.
2.  **Strategic Shift:** Does the player change their movement or weapon choice compared to a standard wave?
    *   *Metric:* Change in average velocity or weapon swap frequency.
3.  **Tension Curve:** Does the difficulty ramp up towards the end of the timer/objective?
    *   *Metric:* "Near-death" events per minute.

# Management Strategies

To keep these engaging, we will implement **Dynamic Parameter Scaling**:
*   If the player is "Stun-locked" (taking damage too fast), the `Pulse_Interval` or `Heat_Growth_Rate` should subtly slow down.
*   If the player is "Dominating" (0 damage taken for 30s), we increase `Enemy_Density` or `Projectiles_Per_Burst`.

# Next Steps
1.  **Prototype "Frequency Shift"** as the first proof of concept for "Systemic Rule Changes."
2.  **Implement a "Wave Manager"** singleton that can toggle these parameters on/off.
