extends Node

signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal all_waves_cleared

var paused: bool = false
var _waves: Array = []
var _current_wave: int = 0
var _enemies_alive: int = 0
var _enemy_container: Node2D
var _spawning: bool = false
var _inter_wave_timer: float = 0.0
var _waiting_for_next_wave: bool = false

const INTER_WAVE_PAUSE := 5.0
const SPAWN_X := 1920.0
const ENEMY_SCENES := {
	"goblin": "res://entities/enemies/goblin.tscn",
	"orc": "res://entities/enemies/orc.tscn",
	"goblin_archer": "res://entities/enemies/goblin_archer.tscn",
}


func _process(delta: float) -> void:
	if _waiting_for_next_wave:
		if not paused:
			_inter_wave_timer -= delta * GameManager.game_speed
		if _inter_wave_timer <= 0.0:
			_waiting_for_next_wave = false
			start_next_wave()


func setup(waves: Array, enemy_container: Node2D) -> void:
	_waves = waves
	_enemy_container = enemy_container
	_current_wave = 0
	_enemies_alive = 0
	_spawning = false
	_waiting_for_next_wave = false


func start_next_wave() -> void:
	if _current_wave >= _waves.size():
		all_waves_cleared.emit()
		return

	_current_wave += 1
	wave_started.emit(_current_wave)

	var wave_data: Dictionary = _waves[_current_wave - 1]
	var enemy_groups: Array = wave_data.get("enemies", [])

	# Count total enemies in this wave
	_enemies_alive = 0
	for group in enemy_groups:
		_enemies_alive += int(group.get("count", 0))

	# Spawn each group
	for group in enemy_groups:
		_spawn_enemy_group(group)


func _spawn_enemy_group(group: Dictionary) -> void:
	var enemy_type: String = group.get("type", "goblin")
	var count: int = int(group.get("count", 1))
	var spawn_delay: float = group.get("spawn_delay", 1.0)
	var y_range: Array = group.get("spawn_y_range", [0.2, 0.8])
	var y_min: float = float(y_range[0]) * 1080.0
	var y_max: float = float(y_range[1]) * 1080.0

	var scene_path: String = ENEMY_SCENES.get(enemy_type, ENEMY_SCENES["goblin"])
	_spawn_sequence(scene_path, count, spawn_delay, y_min, y_max)


func _spawn_sequence(scene_path: String, count: int, delay: float, y_min: float, y_max: float) -> void:
	var scene := load(scene_path) as PackedScene
	if not scene:
		return

	for i in range(count):
		if not is_instance_valid(_enemy_container):
			return
		var enemy := scene.instantiate()
		var spawn_y := randf_range(y_min, y_max)
		enemy.position = Vector2(SPAWN_X + randf_range(0, 60), spawn_y)
		enemy.tree_exiting.connect(_on_enemy_removed)
		_enemy_container.add_child(enemy)

		if i < count - 1:
			await get_tree().create_timer(delay / max(GameManager.game_speed, 0.01)).timeout


func _on_enemy_removed() -> void:
	_enemies_alive -= 1
	if _enemies_alive <= 0 and _current_wave > 0:
		wave_completed.emit(_current_wave)
		if _current_wave < _waves.size():
			_waiting_for_next_wave = true
			_inter_wave_timer = INTER_WAVE_PAUSE
		else:
			all_waves_cleared.emit()
