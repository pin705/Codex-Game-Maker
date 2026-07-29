---
name: game-studio-localization
description: "Implement and verify game localization. Use for string extraction, translation catalogs, locale fallback, plural/gender rules, fonts and glyph coverage, RTL/CJK behavior, pseudo-localization, UI expansion, subtitles, localized assets, store metadata, linguistic QA, and per-language runtime captures."
---

# Game Studio Localization

Treat every supported language as a tested build surface.

## Required Output

Create `design/localization/localization-manifest.json` from `../../references/templates/localization-manifest.json`.

## Workflow

1. Externalize all player-facing strings with stable IDs; prohibit final hard-coded UI/dialogue strings.
2. Define source locale, supported locales, fallback, ownership, glossary, tone, variables, plural/gender rules, and content-update process.
3. Select fonts with verified licenses and glyph coverage. Define fallback chains and shaping/RTL behavior.
4. Run pseudo-localization before translation to expose concatenation, clipping, fixed-width controls, and missing IDs.
5. Import translations without breaking variables or markup. Validate dialogue, subtitles, tutorials, settings, errors, and store assets.
6. Capture every localized `ui_surface` declared by this game's state graph, plus the busiest text surface, dynamic variables, and long-string cases for every release locale.
7. Require linguistic review by a qualified human for public commercial languages.

Missing translations, tofu glyphs, clipped critical text, broken variables, unsupported RTL, untranslated store claims, or absent linguistic approval block that locale from release.
