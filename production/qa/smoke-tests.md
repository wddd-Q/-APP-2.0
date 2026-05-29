# Smoke Tests

Critical checks before pushing a build:

1. Core loop test scene passes: `res://tests/test_core_loop.tscn`
2. Cultivation test scene passes: `res://tests/test_cultivation.tscn`
3. Main scene starts for at least 5 seconds without script or asset loading errors.
4. External UI textures load instead of procedural fallbacks.
5. Portrait pool contains sequential `pool_01.png` through the latest pool image.
6. New game creates a sect with stable disciple IDs and memory entries.
7. The "天下榜" can build rankings including the player sect and alive NPC factions.
8. Save/load preserves disciple IDs, memories, inventory item IDs, and event cooldowns.

Current manual smoke command set:

```powershell
& "C:\Users\25811\Documents\New project\tools\godot\Godot_v4.6.3-stable_win64_console.exe" --headless --path "C:\Users\25811\Documents\New project\xiuxian-sect-sim" "res://tests/test_core_loop.tscn"
& "C:\Users\25811\Documents\New project\tools\godot\Godot_v4.6.3-stable_win64_console.exe" --headless --path "C:\Users\25811\Documents\New project\xiuxian-sect-sim" "res://tests/test_cultivation.tscn"
& "C:\Users\25811\Documents\New project\tools\godot\Godot_v4.6.3-stable_win64_console.exe" --headless --path "C:\Users\25811\Documents\New project\xiuxian-sect-sim" --quit-after 5
```
