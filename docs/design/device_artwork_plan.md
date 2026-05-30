# CLEANLAB Device Artwork Plan

The empty lab background is intentionally equipment-light. Runtime station art should sit on top of the lab background and change with ownership and upgrade level.

## Device Order

Left to right in the laboratory:

1. Extraction Machine
2. Drying Oven
3. Microscope

## Runtime Data

Device state lives in `GameManager`:

- `device_owned`
- `device_levels`
- `DEVICE_CATALOG`
- `purchase_device(device_key)`
- `upgrade_device(device_key)`

Current device keys:

- `extraction`
- `drying`
- `microscope`

## Artwork Strategy

Current implementation uses `DeviceArtwork.gd` as procedural placeholder art.

Final art should be exported as transparent PNG or WebP assets with this naming convention:

```text
assets/devices/extraction_level_1.png
assets/devices/extraction_level_2.png
assets/devices/extraction_level_3.png
assets/devices/extraction_level_4.png

assets/devices/drying_level_1.png
assets/devices/drying_level_2.png
assets/devices/drying_level_3.png
assets/devices/drying_level_4.png

assets/devices/microscope_level_1.png
assets/devices/microscope_level_2.png
assets/devices/microscope_level_3.png
assets/devices/microscope_level_4.png
```

## Level Differences

Level 1:
- Compact, basic model
- Minimal teal accents
- Small footprint

Level 2:
- Slightly larger
- More panels and handles
- Extra indicator lights

Level 3:
- Premium module
- Wider housing
- More glass/inspection surfaces

Level 4:
- Flagship instrument
- Larger, cleaner silhouette
- Strongest teal accents
- Most polished scientific look

## Image Generation Prompt Template

```text
Transparent-background product render of a [DEVICE NAME] for a premium technical cleanliness laboratory simulator, level [1-4] upgrade tier, white industrial laboratory equipment, teal accent handles, realistic cleanroom materials, front-facing slight 3/4 view, consistent lighting, no people, no background, no text labels, believable high-end scientific instrument, clean geometry, not cartoon
```

Negative prompt:

```text
cartoon, toy, messy, dirty, people, background, text, logo, exaggerated perspective, fantasy, low quality, blurry, warped geometry
```
