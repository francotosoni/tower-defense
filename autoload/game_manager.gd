extends Node

# --- Signals ---
signal gold_changed(amount: int)
signal gems_changed(amount: int)
signal base_hp_changed(hp: int)
signal base_destroyed

# --- Resources ---
var gold: int = 0
var gems: int = 0

# --- Base ---
var base_hp: int = 100
var base_max_hp: int = 100

# --- Level state ---
var current_level: int = 1
var available_troops: Array[String] = []
var game_speed: float = 1.0
var is_battle_active: bool = false

# --- Campaign ---
var campaign_progress: Dictionary = {}

# --- Buffs ---
var active_buffs: Dictionary = {}

const SAVE_PATH = "user://save_data.json"


func _ready() -> void:
	load_progress()


func setup_level(level_data: Dictionary) -> void:
	reset_buffs()
	var starting = level_data.get("starting_resources", {})
	gold = int(starting.get("gold", 100))
	gems = int(starting.get("gems", 0))
	base_hp = int(level_data.get("base_hp", 100))
	base_max_hp = base_hp
	available_troops = []
	for t in level_data.get("available_troops", ["soldier"]):
		available_troops.append(str(t))
	is_battle_active = true
	game_speed = 1.0
	gold_changed.emit(gold)
	gems_changed.emit(gems)
	base_hp_changed.emit(base_hp)


func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)


func add_gems(amount: int) -> void:
	gems += amount
	gems_changed.emit(gems)


func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		gold_changed.emit(gold)
		return true
	return false


func spend_gems(amount: int) -> bool:
	if gems >= amount:
		gems -= amount
		gems_changed.emit(gems)
		return true
	return false


func reset_buffs() -> void:
	active_buffs = {}


func heal_base(amount: int) -> void:
	base_hp = mini(base_hp + amount, base_max_hp)
	base_hp_changed.emit(base_hp)


func damage_base(amount: int) -> void:
	base_hp = max(0, base_hp - amount)
	base_hp_changed.emit(base_hp)
	if base_hp <= 0:
		is_battle_active = false
		base_destroyed.emit()


func stop_battle() -> void:
	is_battle_active = false


func complete_level(level: int) -> void:
	campaign_progress[str(level)] = true
	save_progress()


func is_level_unlocked(level: int) -> bool:
	if level == 1:
		return true
	return campaign_progress.get(str(level - 1), false)


func save_progress() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(campaign_progress))


func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) == OK and json.data is Dictionary:
		campaign_progress = json.data
