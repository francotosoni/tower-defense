extends Node2D

signal level_won
signal level_lost

var _selected_troop: String = ""
var _level_data: Dictionary = {}
var _wave_shop
var _total_waves: int = 0

var battlefield: Node2D
var player_base: Node2D
var player_units: Node2D
var enemy_units: Node2D
var projectiles: Node2D
var wave_manager: Node
var hud: Node
var wave_banner: Node


func _ready() -> void:
	# Battlefield
	battlefield = Node2D.new()
	battlefield.name = "Battlefield"
	battlefield.set_script(load("res://scenes/battle/battlefield.gd"))
	add_child(battlefield)

	# Player base
	player_base = load("res://entities/base/player_base.tscn").instantiate()
	player_base.position = Vector2(70, 540)
	battlefield.add_child(player_base)

	# Containers
	player_units = Node2D.new()
	player_units.name = "PlayerUnits"
	battlefield.add_child(player_units)

	enemy_units = Node2D.new()
	enemy_units.name = "EnemyUnits"
	battlefield.add_child(enemy_units)

	projectiles = Node2D.new()
	projectiles.name = "Projectiles"
	battlefield.add_child(projectiles)

	var resource_container := Node2D.new()
	resource_container.name = "ResourceNodes"
	battlefield.add_child(resource_container)

	# Wave manager
	wave_manager = Node.new()
	wave_manager.name = "WaveManager"
	wave_manager.set_script(load("res://scenes/battle/wave_manager.gd"))
	add_child(wave_manager)

	# HUD
	hud = CanvasLayer.new()
	hud.name = "HUD"
	hud.set_script(load("res://scenes/battle/hud.gd"))
	add_child(hud)
	hud.troop_selected.connect(select_troop)

	# Wave banner
	wave_banner = CanvasLayer.new()
	wave_banner.name = "WaveBanner"
	wave_banner.set_script(load("res://scenes/battle/wave_banner.gd"))
	add_child(wave_banner)

	# Wave shop
	var shop_script = load("res://scenes/battle/wave_shop.gd")
	_wave_shop = CanvasLayer.new()
	_wave_shop.set_script(shop_script)
	_wave_shop.name = "WaveShop"
	add_child(_wave_shop)

	# Connect signals
	GameManager.base_destroyed.connect(_on_base_destroyed)
	wave_manager.all_waves_cleared.connect(_on_all_waves_cleared)
	wave_manager.wave_completed.connect(_on_wave_completed)
	wave_manager.wave_completed.connect(_on_wave_completed_shop)
	wave_manager.wave_started.connect(_on_wave_started)
	_wave_shop.shop_closed.connect(func(): wave_manager.paused = false)


func start_level(level_data: Dictionary) -> void:
	_level_data = level_data
	_total_waves = level_data.get("waves", []).size()
	GameManager.setup_level(level_data)
	wave_manager.setup(level_data.get("waves", []), enemy_units)
	_spawn_resource_nodes(level_data)
	hud.update_available_troops(GameManager.available_troops)
	hud.set_level_name(level_data.get("level_name", ""))
	wave_manager.start_next_wave()


func _spawn_resource_nodes(level_data: Dictionary) -> void:
	var nodes_data: Array = level_data.get("resource_nodes", [])
	var resource_scene = load("res://entities/resources/resource_node.tscn")
	var container = find_child("ResourceNodes", true, false)
	if not container:
		return
	for node_data in nodes_data:
		var node = resource_scene.instantiate()
		var type_str: String = node_data.get("type", "gold")
		match type_str:
			"silver":
				node.resource_type = ResourceNode.ResourceType.SILVER
			"gold":
				node.resource_type = ResourceNode.ResourceType.GOLD
			"gem":
				node.resource_type = ResourceNode.ResourceType.GEM
		var pos_x: float = node_data.get("x", 400)
		var pos_y: float = node_data.get("y", 500)
		node.position = Vector2(pos_x, pos_y)
		if node_data.has("charges"):
			node.max_charges = node_data["charges"]
		node.add_to_group("resource_nodes")
		container.add_child(node)


func select_troop(troop_type: String) -> void:
	_selected_troop = troop_type
	battlefield.set_deploy_highlight(troop_type != "")


func _process(_delta: float) -> void:
	if _selected_troop != "":
		var mouse_pos := get_viewport().get_mouse_position()
		var in_zone: bool = mouse_pos.x >= battlefield.DEPLOY_ZONE_START_X and mouse_pos.x <= battlefield.DEPLOY_ZONE_END_X and mouse_pos.y >= 80.0 and mouse_pos.y <= 1000.0
		if in_zone:
			Input.set_default_cursor_shape(Input.CURSOR_CROSS)
		else:
			Input.set_default_cursor_shape(Input.CURSOR_FORBIDDEN)
	else:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _selected_troop != "":
			_try_deploy(_selected_troop, event.position)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		select_troop("")
		hud.deselect_troop()


func _try_deploy(troop_type: String, pos: Vector2) -> void:
	if pos.x < battlefield.DEPLOY_ZONE_START_X or pos.x > battlefield.DEPLOY_ZONE_END_X:
		return
	if pos.y < 80.0 or pos.y > 1000.0:
		return

	var cost := _get_troop_cost(troop_type)
	if cost.has("gold"):
		if not GameManager.spend_gold(cost["gold"]):
			return
	if cost.has("gems"):
		if not GameManager.spend_gems(cost["gems"]):
			return

	var scene_path := "res://entities/units/%s.tscn" % troop_type
	var scene := load(scene_path) as PackedScene
	if not scene:
		return
	var unit := scene.instantiate()
	unit.position = pos
	player_units.add_child(unit)


func _get_troop_cost(troop_type: String) -> Dictionary:
	match troop_type:
		"soldier":
			return {"gold": 30}
		"archer":
			return {"gold": 50}
		"mage":
			return {"gems": 2}
		"miner":
			return {"gold": 15}
	return {}


func _on_wave_started(wave_number: int) -> void:
	var total: int = _level_data.get("waves", []).size()
	hud.update_wave_info(wave_number, total)
	wave_banner.show_banner("Wave %d — %d enemies" % [wave_number, _count_wave_enemies(wave_number)])


func _count_wave_enemies(wave_number: int) -> int:
	var waves: Array = _level_data.get("waves", [])
	if wave_number - 1 < waves.size():
		var wave_data: Dictionary = waves[wave_number - 1]
		var total := 0
		for group in wave_data.get("enemies", []):
			total += int(group.get("count", 0))
		return total
	return 0


func _on_wave_completed_shop(wave_num: int) -> void:
	if wave_num < _total_waves:
		wave_manager.paused = true
		_wave_shop.show_shop()


func _on_wave_completed(wave_number: int) -> void:
	var waves: Array = _level_data.get("waves", [])
	if wave_number - 1 < waves.size():
		var wave_data: Dictionary = waves[wave_number - 1]
		var reward: Dictionary = wave_data.get("reward", {})
		if reward.has("gold"):
			GameManager.add_gold(int(reward["gold"]))
		if reward.has("gems"):
			GameManager.add_gems(int(reward["gems"]))


func _on_all_waves_cleared() -> void:
	await get_tree().create_timer(0.5).timeout
	_check_victory()


func _check_victory() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	if enemies.size() == 0:
		GameManager.stop_battle()
		level_won.emit()
	else:
		await get_tree().create_timer(0.5).timeout
		_check_victory()


func _on_base_destroyed() -> void:
	GameManager.stop_battle()
	level_lost.emit()
