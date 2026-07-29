# Codex Game Maker Evaluation

The stable-release evidence lives here instead of in self-authored marketing claims.

Run the deterministic corpus validator:

```bash
python3 evals/run_eval.py validate
```

Score one completed clean-task run:

```bash
python3 evals/run_eval.py score evals/results/<run>.json
```

Aggregate the release corpus:

```bash
python3 evals/run_eval.py aggregate evals/results
```

Each benchmark case requires at least three `plugin-current` runs, at least one baseline run, a blind comparison for every current run, no blocker/high false pass, routing precision/recall of at least 0.9, an overall score of at least 80, and no dimension below 70 percent. Complete runs must name hashed artifacts. Keep generated projects and large media in release artifacts or Git LFS, but commit the brief, run metadata, hashes, score, reviewer independence, and compact golden evidence.

`validate` proves only that the corpus and schemas are internally valid. `aggregate` is the empirical quality gate and must remain `BLOCKED` until real current, baseline, and blind-review runs satisfy the thresholds. Never seed synthetic PASS results to release a version.
