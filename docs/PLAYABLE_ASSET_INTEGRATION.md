# Player-Ready Asset Integration

Use this playbook when project-bound 2D art must move from look-dev into a verified Godot runtime. It reflects the Codex Game Maker 1.0 contracts; it is not a postmortem for an older showcase.

## Source Of Truth

Read and keep current:

- `design/art/art-bible.md`
- `design/art/style-lock.json`
- `production/session-state/active.md`
- `design/assets/asset-coverage.json`
- `design/assets/asset-manifest.yaml`
- `design/assets/godot-import-manifest.yaml`
- `design/game-state-matrix.json`
- `design/ui/ui-ux-spec.md`
- `production/reviews/visual-quality-contract.json`

The state graph, system GDDs and target devices determine the asset inventory. Do not copy a universal character/environment/UI count into every game.

## Production Loop

1. Define the game-specific visual identity and every required asset family.
2. Produce multiple look-dev candidates for generated or mixed art.
3. Compare candidates together in a runtime composite at actual display scale.
4. Record accepted and rejected directions, then seal `design/art/style-lock.json`.
5. Verify the style lock before every production generation batch.
6. Create family-aware prompt specs with camera, scale, palette, lighting, material and silhouette anchors.
7. Generate or source raw assets and record provenance and commercial-use rights.
8. Process transparency, slicing, alignment and animation frames without destroying the raw source.
9. Run structural media, harness and asset QA.
10. Import only accepted assets and record real `res://` targets.
11. Integrate them into actual states and gameplay scenes.
12. Capture current runtime composites at every declared target viewport.
13. Resolve visual blockers and high-severity findings, then recapture.
14. Update coverage, manifest, session state and player-ready evidence.

## Runtime Presentation Contract

Every required asset records:

- A stable asset ID and family/category.
- Lifecycle status: `planned -> draft -> accepted -> integrated -> verified`.
- Project-local path and provenance record.
- One or more real runtime references.
- Style-lock version and digest.
- Source kind and presentation usages.
- State ID, render mode, rendered size and rationale for each usage.
- Current runtime composite evidence.

Preserve aspect ratio for sprites, icons and other fixed-shape sources. Use cover crop only with a declared crop-safe area. Use tiled art only when seam evidence proves it was authored as tileable. Use sprite frames only with the declared source-frame dimensions and verified pivot/anchor behavior.

## UI Materials

- Build panels and buttons as dedicated component families.
- Use `NinePatchRect` only with verified margins and tested minimum/maximum sizes.
- Never stretch a random prop crop into a scalable panel.
- Keep live text inside a protected content rectangle; do not bake final labels into generated art.
- Test longest localized copy, font fallback, focus, disabled/pressed/selected states and input-device prompts.
- Reject generic dashboard cards, default gray controls, plastic bevels and one ornate frame reused for every hierarchy level.

## Sprite And VFX Checks

- Validate frame count, alpha, chroma-key residue, neighboring-frame fragments and edge contact.
- Keep runtime scale, grounding and pivot consistent across every animation.
- Default no-input state must be visually valid.
- Movement must not scale-pop or slide because frames use inconsistent bounds.
- Jump or phase-based actions use authored phases rather than a blind loop.
- VFX must remain readable at peak combat density and preserve enemy telegraphs.
- Evolved skill tiers change a readable silhouette or behavior; brightness and particle count alone are insufficient.

## Map And Level Checks

- Separate gameplay objects from decorative reference art.
- Record placement, collision, zones, exits, camera bounds and traversal anchors.
- Validate grounding on both small and large surfaces when applicable.
- Repeated pickups and interactables use stable groups/metadata rather than duplicate node names.
- Collision and debug shapes never appear in production captures.
- A baked background cannot substitute for editable runtime data when gameplay needs separate objects.

## Verification

Run the project-owned asset commands, then the cross-platform player-ready gate:

```bash
python3 plugins/codex-game-maker/scripts/cgm.py style-lock verify --root /path/to/game
python3 plugins/codex-game-maker/scripts/cgm.py quality --root /path/to/game
python3 plugins/codex-game-maker/scripts/cgm.py player-ready --root /path/to/game
```

PowerShell asset detail checks remain available when PowerShell is installed:

```powershell
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\check-asset-qa.ps1 -Root /path/to/game
```

File presence or a self-authored `PASS` is not final evidence. Player-ready requires valid current media, hash-bound capture commands, complete required-state coverage, runtime integration and a human or clean-context independent visual review with no unresolved blocker/high finding.
