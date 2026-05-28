class_name CombatResult
extends Resource
## 战斗结果数据模型


@export var attacker_id: String = ""
@export var defender_id: String = ""
@export var attacker_power: int = 0
@export var defender_power: int = 0
@export var power_ratio: float = 0.0
@export var attacker_won: bool = false
@export var attacker_losses: int = 0  # 伤亡弟子数
@export var defender_losses: int = 0
@export var attacker_dead: Array[String] = []  # 阵亡弟子ID
@export var defender_dead: Array[String] = []
@export var loot_spirit_stones: int = 0  # 战利品
@export var territory_transfer: String = ""  # 割让的灵脉ID
@export var battle_description: String = ""
