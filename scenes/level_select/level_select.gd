extends Control

const LEVEL_COUNT := 5
const LEVEL_DATA_PATH := "res://data/levels/level_%d.json"


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	# Background
	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.12, 0.18)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Title
	var title := Label.new()
	title.text = "Select Level"
	title.position = Vector2(0, 40)
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color.WHITE)
	add_child(title)

	# Level buttons in a horizontal row
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 40)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(hbox)

	for i in range(1, LEVEL_COUNT + 1):
		var level_data := _load_level_data(i)
		var level_name: String = level_data.get("level_name", "Level %d" % i)
		var unlocked := GameManager.is_level_unlocked(i)
		var completed: bool = GameManager.campaign_progress.get(str(i), false)

		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 10)
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.add_child(vbox)

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(120, 120)
		btn.add_theme_font_size_override("font_size", 32)

		if completed:
			btn.text = str(i) + " ✓"
			btn.modulate = Color(0.5, 1.0, 0.5)
		elif unlocked:
			btn.text = str(i)
			btn.modulate = Color(1.0, 1.0, 0.6)
		else:
			btn.text = "🔒"
			btn.disabled = true
			btn.modulate = Color(0.4, 0.4, 0.4)

		btn.pressed.connect(_on_level_selected.bind(i))
		vbox.add_child(btn)

		var name_label := Label.new()
		name_label.text = level_name if unlocked else "???"
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 14)
		vbox.add_child(name_label)

	# Back button
	var back_btn := Button.new()
	back_btn.text = "← Back"
	back_btn.position = Vector2(40, 40)
	back_btn.custom_minimum_size = Vector2(100, 40)
	back_btn.add_theme_font_size_override("font_size", 18)
	back_btn.pressed.connect(_on_back)
	add_child(back_btn)


func _load_level_data(level: int) -> Dictionary:
	var path := LEVEL_DATA_PATH % level
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var json := JSON.new()
	if json.parse(file.get_as_text()) == OK and json.data is Dictionary:
		return json.data
	return {}


func _on_level_selected(level: int) -> void:
	GameManager.current_level = level
	var battle_scene = load("res://scenes/battle/battle.tscn").instantiate()
	get_tree().root.add_child(battle_scene)

	var level_data := _load_level_data(level)

	# Connect result signals
	battle_scene.level_won.connect(_on_level_won.bind(level, battle_scene))
	battle_scene.level_lost.connect(_on_level_lost.bind(level, battle_scene))

	# Add level result overlay (wrapped in CanvasLayer so Control renders properly over Node2D)
	var result_layer := CanvasLayer.new()
	result_layer.name = "ResultLayer"
	result_layer.layer = 30
	battle_scene.add_child(result_layer)
	var result_scene = load("res://scenes/level_result/level_result.tscn").instantiate()
	result_layer.add_child(result_scene)

	# Connect result navigation
	result_scene.next_level_requested.connect(func():
		battle_scene.queue_free()
		if level < LEVEL_COUNT:
			_on_level_selected(level + 1)
	)
	result_scene.retry_requested.connect(func():
		battle_scene.queue_free()
		_on_level_selected(level)
	)
	result_scene.back_to_menu_requested.connect(func():
		battle_scene.queue_free()
		visible = true
	)

	visible = false
	battle_scene.start_level(level_data)


func _on_level_won(level: int, battle_scene: Node) -> void:
	GameManager.complete_level(level)
	var result = battle_scene.find_child("LevelResult", true, false)
	if result:
		result.show_victory()


func _on_level_lost(_level: int, battle_scene: Node) -> void:
	var result = battle_scene.find_child("LevelResult", true, false)
	if result:
		result.show_defeat()


func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
