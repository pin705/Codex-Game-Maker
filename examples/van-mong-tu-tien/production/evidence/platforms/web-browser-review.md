# Served Web smoke review — Vân Mộng Tu Tiên

Date: 2026-07-31
Build: Godot 4.6.2 Compatibility, single-thread Web export  
Artifact: `build/web/index.html` (SHA-256 `a36e45fe94fa07d62f98f45f0fa3869a3bba846ab56a2b3abbbdcd28e5d9205d`)

## Evidence

- Export command: Godot 4.6.2 `--export-release Web build/web/index.html`; output and template/export diagnostics: `production/evidence/platforms/export.log`.
- Reproducible browser command: `npm run test:web` (`tests/web_smoke.spec.js`, Playwright 1.62.0).
- Structured result: `production/evidence/platforms/web-smoke.json`.
- Chromium captures: `web-title.png`, `web-hub.png`, `web-stages.png`, `web-title-phone.png`, `web-hub-phone.png`.
- Browser visual/input pass: the served desktop canvas booted, the primary pointer action entered Hub, `HÀNH TRÌNH` opened the sequential route screen, and `Escape` returned to Hub. Browser console/page/network error queries returned an empty list.

## Checks

| Check | Result |
|---|---|
| WebAssembly/WebGL canvas boot | PASS |
| Desktop 1600×900 render | PASS |
| Enter/title → Hub | PASS |
| Pointer Hub → Stage Select | PASS |
| Escape Stage Select → Hub | PASS |
| 844×390 landscape resize/input path in Chromium | PASS |
| Console/page/network errors in Playwright run | PASS (none) |

The in-app browser's ambient mobile emulation exposed a 430×932 portrait CSS viewport during a later phone interaction; the game correctly displayed its portrait rotation guard. That is a browser-environment observation, not physical iOS/Android evidence. Physical devices, Safari/Firefox, sustained input, audio output and thermal behavior remain outside this local smoke pass.

## Verdict

Web candidate smoke: **PASS**. This does not upgrade the project to PLAYER_READY or commercial-release-ready; the independent visual sign-off, human audio listening, manual four-minute playtest and physical-device QA remain separate gates.
