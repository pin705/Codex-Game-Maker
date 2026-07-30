# Active Session State: Vân Mộng Tu Tiên

Updated: 2026-07-29  
Current phase: commercial-oriented full vertical slice implemented; Godot 4.6.2 native QA passed; independent visual review in progress; Web/manual/physical-device gates pending

## Player-ready scope now implemented

- Godot project feature baseline 4.4, verified with supported Godot 4.6.2 at logical 1600x900 using the Compatibility renderer.
- Full loop: Title → Hub → Stage Select → Loadout → Combat → Results → Hub.
- Persistent/migrated JSON profile with currency, stage records, unlocks, permanent techniques, bestiary, achievements and settings.
- Three authored stage environments: Vân Mộng Cốc, Huyết Vân Đài, Thiên Môn Tàn Cảnh.
- Three disciplines and three permanent technique tracks; selected modifiers are applied immediately before combat.
- Raster-backed UI across front end, combat HUD, breakthrough cards and modals: UIKIT-005 supplies matte lacquer/command controls, UIKIT-002 retains only scroll/talisman surfaces, and procedural drawing owns compact controls plus feedback/fallback.
- Procedural 32-second ambient score variants plus event-driven SFX, Music/SFX buses and functional volume controls.
- Keyboard/mouse and controller navigation, visible focus, 64 px phone interaction-target floor, reduced motion and screen-shake settings.

## Verification

- `tests/smoke_meta_profile.tscn`: PASS.
- `tests/smoke_runtime.tscn`: PASS.
- `tests/smoke_frontend_flow.tscn`: PASS, including reward/unlock and three consecutive hub reloads.
- `tests/smoke_audio.tscn`: PASS, non-silent PCM, loop and buses.
- `tests/smoke_long_run.tscn`: PASS, boss timed event and living-enemy pressure.
- Nine front-end captures: `production/playtests/frontend/`.
- Combat/upgrade/pause/result captures: `production/playtests/overhaul/`.
- Native project boot/import on Godot 4.6.2: PASS. All 13 shell-free quality commands PASS for project fingerprint `740e418cd08d2d68a753c5dc91e0fd05bc9c8f96d6f5c1b9c9c94cf1eddecd3f`.
- Style lock 2.0.0 is sealed and verified at digest `0c5290bf863761218e7a7a0e995c18cf07409a4137907ae34a350a72d179ac9c`.

## Remaining release gates

- Godot 4.6.2 Web export and served Chromium smoke are recorded under `production/evidence/platforms/`; Firefox/Safari matrix and human audio-unlock/output review remain pending.
- A physical-input four-minute run, boss-kill run and death/retry run still need human feel/balance sign-off.
- Physical iOS/Android notch, DPI, thumb-reach, sustained multitouch and thermal QA remain unverified.
- Human audio listening on target outputs remains unverified.
- Do not label the project player-ready, release-ready or commercial-ready until the required evidence checks pass.

## Important paths

- `scripts/meta/meta_profile.gd`
- `scripts/ui/frontend.gd`
- `scripts/ui/raster_button.gd`
- `scripts/audio/audio_director.gd`
- `assets/generated/ui/UIKIT-005-restrained-controls/`
- `assets/generated/ui/UIKIT-002-xuan-ink-commercial/runtime/`
- `assets/source-prompts/UIKIT-005-restrained-controls.yaml`
- `assets/generated/environments/`
- `assets/generated/audio/`

## Next recommended step

Record the final independent visual verdict, then produce and serve a Godot 4.6.2 Web build for browser focus/input/audio checks; follow with physical mobile QA, human listening and one uninterrupted four-minute manual balance pass.
