# Web Search Policy

Use web search aggressively when current external reality matters.

## Must Search

- User says generated art/assets are unsatisfactory, generic, not fun, or off-style.
- The asset list is large enough that online references, public-domain resources, or official marketplaces could save time.
- Engine version, API, export workflow, renderer behavior, plugin compatibility, or build errors may be newer than local knowledge.
- The user references a specific engine version, plugin, bug, error message, tutorial, marketplace asset, or official page.
- Legal/licensing/source provenance matters for assets.

## Source Priority

Engine/API:
1. Official docs
2. Official GitHub/release notes
3. Maintainer docs
4. High-quality community posts only after primary sources

Assets/references:
1. Official asset libraries or marketplaces
2. CC0/public-domain sources
3. Creator pages with explicit license
4. Inspiration references from official game pages, not copied assets

## Output Requirement

When web search affects a decision, cite the source URL in the relevant doc or response. For asset sourcing, record URLs in `assets/source-prompts/<asset-id>.yaml` or the asset manifest notes.
