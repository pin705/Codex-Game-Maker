# Active Session State: Vân Mộng Tu Tiên

Updated: 2026-07-30
Current phase: V3 authored UI/portrait batch passes clean parse, native desktop/844×390 capture and served Chromium checks; independent visual review plus cross-browser/manual/physical-device gates remain open

## Current implemented scope — not a readiness claim

- Godot project feature baseline 4.4, verified with supported Godot 4.6.2 at logical 1600x900 using the Compatibility renderer.
- Full loop: Title → Hub → Stage Select → Loadout → Combat → Results → Hub.
- Persistent/migrated JSON profile with currency, stage records, unlocks, permanent techniques, bestiary, achievements and settings.
- Three authored stage environments: Vân Mộng Cốc, Huyết Vân Đài, Thiên Môn Tàn Cảnh.
- Three disciplines and three permanent technique tracks; selected modifiers are applied immediately before combat.
- Raster-backed UI across front end, combat HUD, breakthrough cards and modals. UIKIT-006 supplies arsenal inventory material and icon framing; UIKIT-007 supplies title/header, guarded modal/result surfaces, raised skill rail, touch medallions and the live boss bar; UIKIT-008 supplies distinct primary/secondary/back/stepper/destructive/confirm silhouettes. UIKIT-005 and the active UIKIT-002 scroll/talisman components remain transitional support; procedural drawing owns feedback/fallback.
- Project-local typography is source-wired: Be Vietnam Pro Regular for body/HUD text, Be Vietnam Pro SemiBold for controls/emphasis, and Literata variable roman for large ritual headings. All copy remains dynamic Godot text.
- Procedural 32-second ambient score variants plus event-driven SFX, Music/SFX buses and functional volume controls.
- Keyboard/mouse and controller navigation, visible focus, 64 px phone interaction-target floor, reduced motion and screen-shake settings.
- V3 arsenal direction is locked from the user-approved look-dev reference. UIICON-001 supplies twelve relic silhouettes, SKILLICON-001 supplies the five-skill/companion glyph family, PORTRAIT-001/002 supply bestiary/companion/player/boss identity art and ACHIEVEICON-001 supplies six distinct milestone seals; chrome, rarity, cooldown and copy remain runtime-rendered.

## Verification state

- Current post-edit checks pass on Godot 4.6.2: clean editor import/parse, `smoke_runtime`, `smoke_mobile_support` and `smoke_responsive_layout`; the earlier full flow/audio/long-run passes remain baseline evidence and should be rerun before release gating.
- Title and boss desktop/phone native captures were refreshed after the final protected-title and phone boss-position fixes. Existing current V3 front-end/combat captures bind the new portraits, seals and controls; a clean-context reviewer has not accepted the full matrix yet.
- UIKIT-007 provenance is recorded at `assets/source-prompts/UIKIT-007-ritual-surface-atlas.yaml`; raw SHA-256 is `302172f890f74428fce745a103839cf52ce867e61b6497b2eecba2a8acd82c2a`, and processed/runtime SHA-256 is `02f7a634a8857745c0cb2b3aa1195ff06596a05c0dc0bcdeea5922dfb729828c`.
- Be Vietnam Pro Regular/SemiBold and Literata variable hashes match their recorded official Google Fonts raw downloads; both OFL 1.1 license files are bundled under `assets/fonts/`.
- Godot import artifacts exist for UIKIT-007/008, PORTRAIT-001/002, ACHIEVEICON-001 and all three fonts. `boss_bar` is runtime-bound in `scripts/gameplay/enemy.gd`; `status_plaque` remains deliberately reserved/unbound.
- Web export was rebuilt on 2026-07-30 and served from `http://localhost:8765/`. In-app Chromium checks at exact 1600×900 and 844×390 confirm canvas focus, Title → Hub navigation, the phone `THOÁT` label and zero console warnings/errors.
- The V3 identity version/digest remain `3.0.0` / `0d1b060efbb561c8625b13cd07912a49808ec704ce1d0db8ebf616d231d109da`. This metadata/art-bible batch intentionally does not reseal `design/art/style-lock.json`; because the art bible changed, its stored art-bible hash is expected to remain stale until the full migration and refreshed captures are accepted.
- Current additive art-bible SHA-256 is `adb4c66b770941446061c202091f97cca1f78212457782baf9107b1fd99f81d2`; the sealed lock binding remains `2ae2550201bd145ffa4972d96738fd8b90ef21e582f014e66623bf277ff7f2b1` until that deferred reseal.

## Immediate validation state

- The configured Godot binary is present at `/Users/bon/Library/Caches/CodexGameMaker/godot/bin/godot` and reports `4.6.2.stable.official.71f334935`.
- `.godot/imported` contains the three FontFile resources and current V3 runtime textures; the clean parse and runtime/mobile/responsive smokes pass.
- Current final-fix evidence: `production/playtests/frontend/title.png`, `title-phone.png`, `production/playtests/overhaul/boss-final.png`, and `production/playtests/mobile-support/boss-phone.png`.
- The PowerShell asset-QA wrapper could not run because `pwsh` is unavailable on this host; source/processed/runtime files, metadata, import paths, hashes and current composites were checked directly. This remains a tooling warning, not an asset acceptance claim.

## Remaining release gates

- Refresh the full declared desktop/844×390 capture matrix only when starting the independent visual gate; title and boss final-fix captures are already current.
- Obtain a clean-context independent visual verdict before resealing the V3 style lock or changing readiness status.
- Firefox/Safari and human Web audio-unlock/output review remain pending; current Chromium smoke covers the refreshed export only.
- A physical-input four-minute run, boss-kill run and death/retry run still need human feel/balance sign-off.
- Physical iOS/Android notch, DPI, thumb-reach, sustained multitouch and thermal QA remain unverified.
- Human audio listening on target outputs remains unverified.
- Do not label the project player-ready, release-ready or commercial-ready until the required evidence checks pass.

## Important paths

- `scripts/meta/meta_profile.gd`
- `scripts/ui/frontend.gd`
- `scripts/ui/raster_button.gd`
- `scripts/ui/van_mong_component_kit.gd`
- `resources/ui/cultivation_theme.tres`
- `assets/generated/ui/UIKIT-007-ritual-surface-atlas/`
- `assets/source-prompts/UIKIT-007-ritual-surface-atlas.yaml`
- `assets/fonts/`
- `scripts/audio/audio_director.gd`
- `assets/generated/ui/UIKIT-005-restrained-controls/`
- `assets/generated/ui/UIKIT-002-xuan-ink-commercial/runtime/`
- `assets/source-prompts/UIKIT-005-restrained-controls.yaml`
- `assets/generated/environments/`
- `assets/generated/audio/`

## Next recommended step

Run the clean-context full-surface visual review against the current V3 captures, resolve any high/blocker findings and only then reseal the style lock. Firefox/Safari, physical mobile, human listening and the full four-minute feel/balance pass follow before any release-readiness claim.
