extends Control
## 主菜单界面


@onready var new_game_button: Button = $Panel/VBoxContainer/NewGameButton
@onready var load_game_button: Button = $Panel/VBoxContainer/LoadGameButton
@onready var settings_button: Button = $Panel/VBoxContainer/SettingsButton
@onready var quit_button: Button = $Panel/VBoxContainer/QuitButton
@onready var sect_name_input: LineEdit = $Panel/VBoxContainer/SectNameInput
@onready var save_slots_container: Control = $SaveSlots


func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game_pressed)
	load_game_button.pressed.connect(_on_load_game_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	save_slots_container.visible = false


func _on_new_game_pressed() -> void:
	var name = sect_name_input.text.strip_edges()
	if name.is_empty():
		name = "青云宗"
	GameSetup.setup_new_game(name)
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_load_game_pressed() -> void:
	save_slots_container.visible = true
	var slots = SaveManager.get_save_slots()
	_display_save_slots(slots)


func _display_save_slots(slots: Array[Dictionary]) -> void:
	for child in save_slots_container.get_children():
		child.queue_free()

	for slot in slots:
		var btn = Button.new()
		btn.text = "%s — %s" % [slot["sect_name"], slot["date"]]
		btn.pressed.connect(func(): _on_slot_selected(slot["path"]))
		save_slots_container.add_child(btn)


func _on_slot_selected(path: String) -> void:
	GameManager.load_game(path)
	if GameManager.is_game_running():
		get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
