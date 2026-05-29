# Studio Skill Audit - 2026-05-29

## Skill Pack

Installed from `Claude-Code-Game-Studios-main` into the local agent skills folder:

- Art and assets: `art-bible`, `asset-audit`
- UI and UX: `team-ui`, `ux-review`
- Game content and balance: `content-audit`, `balance-check`, `map-systems`, `design-system`, `team-narrative`
- Engineering and QA: `architecture-review`, `tech-debt`, `qa-plan`, `regression-suite`, `smoke-check`, `vertical-slice`, `team-polish`

Codex may need a restart before these appear as first-class invocable skills, but their workflows are now available locally.

## Current Verdict

The project is past prototype and entering a vertical-slice cleanup phase.

Strengths:

- Core loop tests exist and currently pass.
- Design, UX, architecture, and economy documents already exist.
- The game has a clear management fantasy: grow a sect, train disciples, manage resources, compete with other sects.
- Recent AI art gives the project a stronger visual identity.

Main risks:

- Several large controllers are becoming feature hubs.
- Balance data is still mixed into autoload code instead of external data files.
- UI has strong visual direction but needs clearer operational dashboards.
- Runtime assets were carrying source/back-up files and oversized portraits.

## Content Audit

Implemented content highlights:

- Sect management: facilities, rank promotion, decrees, resources.
- Disciple system: attributes, spirit roots, cultivation, breakthrough, positions, memories.
- Alchemy and crafting: recipes, inventory output, breakthrough aid.
- Dungeon expeditions: dispatch, success checks, loot.
- World factions: NPC factions, annual growth, relation, combat power, rankings.
- Event system: random sect events, choice effects, cooldowns.

Gaps to close next:

- Faction personalities are numeric but not yet very readable in UI.
- World events are simulated but not surfaced as a persistent world news feed.
- Rank promotion conditions exist but are not presented as a clear goal ladder.
- Disciple relationships exist but need stronger player-facing consequences.

Recommended next content pass:

1. Add a "晋升目标" panel showing missing requirements for the next sect rank.
2. Add yearly world news from NPC faction actions.
3. Add faction traits such as "丹道名门", "剑修强宗", "魔道掠夺者" that affect AI and UI labels.

## UI / UX Audit

Recent improvements:

- AI background and scroll-style UI textures are loaded from external PNG.
- The "天下榜" now gives rankings and comparison bars.
- Sect overview shows a compact world ranking summary.

Remaining issues:

- The top bar is crowded because many feature buttons are added dynamically.
- Main overview is still a fixed three-column layout; it should adapt to more management data.
- Some panels duplicate helper UI code instead of sharing row/card components.
- Several views use text-heavy rows where icon + metric + progress state would scan better.

Recommended next UI pass:

1. Convert the top bar actions into grouped navigation tabs or an action menu.
2. Add a management dashboard strip: monthly income, upkeep, net balance, next rank gap, world rank.
3. Create shared UI helpers for metric rows, comparison bars, and section cards.

## Asset Audit

Actions already taken:

- Moved portrait source sheets/backups out of runtime texture folders:
  `assets/textures/portraits/_sources` -> `docs/art-sources/portraits`
- Resized runtime portrait pool images from 2048x2048 to 1024x1024.
- Re-encoded mislabeled PNG files that were actually JPEG data.

Remaining asset policy:

- Runtime portraits: max 1024x1024 PNG.
- UI buttons/decorations: keep under 512px on the long side unless used as a full-screen background.
- Source sheets and backups should stay under `docs/art-sources/`, not `assets/textures/`.

## Balance Check

Current observations:

- Initial economy is stable in automated tests.
- Spirit vein output starts useful and scales strongly.
- Maintenance and salaries exist, but insufficient-funds consequences are still soft.
- Breakthrough and pill aid are working, but long-term progression needs simulation across 50-100 years.

Balance risks:

- NPC faction growth is yearly and simple; it may not stay competitive against an optimized player.
- Spirit stone sinks may become too weak after the player stabilizes income.
- Rank promotion costs are present but not yet framed as planned milestones in the UI.

Recommended next balance tests:

1. Add a 30-year economy simulation test.
2. Add a 100-year world ranking simulation test.
3. Track monthly income/upkeep/net in a small history buffer for UI and balance reporting.

## Architecture / Tech Debt

Largest files:

- `event_controller.gd`: event data and event resolution are mixed together.
- `data_registry.gd`: static data lives in code and will become hard to balance.
- `disciple_detail_panel.gd`, `theme_manager.gd`, `diplomacy_panel.gd`: large UI scripts with repeated construction patterns.

Recommended refactors:

1. Move event definitions out of `event_controller.gd` into data files or smaller event modules.
2. Move ranking and economy formulas into core system calculators with tests.
3. Extract shared UI builders for cards, metric rows, and section headers.
4. Create data migration tests for save/load every time a new field is added.

## Next Implementation Slice

Recommended immediate slice:

1. Add a "宗门经营仪表盘" to the overview.
2. Show next-rank requirements and missing gaps.
3. Add a small world-news feed from NPC faction yearly actions.
4. Add simulation tests for 30-year economy and world-rank stability.

