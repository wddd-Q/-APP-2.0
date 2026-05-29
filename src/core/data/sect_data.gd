class_name SectData
extends Resource
## 宗门数据模型 — 纯数据层，不发射信号


## 基本
@export var name: String = "未命名宗门"
@export var rank: int = 9  # 1-9品（9品最低，1品最高，0=超品）
@export var prestige: int = 0
@export var karma: int = 0  # 正>0，魔<0

## 货币
@export var spirit_stones: int = 50

## 二级资源
@export var herbs: Dictionary = {}  # {herb_id: quantity}
@export var ores: Dictionary = {}   # {ore_id: quantity}
@export var beast_materials: Dictionary = {}  # {material_id: quantity}
@export var rare_materials: Dictionary = {}    # {material_id: quantity}

## 实体
@export var facilities: Array = []
@export var disciples: Array = []
@export var inventory: Array = []
@export var pill_recipes: Array = []
@export var craft_recipes: Array = []
@export var faction_relations: Dictionary = {}  # {faction_id: relation_value}

## 门规
@export var active_decrees: Array[String] = []
@export var next_disciple_serial: int = 1


func assign_disciple_id(disciple: Resource) -> void:
	if not disciple or disciple.disciple_id != "":
		return
	disciple.disciple_id = "disciple_%04d" % next_disciple_serial
	next_disciple_serial += 1


func ensure_disciple_ids() -> void:
	for disciple in disciples:
		assign_disciple_id(disciple)
		if disciple.disciple_id.begins_with("disciple_"):
			var serial = int(disciple.disciple_id.substr("disciple_".length()))
			next_disciple_serial = maxi(next_disciple_serial, serial + 1)


func get_disciple_by_id(disciple_id: String) -> Resource:
	for disciple in disciples:
		if disciple.disciple_id == disciple_id:
			return disciple
	return null


func add_disciple(disciple: Resource) -> void:
	assign_disciple_id(disciple)
	disciples.append(disciple)


func add_inventory_item(item_id: String, item_name: String, item_type: int, quality: int, quantity: int = 1, effects: Dictionary = {}) -> void:
	for item in inventory:
		if item.item_id == item_id and item.quality == quality:
			item.quantity += quantity
			return

	var item_data = load("res://src/core/data/item_data.gd").new()
	item_data.item_id = item_id
	item_data.item_name = item_name
	item_data.item_type = item_type
	item_data.quality = quality
	item_data.quantity = quantity
	item_data.effects = effects
	inventory.append(item_data)


func remove_inventory_item(item_id: String, quantity: int = 1) -> bool:
	for item in inventory:
		if item.item_id != item_id:
			continue
		if item.quantity < quantity:
			return false
		item.quantity -= quantity
		if item.quantity <= 0:
			inventory.erase(item)
		return true
	return false


func get_facility(type: String) -> Resource:
	for f in facilities:
		if f.facility_type == type:
			return f
	return null


func add_resource(resource_dict: Dictionary, resource_id: String, amount: int) -> void:
	if not resource_dict.has(resource_id):
		resource_dict[resource_id] = 0
	resource_dict[resource_id] += amount


func remove_resource(resource_dict: Dictionary, resource_id: String, amount: int) -> bool:
	if resource_dict.get(resource_id, 0) < amount:
		return false
	resource_dict[resource_id] -= amount
	return true


func can_afford_spirit_stones(amount: int) -> bool:
	return spirit_stones >= amount


func add_spirit_stones(amount: int) -> int:
	spirit_stones += amount
	return spirit_stones


func spend_spirit_stones(amount: int) -> bool:
	if not can_afford_spirit_stones(amount):
		return false
	spirit_stones -= amount
	return true


func max_facilities() -> int:
	return 12 - rank


func max_disciples() -> int:
	return (12 - rank) * 5


func can_build() -> bool:
	return facilities.size() < max_facilities()
