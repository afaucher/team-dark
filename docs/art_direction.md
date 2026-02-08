# Art Direction & Style Guide

## Visual Style
- **Theme**: High-contrast geometric vector art.
- **Atmosphere**: Arcade, digital, neon-on-dark.
- **Rendering**:
    - Solid bright outlines (2-3px width).
    - Black or very dark fills for characters/objects to ensure outlines pop.
    - "Fake" depth using layered 2D elements.
    - Glow effects (bloom) to enhance the neon aesthetic.

## Color Palette
Based on "Neon on Dark" high-contrast research.

### Background
- **Ground (Low)**: `#1a1a2e` (Dark Slate Blue/Charcoal)
- **Ground (Med)**: `#16213e` (Deep Blue)
- **Ground (High)**: `#0f3460` (Muted Blue)
- **Obstacles**: `#e94560` (Red/Pink) or Dark Grey with Neon Outline

### Entities
- **Player**: Cyan / Electric Blue (`#00fff5`) outline, Black fill.
- **Enemies**:
    - **Tier 1**: Bright Orange (`#ff9a00`) outline.
    - **Tier 2**: Neon Purple (`#b829ea`) outline.
    - **Tier 3**: Lime Green (`#39ff14`) outline.
- **Projectiles**: Matching the source entity's color, solid fill.

### UI
- **Health/Status**: Green/Red standard, but stylized with thin glowing lines.
- **Text**: White or very light grey, sans-serif, geometric font.

## Visual Testing Process
We use an automated screenshot workflow to validate procedural generation and visual consistency.

1.  **Script**: `scripts/auto_screenshot.gd` captures the viewport after a short delay.
2.  **Scene**: `scenes/test/test_screenshot_scene.tscn` sets up the map and screenshotter.
3.  **Execution**: Run `.\run_visual_test.ps1` in PowerShell.
4.  **Output**: Images are saved to `screenshots/` in the project root.

## Implementation Notes
- **Outlines**: Use Godot's `draw_polyline` or shaders for outlines.
- **Glow**: Use `WorldEnvironment` with Glow enabled (HDR threshold ~1.0).
- **Hex Grid**: Already implemented in `map_renderer.gd`, need to update colors to match this palette.
