extends Node
## 全局事件总线 — 解耦各系统间的通信

const CombatResult = preload("res://src/core/data/combat_result.gd")


## 游戏生命周期
signal game_started
signal game_loaded
signal game_saved

## 时间信号
signal month_passed(month: int, year: int)
signal year_passed(year: int)

## 弟子信号
signal disciple_recruited(disciple_id: String)
signal disciple_died(disciple_id: String, cause: String)
signal disciple_broken_through(disciple_id: String, realm: int, sub_realm: int)
signal disciple_tribulation_passed(disciple_id: String)
signal disciple_tribulation_failed(disciple_id: String)
signal disciple_task_assigned(disciple_id: String, task_id: String)

## 宗门信号
signal sect_rank_changed(old_rank: int, new_rank: int)
signal facility_built(facility_type: String, level: int)
signal facility_upgraded(facility_type: String, new_level: int)

## 资源信号
signal spirit_stones_changed(new_amount: int, delta: int)
signal resource_changed(resource_type: String, resource_id: String, new_amount: int)
signal herb_changed(herb_id: String, new_amount: int)
signal ore_changed(ore_id: String, new_amount: int)

## 生产信号
signal pill_crafted(pill_id: String, quality: int, alchemist_id: String)
signal equipment_forged(equipment_id: String, quality: int, crafter_id: String)

## 事件信号
signal random_event_triggered(event_id: String)
signal event_choice_made(event_id: String, choice: int)
signal event_ledger_changed

## 外交信号
signal faction_relation_changed(faction_id: String, old_value: int, new_value: int)
signal war_declared(attacker_id: String, defender_id: String)

## 副本信号
signal dungeon_discovered(dungeon_id: String)
signal dungeon_expedition_started(dungeon_id: String, disciple_ids: Array)
signal dungeon_expedition_finished(dungeon_id: String, success: bool, loot: Dictionary)

## 职位信号
signal position_changed(disciple_id: String, old_pos: String, new_pos: String)

## 背景故事信号
signal lore_unlocked(entry_id: String)

## 前期目标信号
signal onboarding_changed

## 战斗信号
signal combat_finished(result: CombatResult)
