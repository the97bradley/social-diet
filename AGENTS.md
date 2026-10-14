# Agent skills

Slim always-on wiring. Do not load full `SKILL.md` files on boot.

- **Ponytail** (default: full) — `.cursor/rules/ponytail.mdc`. Off only if the human says `stop ponytail` or `normal mode`. On demand: `ponytail-help`, `ponytail-review`, `ponytail-audit`, `ponytail-debt`, `ponytail-gain`.
- **MemPalace + mempalace-recall** — `.cursor/rules/mempalace-recall.mdc`. Search the palace before answering about past work, people, or decisions. Setup: `.agents/skills/mempalace/SKILL.md`. Full recall protocol: `.agents/skills/mempalace-recall/SKILL.md`.
- **Hallmark** (UI only) — `.cursor/rules/hallmark.mdc`. Load `.agents/skills/hallmark/SKILL.md` only when designing or auditing a page.
- **Graphify** (query before grep) — `.cursor/rules/graphify.mdc`. Full skill: `.agents/skills/graphify/SKILL.md`.

This repo is a Flutter + Supabase app (`app/` + `supabase/`). Do not install caveman, cavecrew, omni-*, or cli-* OmniRoute dumps.
