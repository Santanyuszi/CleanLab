# Android / Google Play release readiness

This project is configured to keep Android release preparation repository-safe (no committed secrets).

## Versioning

- Project version: `project.godot` → `config/version`
- Android export version: `export_presets.cfg` → `version/name`, `version/code`
- Keep `config/version` and `version/name` synchronized.
- Increment `version/code` for every Play Console upload.

## Signing (without committing secrets)

Use one of these approaches:

1. Godot editor export dialog (recommended for local-only secrets), or
2. External credentials file (`export_credentials.cfg`) kept out of git.

`.gitignore` already excludes:

- `export_credentials.cfg`

Required Android release fields in `export_presets.cfg`:

- `keystore/release`
- `keystore/release_user`
- `keystore/release_password`

## Launcher/adaptive icons

Android launcher icon fields are intentionally left blank in `export_presets.cfg` until final production assets are provided:

- `launcher_icons/main_192x192`
- `launcher_icons/adaptive_foreground_432x432`
- `launcher_icons/adaptive_background_432x432`

Missing final assets:

- A square launcher icon image suitable for Play (`192x192` source minimum).
- Adaptive icon foreground art (`432x432` source).
- Adaptive icon background art (`432x432` source).

## Google Play Games readiness

Play Games UI and calls are now gated behind runtime readiness checks.

For Play Games to become active, both must be true:

1. Android plugin singleton `GooglePlayGames` is available and exposes required methods.
2. All entries in `GOOGLE_ACHIEVEMENT_IDS` inside `scripts/autoload/PlatformServices.gd` are filled with real Play Console IDs.

If either is missing, Play Games controls stay hidden/disabled and local achievements continue to work normally.
