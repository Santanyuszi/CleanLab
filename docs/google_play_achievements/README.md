# Google Play Achievements Import

Use `google_play_achievements_import.zip` in Play Console achievement import.

The ZIP contains:

- `AchievementsMetadata.csv`
- `AchievementsIconsMappings.csv`
- 72 final PNG icons, one per achievement/tier row.

The metadata defines 72 standard Play Games achievements:

- 18 CleanLab achievement families.
- 4 Play Games achievements per family: Bronze, Silver, Gold, Certified.
- Total XP value: 990 points.

Each Play Console icon is a final 512x512 PNG combining the tier badge frame and the achievement-specific inner symbol.

After importing, Play Console will generate Play Games achievement IDs. Copy those IDs into `play_console_id_mapping.csv`, then into `PlatformServices.GOOGLE_ACHIEVEMENT_IDS` using the matching `local_key`.

The import CSVs intentionally have no header row. Keep them that way for Play Console import.

`AchievementsLocalizations.csv` is intentionally not included in the ZIP because Play Console rejects localization rows that use the game's default locale. Add it later only for non-default languages enabled in Play Console.
