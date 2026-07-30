# Commercial Visual + Mobile Rebuild Review

Date: 2026-07-29  
Engine: Godot 4.4.stable  
Gate: **PASS_WITH_DEVICE_QA_REQUIRED**

## Rejected baseline

The former baseline is explicitly rejected: repeated `UIKIT-002/003` ornate nine-slice frames, stretched clasps/corners, oversized paper cards, fixed 1600×900 composition and number-only permanent upgrades were not commercial quality.

## Replacement

- Hub/header/navigation rebuilt as a restrained cinematic command surface with stable geometry and clear 8/16/24/32 spacing.
- Every meta screen remains available: Title, Hub, Stages, Loadout, Techniques, Codex, Achievements, Settings, Results and guarded reset.
- `PREMIUM-001` supplies standalone sword, jade-shell and qi-vortex sigils. They have transparent safe margins and remain readable at 40 px.
- Permanent-technique screen has a live rank silhouette preview and a full ascension beat after purchase.
- Breakthrough cards use standalone sigils and dark cultivation wells instead of talisman templates.
- Combat VFX is rank-aware and integrated with attack, hit and pickup events.
- Combat HUD no longer stretches authored ornamental frames across unrelated aspect ratios.

## Mobile/responsive

- Landscape multi-touch: independent joystick finger plus pulse finger, pause dispatch and release safety.
- Minimum control target: 64 px.
- Device cutout safe area intersects a conservative 90% title-safe region.
- Portrait is blocked by a polished rotate-device overlay.
- Stretch mode is `expand`; arena dimensions follow the viewport.
- 16:9 environment plates use centered cover-cropping rather than non-uniform stretching.
- Fixed 1600×900 menu composition centers inside 18:9–21:9; small 16:9 layouts scale uniformly.
- HUD objective/cooldown plaques reserve both lower thumb zones.

## Automated evidence

- `smoke_runtime`: full integration, including mobile lifecycle and live VFX triggers.
- `smoke_mobile_support`: multi-touch, InputMap dispatch, 64 px targets, asymmetric notch bounds, portrait guard and lifecycle.
- `smoke_cultivation_vfx`: 20 assertions across all three rank paths, reduced motion and particle/transient budgets.
- `smoke_responsive_layout`: source cropping, 21:9 menu centering, 1280×720 scaling, health-preserving bounds updates and stretch configuration.
- Existing profile/frontend/audio/long-run suites remain mandatory release regressions.

Visual evidence:

- `production/playtests/frontend/hub.png`
- `production/playtests/frontend/techniques.png`
- `production/playtests/frontend/technique-upgrade.png`
- `production/playtests/overhaul/gameplay-final.png`
- `production/playtests/overhaul/upgrade-final.png`
- `production/playtests/mobile-support/landscape-controls.png`
- `production/playtests/mobile-support/portrait-overlay.png`
- `production/playtests/responsive/hub-wide.png`
- `production/playtests/responsive/combat-wide-touch.png`

## Remaining release gates

- Physical iOS/Android notch, DPI, thermals and thumb-reach playtest.
- Full four-minute hands-on tuning/performance sessions.
- Web export and served-browser input after Godot 4.4 Web templates are installed.
- Store/legal/localization/performance packaging outside this vertical slice.
