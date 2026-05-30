# CLEANLAB UI Design System v1.0

This package turns the CLEANLAB visual direction into reusable implementation artifacts.

## Philosophy

CLEANLAB should feel like Apple Vision Pro meets industrial laboratory software: premium, minimal, technical, high-end, and believable as a professional instrument interface.

The laboratory is the hero. UI frames it; UI does not compete with it.

## Godot Assets

- `scripts/ui/design/CleanLabTokens.gd`
  - Color, spacing, typography, radius, and layout constants.
- `scripts/ui/design/CleanLabTheme.gd`
  - Runtime `Theme` and `StyleBoxFlat` factory for panels, buttons, nav, progress bars, and station states.
- `scripts/ui/components/CleanLabGlassPanel.gd`
  - Reusable glass/solid panel container.
- `scripts/ui/components/CleanLabButton.gd`
  - Reusable nav/action button with selected and hover styling.
- `scripts/ui/components/CleanLabStatBlock.gd`
  - Top status bar stat block.
- `scripts/ui/components/CleanLabStationBadge.gd`
  - Floating station label with idle, processing, completed, and problem states.

## External Design Assets

- `docs/design/tokens.json`
  - Design-token source for Figma, web, or code generation.
- `docs/design/cleanlab_styles.css`
  - CSS-like reference style system.
- `docs/design/figma_layout_spec.md`
  - 1920 x 1080 frame layout and component placement spec.
- `docs/design/image_generation_prompts.md`
  - Prompts for lab backgrounds, thumbnails, truck art, and microscope filters.

## Core Layout

- Target: 1920 x 1080
- Grid: 12 columns
- Safe margin: 40 px
- Spacing: 4, 8, 16, 24, 32, 48, 64 only
- Main lab view: 65-70 percent of the screen width
- Bottom navigation: 90 px
- Top status bar: 80 px

## State Language

Station badges use only four states:

- Idle: muted border, disabled text
- Processing: cyan border, visible progress
- Completed: green border, ready-to-collect text
- Problem: amber border, revision/QC required

## Motion

Use subtle motion only:

- Button hover: 150 ms
- Selection: 200 ms
- Panel open: 250 ms
- Station completion pulse: 500 ms

Avoid bounce, exaggerated scaling, cartoon easing, and visual noise.

## Quality Gate

Before adding any new visual element, ask:

Would this look believable on a EUR 500,000 laboratory software system?

If not, remove complexity.
