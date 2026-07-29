---
name: game-studio-performance
description: "Measure and optimize game performance and reliability for release. Use for FPS/frame-time budgets, CPU/GPU/memory profiling, load times, shader stutter, asset size, Web memory, mobile thermal behavior, device matrices, soak tests, crash-free sessions, load testing, leaks, and performance regression evidence."
---

# Game Studio Performance

Replace subjective “runs fine” claims with budgets measured on declared target devices.

## Required Outputs

- `production/performance-budget.json` from `../../references/templates/performance-budget.json`
- captures, profiler exports, and reports under `production/evidence/performance/`

## Workflow

1. Define per-platform budgets for frame time/FPS, memory, startup, scene transition, package/download size, long-run stability, and online latency when applicable.
2. Create repeatable idle, normal, busiest-case, loading, restart, and soak scenarios.
3. Profile before optimizing. Attribute costs to scripts, rendering, physics, audio, allocation, assets, shaders, and services.
4. Test minimum, representative, and high-end devices plus supported browser/OS combinations.
5. Record median and worst-case values, sample duration, build hash, device, OS, renderer, and measurement tool.
6. Add a target-specific `measurement_command_id` to the quality manifest. Its passing result must hash at least one artifact also listed in the target's performance evidence; a manually typed budget table alone cannot pass.
7. Add regression commands to CI where deterministic measurement is possible.

Commercial release blocks on missing target-device results, budget violations, repeatable crashes, unbounded memory growth, severe stutter, or unexplained measurement gaps. Waivers require a named owner, rationale, player impact, and expiry.
