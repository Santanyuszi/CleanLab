# CLEANLAB Figma Layout Spec

Target frame: `Desktop / 1920 x 1080`

Grid:
- 12 columns
- Outer margin: 40 px
- Gutter: 24 px
- Spacing tokens only: 4, 8, 16, 24, 32, 48, 64

## Frame Structure

1. Root background
   - Fill: `#040B12`
   - Size: 1920 x 1080

2. Top status bar
   - X: 346
   - Y: 16
   - W: 944
   - H: 80
   - Radius: 16
   - Fill: `rgba(8,17,26,0.92)`
   - Stroke: `rgba(255,255,255,0.06)`, 1 px
   - Contains four 220 px stat blocks: LEVEL, XP, MONEY, REPUTATION

3. Logo block
   - X: 40
   - Y: 24
   - CLEAN: white, 64 px, weight 700
   - LAB: `#00D7D0`, 64 px, weight 700
   - Subtitle: 15 px, `#F7FAFC`

4. Left task panel
   - X: 40
   - Y: 128
   - W: 260
   - H: 270
   - Radius: 20
   - Fill: `rgba(8,17,26,0.92)`
   - Task card height: 70
   - Card spacing: 12

5. Laboratory viewport
   - X: 320
   - Y: 128
   - W: 1280
   - H: 720
   - Keep the OASIS lab image undistorted using center-crop cover.
   - Station labels float above real equipment, never over primary cabinetry details.

6. Right orders panel
   - X: 1624
   - Y: 128
   - W: 280
   - H: 520
   - Radius: 20
   - Order card: 140 h, radius 18

7. Shipping panel
   - X: 1624
   - Y: 672
   - W: 280
   - H: 300
   - SEND TRUCK button: 220 x 60, radius 14

8. Bottom navigation
   - X: 40
   - Y: 966
   - W: 1840
   - H: 90
   - Items: Lab, Samples, Upgrades, Staff, Shop
   - Button: 220 x 70, radius 18

## Component Rules

- The laboratory image is the hero. UI panels must frame it and leave it visually dominant.
- Use glass panels sparingly. Do not put cards inside cards unless the card is a repeated item.
- Buttons use precise 150 ms hover and pressed transitions. No bounce or oversized scaling.
- Station labels use four visual states only: idle, processing, completed, problem.
- The microscope revision overlay is full-screen, darkens the lab, and centers the particle filter.

## Export Notes

- Export lab background separately at 1536 x 1024 or larger.
- Export icons as SVG with 1.5 px strokes, then convert/import in Godot.
- Do not rasterize text in UI exports.
