class_name FactionData
extends Resource
## NPC宗门数据模型（用于外交和世界模拟）


@export var faction_name: String = ""
@export var faction_rank: int = 9  # 宗门品级
@export var faction_realm: int = 1  # 宗主最高境界
@export var prestige: int = 0
@export var spirit_stones: int = 100
@export var combat_power: int = 0  # 缓存战力值
@export var karma: int = 0  # 业力
@export var aggression: int = 50
@export var diplomacy: int = 50
@export var development_priority: int = 50
@export var loyalty: int = 50
@export var relation_to_player: int = 0  # -100 to 100
@export var home_region: String = ""  # 宗门所在区域ID
@export var is_alive: bool = true
@export var controlled_veins: Array = []  # 控制的灵脉ID
@export var disciples: Array = []  # NPC弟子 [{name, realm, sub_realm, bone, comp, ...}]
