# Tower Defense — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a complete tower defense game in Godot 4 with 3 troop types, 3 enemy types, 5 campaign levels, and full menu/save flow.

**Architecture:** Godot 4 scene tree with an autoloaded GameManager singleton for global state. Entities (troops/enemies) use CharacterBody2D with autonomous AI. Levels defined as JSON files loaded by WaveManager. Signal-based communication between systems. All visuals use code-drawn placeholders (colored shapes via `_draw()`) — no external art assets needed.

**Tech Stack:** Godot 4.3+, GDScript, JSON level data

**Prerequisites:** Install Godot 4.3+ from https://godotengine.org/download

---

## File Structure

```
project.godot                        — Engine config, autoloads, display settings
autoload/
  game_manager.gd                    — Global state: resources, progression, save/load
scenes/
  main_menu/
    main_menu.tscn + .gd             — Title screen: Play / Quit
  level_select/
    level_select.tscn + .gd          — Campaign map with level nodes
  battle/
    battle.tscn + .gd                — Main gameplay orchestrator
    battlefield.gd                   — Background rendering + deployment zone overlay
    wave_manager.gd                  — Wave spawning, timing, signals
    hud.tscn + .gd                   — Top bar (resources), bottom bar (troop buttons, speed)
    wave_banner.gd                   — "Wave N" announcement overlay
  level_result/
    level_result.tscn + .gd          — Victory / Defeat screen
entities/
  units/
    base_unit.gd                     — Shared troop base: HP, move, target, attack
    soldier.tscn + .gd               — Melee troop (extends base_unit)
    archer.tscn + .gd                — Ranged troop
    mage.tscn + .gd                  — AoE ranged troop
  enemies/
    base_enemy.gd                    — Shared enemy base: HP, base-seeking, aggro
    goblin.tscn + .gd                — Fast / fragile melee
    orc.tscn + .gd                   — Slow / tanky melee
    goblin_archer.tscn + .gd         — Ranged enemy
  projectiles/
    arrow.tscn + .gd                 — Archer projectile
    magic_bolt.tscn + .gd            — Mage AoE projectile
  base/
    player_base.tscn + .gd           — Defend target with HP bar
data/
  levels/
    level_1.json ... level_5.json    — Wave compositions, rewards, available troops
```

### Resolution & Scaled Values

Base viewport: **1920×1080** (scaled 1.5× from original 720p spec). All pixel values below reflect 1080p.

**Troops (1080p):**

| Troop | Cost | HP | Damage | Atk Speed | Move Speed | Range |
|-------|------|----|--------|-----------|------------|-------|
| Soldier | 30 Gold | 100 | 10 | 1.0s | 120 px/s | 45 (melee) |
| Archer | 50 Gold | 50 | 8 | 0.8s | 90 px/s | 300 |
| Mage | 2 Gems | 40 | 15 (AoE r=90) | 1.5s | 75 px/s | 270 |

**Enemies (1080p):**

| Enemy | HP | Damage | Atk Speed | Move Speed | Range | Base Dmg | Bounty |
|-------|----|--------|-----------|------------|-------|----------|--------|
| Goblin | 40 | 5 | 1.0s | 180 px/s | 45 | 10 | 5 Gold |
| Orc | 150 | 12 | 1.5s | 75 px/s | 45 | 30 | 15 Gold |
| Goblin Archer | 60 | 7 | 1.0s | 120 px/s | 225 | 10 | 10 Gold |

**Other scaled values:** Enemy aggro range: 120px. Deployment zone: leftmost 480px (25% of 1920), starting after the base.

### Collision Layers

| Layer | Bit | Used by |
|-------|-----|---------|
| 1 | Player Troops | CharacterBody2D for soldiers, archers, mages |
| 2 | Enemies | CharacterBody2D for goblins, orcs, goblin archers |
| 3 | Obstacles | StaticBody2D for rocks, trees |

- Player troops: `collision_layer = 1`, `collision_mask = 6` (collide with enemies + obstacles)
- Enemies: `collision_layer = 2`, `collision_mask = 5` (collide with player troops + obstacles)
- Allies overlap (same-layer bodies don't collide because they don't mask their own layer)

---

### Task 1: Project Setup

**Files:**
- Create: `project.godot`
- Create: directory structure (all folders)

- [ ] **Step 1: Create directory structure**

```bash
mkdir -p autoload scenes/main_menu scenes/level_select scenes/battle scenes/level_result
mkdir -p entities/units entities/enemies entities/projectiles entities/base
mkdir -p data/levels
```

- [ ] **Step 2: Create `project.godot`**

```ini
; Engine configuration file.
; It's best edited using the editor UI and not directly,
; but it can also be edited via text.

config_version=5

[application]

config/name="Tower Defense"
run/main_scene="res://scenes/main_menu/main_menu.tscn"
config/features=PackedStringArray("4.3")

[autoload]

GameManager="*res://autoload/game_manager.gd"

[display]

window/size/viewport_width=1920
window/size/viewport_height=1080
window/stretch/mode="canvas_items"

[rendering]

textures/canvas_textures/default_texture_filter=0
```

- [ ] **Step 3: Create placeholder main menu so the project opens**

Create `scenes/main_menu/main_menu.gd`:

```gdscript
extends Control

func _ready():
	pass
```

Create `scenes/main_menu/main_menu.tscn`:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scenes/main_menu/main_menu.gd" id="1"]

[node name="MainMenu" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1")
```

- [ ] **Step 4: Create placeholder `autoload/game_manager.gd`**

```gdscript
extends Node
```

- [ ] **Step 5: Verify — open project in Godot**

Open Godot 4.3+, import the project folder. The editor should open with no errors and show a blank main menu scene.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat: scaffold Godot 4 project with directory structure and 1080p config"
```

---

### Task 2: GameManager Autoload

**Files:**
- Modify: `autoload/game_manager.gd`

- [ ] **Step 1: Implement GameManager**

Replace `autoload/game_manager.gd` with:

```gdscript
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
var gold_per_second: float = 5.0
var available_troops: Array[String] = []
var game_speed: float = 1.0
var is_battle_active: bool = false

# --- Campaign ---
var campaign_progress: Dictionary = {}

# --- Gold generation ---
var _gold_accumulator: float = 0.0

const SAVE_PATH = "user://save_data.json"


func _ready() -> void:
	load_progress()


func _process(delta: float) -> void:
	if not is_battle_active:
		return
	_gold_accumulator += delta * gold_per_second * game_speed
	while _gold_accumulator >= 1.0:
		_gold_accumulator -= 1.0
		add_gold(1)


func setup_level(level_data: Dictionary) -> void:
	var starting = level_data.get("starting_resources", {})
	gold = int(starting.get("gold", 100))
	gems = int(starting.get("gems", 0))
	base_hp = int(level_data.get("base_hp", 100))
	base_max_hp = base_hp
	gold_per_second = float(level_data.get("gold_per_second", 5.0))
	available_troops = []
	for t in level_data.get("available_troops", ["soldier"]):
		available_troops.append(str(t))
	_gold_accumulator = 0.0
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
```

- [ ] **Step 2: Verify — open project, check Output for errors**

Run the project (F5). The main menu scene loads. Check the Output panel — no errors from GameManager autoload.

- [ ] **Step 3: Commit**

```bash
git add autoload/game_manager.gd
git commit -m "feat: implement GameManager autoload with resources, base HP, and save/load"
```

---

### Task 3: BaseUnit + Soldier

**Files:**
- Create: `entities/units/base_unit.gd`
- Create: `entities/units/soldier.gd`
- Create: `entities/units/soldier.tscn`

- [ ] **Step 1: Create `entities/units/base_unit.gd`**

```gdscript
extends CharacterBody2D
class_name BaseUnit

signal unit_died(unit: BaseUnit)

@export var max_hp: int = 100
@export var damage: int = 10
@export var attack_speed: float = 1.0
@export var move_speed: float = 120.0
@export var attack_range: float = 45.0
@export var unit_color: Color = Color.CORNFLOWER_BLUE
@export var unit_radius: float = 15.0

var hp: int
var attack_timer: float = 0.0
var target: Node2D = null


func _ready() -> void:
	hp = max_hp
	add_to_group("player_units")
	collision_layer = 1
	collision_mask = 6
	_create_collision_shape()


func _create_collision_shape() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = unit_radius
	shape.shape = circle
	add_child(shape)


func _draw() -> void:
	# Body
	draw_circle(Vector2.ZERO, unit_radius, unit_color)
	draw_arc(Vector2.ZERO, unit_radius, 0, TAU, 32, unit_color.darkened(0.3), 2.0)
	# HP bar
	var bar_w := unit_radius * 2.2
	var bar_h := 4.0
	var bar_y := -unit_radius - 10.0
	var hp_ratio := float(hp) / float(max_hp)
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w, bar_h), Color(0.2, 0.2, 0.2))
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w * hp_ratio, bar_h), Color.GREEN_YELLOW)


func _physics_process(delta: float) -> void:
	var speed_mult := GameManager.game_speed
	attack_timer = max(0.0, attack_timer - delta * speed_mult)

	target = _find_target()
	if target and is_instance_valid(target):
		var dist := global_position.distance_to(target.global_position)
		if dist <= attack_range:
			_do_attack()
		else:
			_move_toward(target, delta * speed_mult)
	else:
		velocity = Vector2.ZERO

	queue_redraw()


func _find_target() -> Node2D:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var closest: Node2D = null
	var closest_dist := INF
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var d := global_position.distance_to(enemy.global_position)
		if d < closest_dist:
			closest_dist = d
			closest = enemy
	return closest


func _move_toward(t: Node2D, scaled_delta: float) -> void:
	var dir := (t.global_position - global_position).normalized()
	velocity = dir * move_speed * GameManager.game_speed
	move_and_slide()


func _do_attack() -> void:
	velocity = Vector2.ZERO
	move_and_slide()
	if attack_timer <= 0.0:
		_perform_attack()
		attack_timer = attack_speed


func _perform_attack() -> void:
	if target and is_instance_valid(target) and target.has_method("take_damage"):
		target.take_damage(damage)


func take_damage(amount: int) -> void:
	hp -= amount
	if hp <= 0:
		_die()


func _die() -> void:
	unit_died.emit(self)
	queue_free()
```

- [ ] **Step 2: Create `entities/units/soldier.gd`**

```gdscript
extends BaseUnit

func _ready() -> void:
	max_hp = 100
	damage = 10
	attack_speed = 1.0
	move_speed = 120.0
	attack_range = 45.0
	unit_color = Color(0.2, 0.4, 0.9)  # Blue
	unit_radius = 15.0
	super._ready()
```

- [ ] **Step 3: Create `entities/units/soldier.tscn`**

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://entities/units/soldier.gd" id="1"]

[node name="Soldier" type="CharacterBody2D"]
script = ExtResource("1")
```

- [ ] **Step 4: Verify — create a test scene**

Temporarily modify `scenes/main_menu/main_menu.gd` to spawn a soldier for visual testing:

```gdscript
extends Control

func _ready():
	var soldier_scene := load("res://entities/units/soldier.tscn")
	var soldier := soldier_scene.instantiate()
	soldier.position = Vector2(400, 540)
	add_child(soldier)
```

Run the project — a blue circle with an HP bar should appear at (400, 540). Then revert main_menu.gd:

```gdscript
extends Control

func _ready():
	pass
```

- [ ] **Step 5: Commit**

```bash
git add entities/units/base_unit.gd entities/units/soldier.gd entities/units/soldier.tscn
git commit -m "feat: implement BaseUnit and Soldier troop with autonomous melee AI"
```

---

### Task 4: BaseEnemy + Goblin

**Files:**
- Create: `entities/enemies/base_enemy.gd`
- Create: `entities/enemies/goblin.gd`
- Create: `entities/enemies/goblin.tscn`

- [ ] **Step 1: Create `entities/enemies/base_enemy.gd`**

```gdscript
extends CharacterBody2D
class_name BaseEnemy

signal enemy_died(enemy: BaseEnemy, bounty: int)

@export var max_hp: int = 40
@export var damage: int = 5
@export var attack_speed: float = 1.0
@export var move_speed: float = 180.0
@export var attack_range: float = 45.0
@export var base_damage: int = 10
@export var bounty_gold: int = 5
@export var enemy_color: Color = Color(0.8, 0.2, 0.2)
@export var enemy_radius: float = 13.0

const AGGRO_RANGE := 120.0

var hp: int
var attack_timer: float = 0.0
var target: Node2D = null
var _base_node: Node2D = null


func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")
	collision_layer = 2
	collision_mask = 5
	_create_collision_shape()


func _create_collision_shape() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = enemy_radius
	shape.shape = circle
	add_child(shape)


func _draw() -> void:
	# Body
	draw_circle(Vector2.ZERO, enemy_radius, enemy_color)
	draw_arc(Vector2.ZERO, enemy_radius, 0, TAU, 32, enemy_color.darkened(0.3), 2.0)
	# HP bar
	var bar_w := enemy_radius * 2.2
	var bar_h := 4.0
	var bar_y := -enemy_radius - 10.0
	var hp_ratio := float(hp) / float(max_hp)
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w, bar_h), Color(0.2, 0.2, 0.2))
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w * hp_ratio, bar_h), Color.ORANGE_RED)


func _physics_process(delta: float) -> void:
	var speed_mult := GameManager.game_speed
	attack_timer = max(0.0, attack_timer - delta * speed_mult)

	# Check for nearby player troops to aggro
	target = _find_aggro_target()

	if target and is_instance_valid(target):
		var dist := global_position.distance_to(target.global_position)
		if dist <= attack_range:
			_do_attack()
		else:
			_move_toward(target, speed_mult)
	else:
		# No aggro target — move toward the base
		_move_toward_base(speed_mult)

	queue_redraw()


func _find_aggro_target() -> Node2D:
	var units := get_tree().get_nodes_in_group("player_units")
	var closest: Node2D = null
	var closest_dist := AGGRO_RANGE
	for unit in units:
		if not is_instance_valid(unit):
			continue
		var d := global_position.distance_to(unit.global_position)
		if d < closest_dist:
			closest_dist = d
			closest = unit
	return closest


func _move_toward(t: Node2D, speed_mult: float) -> void:
	var dir := (t.global_position - global_position).normalized()
	velocity = dir * move_speed * speed_mult
	move_and_slide()


func _move_toward_base(speed_mult: float) -> void:
	if not _base_node:
		_base_node = _find_base()
	if _base_node and is_instance_valid(_base_node):
		var dir := (_base_node.global_position - global_position).normalized()
		velocity = dir * move_speed * speed_mult
		move_and_slide()
		# Check if reached the base
		if global_position.distance_to(_base_node.global_position) < 50.0:
			_hit_base()
	else:
		# Fallback: move left
		velocity = Vector2.LEFT * move_speed * speed_mult
		move_and_slide()
		if global_position.x < 60.0:
			_hit_base()


func _find_base() -> Node2D:
	var bases := get_tree().get_nodes_in_group("player_base")
	if bases.size() > 0:
		return bases[0]
	return null


func _do_attack() -> void:
	velocity = Vector2.ZERO
	move_and_slide()
	if attack_timer <= 0.0:
		_perform_attack()
		attack_timer = attack_speed


func _perform_attack() -> void:
	if target and is_instance_valid(target) and target.has_method("take_damage"):
		target.take_damage(damage)


func _hit_base() -> void:
	GameManager.damage_base(base_damage)
	queue_free()


func take_damage(amount: int) -> void:
	hp -= amount
	if hp <= 0:
		_die()


func _die() -> void:
	GameManager.add_gold(bounty_gold)
	enemy_died.emit(self, bounty_gold)
	queue_free()
```

- [ ] **Step 2: Create `entities/enemies/goblin.gd`**

```gdscript
extends BaseEnemy

func _ready() -> void:
	max_hp = 40
	damage = 5
	attack_speed = 1.0
	move_speed = 180.0
	attack_range = 45.0
	base_damage = 10
	bounty_gold = 5
	enemy_color = Color(0.4, 0.7, 0.2)  # Green
	enemy_radius = 11.0
	super._ready()
```

- [ ] **Step 3: Create `entities/enemies/goblin.tscn`**

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://entities/enemies/goblin.gd" id="1"]

[node name="Goblin" type="CharacterBody2D"]
script = ExtResource("1")
```

- [ ] **Step 4: Verify — test soldier vs goblin**

Temporarily edit `scenes/main_menu/main_menu.gd`:

```gdscript
extends Control

func _ready():
	GameManager.is_battle_active = true
	var soldier_scn := load("res://entities/units/soldier.tscn")
	var goblin_scn := load("res://entities/enemies/goblin.tscn")
	var s := soldier_scn.instantiate()
	s.position = Vector2(400, 540)
	add_child(s)
	var g := goblin_scn.instantiate()
	g.position = Vector2(800, 540)
	add_child(g)
```

Run — the goblin (green) should move left toward the soldier (blue). They should engage in combat. The goblin dies first (40 HP vs 100 HP). Then revert main_menu.gd to the empty version.

- [ ] **Step 5: Commit**

```bash
git add entities/enemies/base_enemy.gd entities/enemies/goblin.gd entities/enemies/goblin.tscn
git commit -m "feat: implement BaseEnemy and Goblin with base-seeking and aggro AI"
```

---

### Task 5: Player Base

**Files:**
- Create: `entities/base/player_base.gd`
- Create: `entities/base/player_base.tscn`

- [ ] **Step 1: Create `entities/base/player_base.gd`**

```gdscript
extends Node2D

func _ready() -> void:
	add_to_group("player_base")
	GameManager.base_hp_changed.connect(_on_base_hp_changed)


func _draw() -> void:
	# Castle base — simple rectangle with battlements
	var w := 80.0
	var h := 120.0
	# Main structure
	draw_rect(Rect2(-w / 2, -h / 2, w, h), Color(0.5, 0.4, 0.3))
	draw_rect(Rect2(-w / 2, -h / 2, w, h), Color(0.35, 0.28, 0.2), false, 3.0)
	# Battlements
	var merlon_w := 16.0
	var merlon_h := 15.0
	for i in range(4):
		var mx := -w / 2 + 5.0 + i * (merlon_w + 4.0)
		draw_rect(Rect2(mx, -h / 2 - merlon_h, merlon_w, merlon_h), Color(0.5, 0.4, 0.3))
	# Door
	draw_rect(Rect2(-12, h / 2 - 30, 24, 30), Color(0.3, 0.2, 0.1))
	# HP bar
	var bar_w := 100.0
	var bar_h := 8.0
	var bar_y := h / 2 + 10.0
	var hp_ratio := float(GameManager.base_hp) / float(max(GameManager.base_max_hp, 1))
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w, bar_h), Color(0.2, 0.2, 0.2))
	var bar_color := Color.GREEN if hp_ratio > 0.5 else (Color.YELLOW if hp_ratio > 0.25 else Color.RED)
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w * hp_ratio, bar_h), bar_color)
	# HP text
	var hp_text := "%d / %d" % [GameManager.base_hp, GameManager.base_max_hp]
	draw_string(ThemeDB.fallback_font, Vector2(-bar_w / 2, bar_y + bar_h + 16), hp_text, HORIZONTAL_ALIGNMENT_LEFT, bar_w, 12, Color.WHITE)


func _on_base_hp_changed(_hp: int) -> void:
	queue_redraw()
```

- [ ] **Step 2: Create `entities/base/player_base.tscn`**

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://entities/base/player_base.gd" id="1"]

[node name="PlayerBase" type="Node2D"]
script = ExtResource("1")
```

- [ ] **Step 3: Commit**

```bash
git add entities/base/player_base.gd entities/base/player_base.tscn
git commit -m "feat: implement PlayerBase with castle visuals and HP bar"
```

---

### Task 6: Battle Scene + Battlefield

**Files:**
- Create: `scenes/battle/battlefield.gd`
- Create: `scenes/battle/battle.gd`
- Create: `scenes/battle/battle.tscn`

- [ ] **Step 1: Create `scenes/battle/battlefield.gd`**

```gdscript
extends Node2D

const DEPLOY_ZONE_START_X := 140.0
const DEPLOY_ZONE_END_X := 620.0
const FIELD_COLOR := Color(0.36, 0.54, 0.28)
const DEPLOY_ZONE_COLOR := Color(0.3, 0.6, 0.3, 0.15)
const DEPLOY_BORDER_COLOR := Color(0.9, 0.9, 0.3, 0.5)

var show_deploy_zone: bool = false


func _draw() -> void:
	# Grass background
	draw_rect(Rect2(0, 0, 1920, 1080), FIELD_COLOR)

	# Subtle grid pattern
	var grid_color := Color(0.32, 0.50, 0.25)
	for x in range(0, 1921, 60):
		draw_line(Vector2(x, 0), Vector2(x, 1080), grid_color, 1.0)
	for y in range(0, 1081, 60):
		draw_line(Vector2(0, y), Vector2(1920, y), grid_color, 1.0)

	# Deployment zone highlight
	if show_deploy_zone:
		draw_rect(Rect2(DEPLOY_ZONE_START_X, 0, DEPLOY_ZONE_END_X - DEPLOY_ZONE_START_X, 1080), DEPLOY_ZONE_COLOR)
		# Dashed border on right edge
		var dash_len := 20.0
		var gap_len := 10.0
		var y := 0.0
		while y < 1080.0:
			var end_y := min(y + dash_len, 1080.0)
			draw_line(Vector2(DEPLOY_ZONE_END_X, y), Vector2(DEPLOY_ZONE_END_X, end_y), DEPLOY_BORDER_COLOR, 2.0)
			y += dash_len + gap_len


func set_deploy_highlight(visible: bool) -> void:
	show_deploy_zone = visible
	queue_redraw()
```

- [ ] **Step 2: Create `scenes/battle/battle.gd`**

```gdscript
extends Node2D

signal level_won
signal level_lost

var _selected_troop: String = ""
var _level_data: Dictionary = {}

@onready var battlefield: Node2D = $Battlefield
@onready var player_base: Node2D = $Battlefield/PlayerBase
@onready var player_units: Node2D = $Battlefield/PlayerUnits
@onready var enemy_units: Node2D = $Battlefield/EnemyUnits
@onready var projectiles: Node2D = $Battlefield/Projectiles
@onready var wave_manager: Node = $WaveManager
@onready var hud: CanvasLayer = $HUD


func _ready() -> void:
	GameManager.base_destroyed.connect(_on_base_destroyed)
	wave_manager.all_waves_cleared.connect(_on_all_waves_cleared)
	wave_manager.wave_completed.connect(_on_wave_completed)


func start_level(level_data: Dictionary) -> void:
	_level_data = level_data
	GameManager.setup_level(level_data)
	wave_manager.setup(level_data.get("waves", []))
	hud.update_available_troops(GameManager.available_troops)
	wave_manager.start_next_wave()


func select_troop(troop_type: String) -> void:
	_selected_troop = troop_type
	battlefield.set_deploy_highlight(troop_type != "")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _selected_troop != "":
			_try_deploy(_selected_troop, event.position)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		select_troop("")
		hud.deselect_troop()


func _try_deploy(troop_type: String, pos: Vector2) -> void:
	# Check deployment zone
	if pos.x < battlefield.DEPLOY_ZONE_START_X or pos.x > battlefield.DEPLOY_ZONE_END_X:
		return
	if pos.y < 80.0 or pos.y > 1000.0:
		return

	# Check cost
	var cost := _get_troop_cost(troop_type)
	if cost.has("gold"):
		if not GameManager.spend_gold(cost["gold"]):
			return
	if cost.has("gems"):
		if not GameManager.spend_gems(cost["gems"]):
			return

	# Spawn troop
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
	return {}


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
	# Wait until all enemies are dead
	await get_tree().create_timer(0.5).timeout
	_check_victory()


func _check_victory() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	if enemies.size() == 0:
		GameManager.stop_battle()
		level_won.emit()
	else:
		# Still enemies alive, check again shortly
		await get_tree().create_timer(0.5).timeout
		_check_victory()


func _on_base_destroyed() -> void:
	GameManager.stop_battle()
	level_lost.emit()
```

- [ ] **Step 3: Create `scenes/battle/battle.tscn`**

```
[gd_scene load_steps=5 format=3]

[ext_resource type="Script" path="res://scenes/battle/battle.gd" id="1"]
[ext_resource type="Script" path="res://scenes/battle/battlefield.gd" id="2"]
[ext_resource type="PackedScene" path="res://entities/base/player_base.tscn" id="3"]
[ext_resource type="Script" path="res://scenes/battle/wave_manager.gd" id="4"]

[node name="Battle" type="Node2D"]
script = ExtResource("1")

[node name="Battlefield" type="Node2D" parent="."]
script = ExtResource("2")

[node name="PlayerBase" type="Node2D" parent="Battlefield"]
position = Vector2(70, 540)

[node name="PlayerUnits" type="Node2D" parent="Battlefield"]

[node name="EnemyUnits" type="Node2D" parent="Battlefield"]

[node name="Projectiles" type="Node2D" parent="Battlefield"]

[node name="WaveManager" type="Node" parent="."]
script = ExtResource("4")
```

Note: `PlayerBase` node will need its script attached. We'll handle this by making the battle scene reference the packed scene properly. Since .tscn hand-editing has limits, an alternative approach: set up PlayerBase in `battle.gd` `_ready()`. Let's adjust — replace the PlayerBase node line in the .tscn with a plain Node2D and instantiate in code:

Updated `scenes/battle/battle.tscn`:

```
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scenes/battle/battle.gd" id="1"]
[ext_resource type="Script" path="res://scenes/battle/battlefield.gd" id="2"]

[node name="Battle" type="Node2D"]
script = ExtResource("1")

[node name="Battlefield" type="Node2D" parent="."]
script = ExtResource("2")

[node name="PlayerBase" type="Node2D" parent="Battlefield"]

[node name="PlayerUnits" type="Node2D" parent="Battlefield"]

[node name="EnemyUnits" type="Node2D" parent="Battlefield"]

[node name="Projectiles" type="Node2D" parent="Battlefield"]

[node name="WaveManager" type="Node" parent="."]
```

Then modify `scenes/battle/battle.gd` `_ready()` to set up the base and wave_manager:

Add at the top of the `_ready()` function in battle.gd:

```gdscript
func _ready() -> void:
	# Attach base script
	var base_script := load("res://entities/base/player_base.gd")
	player_base.set_script(base_script)
	player_base.position = Vector2(70, 540)
	player_base._ready()

	# Attach wave manager script
	var wm_script := load("res://scenes/battle/wave_manager.gd")
	wave_manager.set_script(wm_script)

	GameManager.base_destroyed.connect(_on_base_destroyed)
	wave_manager.all_waves_cleared.connect(_on_all_waves_cleared)
	wave_manager.wave_completed.connect(_on_wave_completed)
```

Actually, this approach is fragile. Let's use a simpler strategy — instantiate PlayerBase from the packed scene in battle.gd `_ready()`:

Replace the battle.gd `_ready()` and adjust `@onready` references:

```gdscript
extends Node2D

signal level_won
signal level_lost

var _selected_troop: String = ""
var _level_data: Dictionary = {}

@onready var battlefield: Node2D = $Battlefield
@onready var player_units: Node2D = $Battlefield/PlayerUnits
@onready var enemy_units: Node2D = $Battlefield/EnemyUnits
@onready var projectiles: Node2D = $Battlefield/Projectiles

var player_base: Node2D
var wave_manager: Node
var hud: CanvasLayer


func _ready() -> void:
	# Instantiate player base
	var base_scene := load("res://entities/base/player_base.tscn") as PackedScene
	player_base = base_scene.instantiate()
	player_base.position = Vector2(70, 540)
	battlefield.add_child(player_base)

	# Setup wave manager
	wave_manager = Node.new()
	wave_manager.name = "WaveManager"
	wave_manager.set_script(load("res://scenes/battle/wave_manager.gd"))
	add_child(wave_manager)

	GameManager.base_destroyed.connect(_on_base_destroyed)
	wave_manager.all_waves_cleared.connect(_on_all_waves_cleared)
	wave_manager.wave_completed.connect(_on_wave_completed)
```

This is getting overly complex. Let me simplify the whole approach — use the simplest .tscn possible and do everything in code.

Final `scenes/battle/battle.tscn`:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scenes/battle/battle.gd" id="1"]

[node name="Battle" type="Node2D"]
script = ExtResource("1")
```

And `battle.gd` builds the entire scene tree in `_ready()`. This is the most reliable approach for hand-authored files.

- [ ] **Step 4: Update `scenes/battle/battle.gd` — full self-contained version**

Replace the entire file with:

```gdscript
extends Node2D

signal level_won
signal level_lost

var _selected_troop: String = ""
var _level_data: Dictionary = {}

var battlefield: Node2D
var player_base: Node2D
var player_units: Node2D
var enemy_units: Node2D
var projectiles: Node2D
var wave_manager: Node
var hud: CanvasLayer


func _ready() -> void:
	# Build scene tree
	battlefield = Node2D.new()
	battlefield.name = "Battlefield"
	battlefield.set_script(load("res://scenes/battle/battlefield.gd"))
	add_child(battlefield)

	player_base = load("res://entities/base/player_base.tscn").instantiate()
	player_base.position = Vector2(70, 540)
	battlefield.add_child(player_base)

	player_units = Node2D.new()
	player_units.name = "PlayerUnits"
	battlefield.add_child(player_units)

	enemy_units = Node2D.new()
	enemy_units.name = "EnemyUnits"
	battlefield.add_child(enemy_units)

	projectiles = Node2D.new()
	projectiles.name = "Projectiles"
	battlefield.add_child(projectiles)

	wave_manager = Node.new()
	wave_manager.name = "WaveManager"
	wave_manager.set_script(load("res://scenes/battle/wave_manager.gd"))
	add_child(wave_manager)

	GameManager.base_destroyed.connect(_on_base_destroyed)
	wave_manager.all_waves_cleared.connect(_on_all_waves_cleared)
	wave_manager.wave_completed.connect(_on_wave_completed)


func start_level(level_data: Dictionary) -> void:
	_level_data = level_data
	GameManager.setup_level(level_data)
	wave_manager.setup(level_data.get("waves", []), enemy_units)
	hud.update_available_troops(GameManager.available_troops)
	wave_manager.start_next_wave()


func select_troop(troop_type: String) -> void:
	_selected_troop = troop_type
	battlefield.set_deploy_highlight(troop_type != "")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _selected_troop != "":
			_try_deploy(_selected_troop, event.position)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		select_troop("")
		if hud:
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
	return {}


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
```

- [ ] **Step 5: Commit**

```bash
git add scenes/battle/battlefield.gd scenes/battle/battle.gd scenes/battle/battle.tscn
git commit -m "feat: implement Battle scene with battlefield, deployment zone, and troop placement"
```

---

### Task 7: WaveManager

**Files:**
- Create: `scenes/battle/wave_manager.gd`

- [ ] **Step 1: Create `scenes/battle/wave_manager.gd`**

```gdscript
extends Node

signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal all_waves_cleared

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

	# Spawn enemies with delays using a coroutine
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
			await get_tree().create_timer(delay / GameManager.game_speed).timeout


func _on_enemy_removed() -> void:
	_enemies_alive -= 1
	if _enemies_alive <= 0 and _current_wave > 0:
		wave_completed.emit(_current_wave)
		if _current_wave < _waves.size():
			_waiting_for_next_wave = true
			_inter_wave_timer = INTER_WAVE_PAUSE
		else:
			all_waves_cleared.emit()
```

- [ ] **Step 2: Commit**

```bash
git add scenes/battle/wave_manager.gd
git commit -m "feat: implement WaveManager with wave spawning, timing, and progression signals"
```

---

### Task 8: HUD + Deployment UI

**Files:**
- Create: `scenes/battle/hud.gd`
- Create: `scenes/battle/wave_banner.gd`
- Modify: `scenes/battle/battle.gd` — connect HUD

- [ ] **Step 1: Create `scenes/battle/hud.gd`**

```gdscript
extends CanvasLayer

signal troop_selected(troop_type: String)
signal speed_changed(speed: float)
signal pause_toggled(paused: bool)

var _gold_label: Label
var _gems_label: Label
var _wave_label: Label
var _level_label: Label
var _troop_buttons: Dictionary = {}
var _speed_buttons: Dictionary = {}
var _available_troops: Array[String] = []
var _selected_troop: String = ""

const TROOP_INFO := {
	"soldier": {"name": "Soldier", "cost": "30G", "color": Color(0.2, 0.4, 0.9)},
	"archer": {"name": "Archer", "cost": "50G", "color": Color(0.1, 0.7, 0.3)},
	"mage": {"name": "Mage", "cost": "2 Gem", "color": Color(0.6, 0.2, 0.8)},
}


func _ready() -> void:
	layer = 10
	_build_top_bar()
	_build_bottom_bar()
	GameManager.gold_changed.connect(_on_gold_changed)
	GameManager.gems_changed.connect(_on_gems_changed)


func _build_top_bar() -> void:
	var top_bar := PanelContainer.new()
	top_bar.name = "TopBar"
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	top_bar.add_theme_stylebox_override("panel", style)
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.custom_minimum_size = Vector2(0, 50)
	add_child(top_bar)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 30)
	top_bar.add_child(hbox)

	# Gold
	_gold_label = Label.new()
	_gold_label.text = "Gold: 0"
	_gold_label.add_theme_color_override("font_color", Color.GOLD)
	_gold_label.add_theme_font_size_override("font_size", 22)
	hbox.add_child(_gold_label)

	# Gems
	_gems_label = Label.new()
	_gems_label.text = "Gems: 0"
	_gems_label.add_theme_color_override("font_color", Color.CYAN)
	_gems_label.add_theme_font_size_override("font_size", 22)
	hbox.add_child(_gems_label)

	# Spacer
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	# Level name
	_level_label = Label.new()
	_level_label.text = ""
	_level_label.add_theme_font_size_override("font_size", 22)
	hbox.add_child(_level_label)

	# Spacer
	var spacer2 := Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer2)

	# Wave counter
	_wave_label = Label.new()
	_wave_label.text = "Wave: -"
	_wave_label.add_theme_font_size_override("font_size", 22)
	hbox.add_child(_wave_label)


func _build_bottom_bar() -> void:
	var bottom_bar := PanelContainer.new()
	bottom_bar.name = "BottomBar"
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	bottom_bar.add_theme_stylebox_override("panel", style)
	bottom_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_bar.custom_minimum_size = Vector2(0, 70)
	bottom_bar.position = Vector2(0, 1010)
	add_child(bottom_bar)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_bar.add_child(hbox)

	# Troop buttons
	for troop_type in ["soldier", "archer", "mage"]:
		var btn := Button.new()
		btn.name = troop_type.capitalize() + "Btn"
		var info: Dictionary = TROOP_INFO[troop_type]
		btn.text = "%s\n%s" % [info["name"], info["cost"]]
		btn.custom_minimum_size = Vector2(120, 55)
		btn.add_theme_font_size_override("font_size", 16)
		btn.pressed.connect(_on_troop_btn_pressed.bind(troop_type))
		hbox.add_child(btn)
		_troop_buttons[troop_type] = btn

	# Separator
	var sep := VSeparator.new()
	sep.custom_minimum_size = Vector2(30, 0)
	hbox.add_child(sep)

	# Speed buttons
	for spd in ["1x", "2x", "Pause"]:
		var btn := Button.new()
		btn.text = spd
		btn.custom_minimum_size = Vector2(70, 55)
		btn.add_theme_font_size_override("font_size", 16)
		btn.pressed.connect(_on_speed_btn_pressed.bind(spd))
		hbox.add_child(btn)
		_speed_buttons[spd] = btn


func update_available_troops(troops: Array[String]) -> void:
	_available_troops = troops
	for troop_type in _troop_buttons:
		var btn: Button = _troop_buttons[troop_type]
		if troop_type in _available_troops:
			btn.disabled = false
			btn.tooltip_text = ""
		else:
			btn.disabled = true
			btn.text = TROOP_INFO[troop_type]["name"] + "\n[LOCKED]"


func update_wave_info(wave_number: int, total_waves: int) -> void:
	_wave_label.text = "Wave: %d / %d" % [wave_number, total_waves]


func set_level_name(level_name: String) -> void:
	_level_label.text = level_name


func deselect_troop() -> void:
	_selected_troop = ""
	_update_troop_button_styles()


func _on_troop_btn_pressed(troop_type: String) -> void:
	if troop_type not in _available_troops:
		return
	_selected_troop = troop_type
	_update_troop_button_styles()
	troop_selected.emit(troop_type)


func _update_troop_button_styles() -> void:
	for t in _troop_buttons:
		var btn: Button = _troop_buttons[t]
		if t == _selected_troop:
			btn.modulate = Color(1.2, 1.2, 0.5)
		else:
			btn.modulate = Color.WHITE


func _on_speed_btn_pressed(speed_label: String) -> void:
	match speed_label:
		"1x":
			GameManager.game_speed = 1.0
			GameManager.is_battle_active = true
			speed_changed.emit(1.0)
		"2x":
			GameManager.game_speed = 2.0
			GameManager.is_battle_active = true
			speed_changed.emit(2.0)
		"Pause":
			GameManager.game_speed = 0.0
			pause_toggled.emit(true)


func _on_gold_changed(amount: int) -> void:
	_gold_label.text = "Gold: %d" % amount


func _on_gems_changed(amount: int) -> void:
	_gems_label.text = "Gems: %d" % amount
```

- [ ] **Step 2: Create `scenes/battle/wave_banner.gd`**

```gdscript
extends CanvasLayer

var _label: Label
var _panel: PanelContainer
var _tween: Tween


func _ready() -> void:
	layer = 20

	_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.7)
	style.set_corner_radius_all(10)
	_panel.add_theme_stylebox_override("panel", style)
	_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_panel.position = Vector2(760, 150)
	_panel.modulate.a = 0.0
	add_child(_panel)

	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 36)
	_label.custom_minimum_size = Vector2(400, 60)
	_panel.add_child(_label)


func show_banner(text: String, duration: float = 2.0) -> void:
	_label.text = text
	if _tween and _tween.is_running():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_panel, "modulate:a", 1.0, 0.3)
	_tween.tween_interval(duration)
	_tween.tween_property(_panel, "modulate:a", 0.0, 0.5)
```

- [ ] **Step 3: Update `scenes/battle/battle.gd` — integrate HUD and banner**

Add to `_ready()` in battle.gd, after the wave_manager setup:

```gdscript
	# HUD
	hud = CanvasLayer.new()
	hud.name = "HUD"
	hud.set_script(load("res://scenes/battle/hud.gd"))
	add_child(hud)
	hud.troop_selected.connect(select_troop)

	# Wave banner
	var banner := CanvasLayer.new()
	banner.name = "WaveBanner"
	banner.set_script(load("res://scenes/battle/wave_banner.gd"))
	add_child(banner)

	wave_manager.wave_started.connect(_on_wave_started)
```

Add this new variable at the top of battle.gd:

```gdscript
var wave_banner: Node
```

Add this to the end of `_ready()`:

```gdscript
	wave_banner = $WaveBanner
```

Add this method to battle.gd:

```gdscript
func _on_wave_started(wave_number: int) -> void:
	var total := _level_data.get("waves", []).size()
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
```

Also add `hud.set_level_name(level_data.get("level_name", ""))` in `start_level()` after `hud.update_available_troops(...)`.

Here is the **complete final `scenes/battle/battle.gd`** with all integrations:

```gdscript
extends Node2D

signal level_won
signal level_lost

var _selected_troop: String = ""
var _level_data: Dictionary = {}

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

	# Connect signals
	GameManager.base_destroyed.connect(_on_base_destroyed)
	wave_manager.all_waves_cleared.connect(_on_all_waves_cleared)
	wave_manager.wave_completed.connect(_on_wave_completed)
	wave_manager.wave_started.connect(_on_wave_started)


func start_level(level_data: Dictionary) -> void:
	_level_data = level_data
	GameManager.setup_level(level_data)
	wave_manager.setup(level_data.get("waves", []), enemy_units)
	hud.update_available_troops(GameManager.available_troops)
	hud.set_level_name(level_data.get("level_name", ""))
	wave_manager.start_next_wave()


func select_troop(troop_type: String) -> void:
	_selected_troop = troop_type
	battlefield.set_deploy_highlight(troop_type != "")


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
	return {}


func _on_wave_started(wave_number: int) -> void:
	var total := _level_data.get("waves", []).size()
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
```

- [ ] **Step 4: Commit**

```bash
git add scenes/battle/hud.gd scenes/battle/wave_banner.gd scenes/battle/battle.gd
git commit -m "feat: implement HUD with resource display, troop buttons, speed controls, and wave banner"
```

---

### Task 9: Archer + Arrow Projectile

**Files:**
- Create: `entities/projectiles/arrow.gd`
- Create: `entities/projectiles/arrow.tscn`
- Create: `entities/units/archer.gd`
- Create: `entities/units/archer.tscn`

- [ ] **Step 1: Create `entities/projectiles/arrow.gd`**

```gdscript
extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 500.0
var damage: int = 8
var _max_range: float = 400.0
var _traveled: float = 0.0


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 4.0
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)
	# Only detect enemies
	collision_layer = 0
	collision_mask = 2


func _draw() -> void:
	draw_line(-direction * 8, direction * 8, Color(0.6, 0.4, 0.1), 3.0)
	draw_circle(direction * 8, 2.0, Color(0.8, 0.6, 0.2))


func _physics_process(delta: float) -> void:
	var movement := direction * speed * delta * GameManager.game_speed
	position += movement
	_traveled += movement.length()
	if _traveled >= _max_range:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage") and body.is_in_group("enemies"):
		body.take_damage(damage)
		queue_free()
```

- [ ] **Step 2: Create `entities/projectiles/arrow.tscn`**

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://entities/projectiles/arrow.gd" id="1"]

[node name="Arrow" type="Area2D"]
script = ExtResource("1")
```

- [ ] **Step 3: Create `entities/units/archer.gd`**

```gdscript
extends BaseUnit

var _arrow_scene: PackedScene


func _ready() -> void:
	max_hp = 50
	damage = 8
	attack_speed = 0.8
	move_speed = 90.0
	attack_range = 300.0
	unit_color = Color(0.1, 0.7, 0.3)  # Green
	unit_radius = 13.0
	_arrow_scene = load("res://entities/projectiles/arrow.tscn")
	super._ready()


func _perform_attack() -> void:
	if not target or not is_instance_valid(target):
		return
	var arrow := _arrow_scene.instantiate()
	arrow.position = global_position
	arrow.direction = (target.global_position - global_position).normalized()
	arrow.damage = damage
	arrow.rotation = arrow.direction.angle()
	# Add to projectiles container
	var proj_container := get_tree().current_scene.find_child("Projectiles", true, false)
	if proj_container:
		arrow.position = global_position
		proj_container.add_child(arrow)
	else:
		get_parent().add_child(arrow)


func _draw() -> void:
	# Body — slightly different shape to distinguish from soldier
	draw_circle(Vector2.ZERO, unit_radius, unit_color)
	# Bow indicator
	draw_arc(Vector2(unit_radius * 0.3, 0), unit_radius * 0.6, -PI / 3, PI / 3, 12, Color.SADDLE_BROWN, 2.0)
	# HP bar
	var bar_w := unit_radius * 2.2
	var bar_h := 4.0
	var bar_y := -unit_radius - 10.0
	var hp_ratio := float(hp) / float(max_hp)
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w, bar_h), Color(0.2, 0.2, 0.2))
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w * hp_ratio, bar_h), Color.GREEN_YELLOW)
```

- [ ] **Step 4: Create `entities/units/archer.tscn`**

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://entities/units/archer.gd" id="1"]

[node name="Archer" type="CharacterBody2D"]
script = ExtResource("1")
```

- [ ] **Step 5: Commit**

```bash
git add entities/projectiles/arrow.gd entities/projectiles/arrow.tscn entities/units/archer.gd entities/units/archer.tscn
git commit -m "feat: implement Archer troop with ranged attack and Arrow projectile"
```

---

### Task 10: Mage + Magic Bolt

**Files:**
- Create: `entities/projectiles/magic_bolt.gd`
- Create: `entities/projectiles/magic_bolt.tscn`
- Create: `entities/units/mage.gd`
- Create: `entities/units/mage.tscn`

- [ ] **Step 1: Create `entities/projectiles/magic_bolt.gd`**

```gdscript
extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 350.0
var damage: int = 15
var aoe_radius: float = 90.0
var _max_range: float = 350.0
var _traveled: float = 0.0
var _target_pos: Vector2


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 6.0
	shape.shape = circle
	add_child(shape)
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)


func _draw() -> void:
	draw_circle(Vector2.ZERO, 8.0, Color(0.6, 0.2, 0.9, 0.8))
	draw_circle(Vector2.ZERO, 4.0, Color(0.9, 0.6, 1.0))


func setup(target_position: Vector2) -> void:
	_target_pos = target_position
	direction = (target_position - global_position).normalized()


func _physics_process(delta: float) -> void:
	var movement := direction * speed * delta * GameManager.game_speed
	position += movement
	_traveled += movement.length()

	# Check if reached target area
	if global_position.distance_to(_target_pos) < 20.0 or _traveled >= _max_range:
		_explode()


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage") and body.is_in_group("enemies"):
		_explode()


func _explode() -> void:
	# Deal AoE damage to all enemies in radius
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy):
			if global_position.distance_to(enemy.global_position) <= aoe_radius:
				enemy.take_damage(damage)
	queue_free()
```

- [ ] **Step 2: Create `entities/projectiles/magic_bolt.tscn`**

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://entities/projectiles/magic_bolt.gd" id="1"]

[node name="MagicBolt" type="Area2D"]
script = ExtResource("1")
```

- [ ] **Step 3: Create `entities/units/mage.gd`**

```gdscript
extends BaseUnit

var _bolt_scene: PackedScene
var _aoe_radius: float = 90.0


func _ready() -> void:
	max_hp = 40
	damage = 15
	attack_speed = 1.5
	move_speed = 75.0
	attack_range = 270.0
	unit_color = Color(0.6, 0.2, 0.8)  # Purple
	unit_radius = 13.0
	_bolt_scene = load("res://entities/projectiles/magic_bolt.tscn")
	super._ready()


func _find_target() -> Node2D:
	# Mage targets the position with most enemies clustered together
	var enemies := get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return null

	var best_target: Node2D = null
	var best_count := 0

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		# Count enemies within AoE radius of this enemy
		var count := 0
		for other in enemies:
			if is_instance_valid(other) and enemy.global_position.distance_to(other.global_position) <= _aoe_radius:
				count += 1
		if count > best_count or (count == best_count and (best_target == null or global_position.distance_to(enemy.global_position) < global_position.distance_to(best_target.global_position))):
			best_count = count
			best_target = enemy

	return best_target


func _perform_attack() -> void:
	if not target or not is_instance_valid(target):
		return
	var bolt := _bolt_scene.instantiate()
	bolt.position = global_position
	bolt.damage = damage
	bolt.aoe_radius = _aoe_radius
	bolt.setup(target.global_position)
	var proj_container := get_tree().current_scene.find_child("Projectiles", true, false)
	if proj_container:
		bolt.position = global_position
		proj_container.add_child(bolt)
	else:
		get_parent().add_child(bolt)


func _draw() -> void:
	# Body
	draw_circle(Vector2.ZERO, unit_radius, unit_color)
	# Star/magic indicator
	var star_points := PackedVector2Array()
	for i in range(5):
		var angle := -PI / 2 + i * TAU / 5
		star_points.append(Vector2.from_angle(angle) * unit_radius * 0.5)
		angle += TAU / 10
		star_points.append(Vector2.from_angle(angle) * unit_radius * 0.25)
	draw_colored_polygon(star_points, Color(1.0, 0.9, 0.3))
	# HP bar
	var bar_w := unit_radius * 2.2
	var bar_h := 4.0
	var bar_y := -unit_radius - 10.0
	var hp_ratio := float(hp) / float(max_hp)
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w, bar_h), Color(0.2, 0.2, 0.2))
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w * hp_ratio, bar_h), Color.GREEN_YELLOW)
```

- [ ] **Step 4: Create `entities/units/mage.tscn`**

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://entities/units/mage.gd" id="1"]

[node name="Mage" type="CharacterBody2D"]
script = ExtResource("1")
```

- [ ] **Step 5: Commit**

```bash
git add entities/projectiles/magic_bolt.gd entities/projectiles/magic_bolt.tscn entities/units/mage.gd entities/units/mage.tscn
git commit -m "feat: implement Mage troop with AoE magic bolt and cluster targeting"
```

---

### Task 11: Orc + Goblin Archer

**Files:**
- Create: `entities/enemies/orc.gd`
- Create: `entities/enemies/orc.tscn`
- Create: `entities/enemies/goblin_archer.gd`
- Create: `entities/enemies/goblin_archer.tscn`

- [ ] **Step 1: Create `entities/enemies/orc.gd`**

```gdscript
extends BaseEnemy

func _ready() -> void:
	max_hp = 150
	damage = 12
	attack_speed = 1.5
	move_speed = 75.0
	attack_range = 45.0
	base_damage = 30
	bounty_gold = 15
	enemy_color = Color(0.5, 0.3, 0.1)  # Brown
	enemy_radius = 18.0
	super._ready()


func _draw() -> void:
	# Bigger, chunkier body
	draw_circle(Vector2.ZERO, enemy_radius, enemy_color)
	draw_arc(Vector2.ZERO, enemy_radius, 0, TAU, 32, enemy_color.darkened(0.4), 3.0)
	# Shield indicator
	draw_arc(Vector2(-4, 0), enemy_radius * 0.5, PI / 2, 3 * PI / 2, 12, Color(0.4, 0.4, 0.4), 3.0)
	# HP bar
	var bar_w := enemy_radius * 2.2
	var bar_h := 5.0
	var bar_y := -enemy_radius - 10.0
	var hp_ratio := float(hp) / float(max_hp)
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w, bar_h), Color(0.2, 0.2, 0.2))
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w * hp_ratio, bar_h), Color.ORANGE_RED)
```

- [ ] **Step 2: Create `entities/enemies/orc.tscn`**

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://entities/enemies/orc.gd" id="1"]

[node name="Orc" type="CharacterBody2D"]
script = ExtResource("1")
```

- [ ] **Step 3: Create `entities/enemies/goblin_archer.gd`**

```gdscript
extends BaseEnemy

var _arrow_scene: PackedScene


func _ready() -> void:
	max_hp = 60
	damage = 7
	attack_speed = 1.0
	move_speed = 120.0
	attack_range = 225.0
	base_damage = 10
	bounty_gold = 10
	enemy_color = Color(0.3, 0.6, 0.15)  # Dark green
	enemy_radius = 12.0
	_arrow_scene = load("res://entities/projectiles/arrow.tscn")
	super._ready()


func _find_aggro_target() -> Node2D:
	# Goblin archers also attack from range, so use attack_range for aggro instead of AGGRO_RANGE
	var units := get_tree().get_nodes_in_group("player_units")
	var closest: Node2D = null
	var closest_dist := attack_range
	for unit in units:
		if not is_instance_valid(unit):
			continue
		var d := global_position.distance_to(unit.global_position)
		if d < closest_dist:
			closest_dist = d
			closest = unit
	return closest


func _perform_attack() -> void:
	if not target or not is_instance_valid(target):
		return
	var arrow := _arrow_scene.instantiate()
	arrow.position = global_position
	arrow.direction = (target.global_position - global_position).normalized()
	arrow.damage = damage
	arrow.rotation = arrow.direction.angle()
	# Enemy arrows should hit player units
	arrow.collision_layer = 0
	arrow.collision_mask = 1
	var proj_container := get_tree().current_scene.find_child("Projectiles", true, false)
	if proj_container:
		arrow.position = global_position
		proj_container.add_child(arrow)
	else:
		get_parent().add_child(arrow)


func _draw() -> void:
	draw_circle(Vector2.ZERO, enemy_radius, enemy_color)
	# Bow indicator
	draw_arc(Vector2(-enemy_radius * 0.3, 0), enemy_radius * 0.5, PI / 2, 3 * PI / 2, 8, Color(0.5, 0.3, 0.1), 2.0)
	# HP bar
	var bar_w := enemy_radius * 2.2
	var bar_h := 4.0
	var bar_y := -enemy_radius - 10.0
	var hp_ratio := float(hp) / float(max_hp)
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w, bar_h), Color(0.2, 0.2, 0.2))
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w * hp_ratio, bar_h), Color.ORANGE_RED)
```

Note: The arrow projectile needs a fix — the `_on_body_entered` callback checks for `enemies` group, but goblin archer arrows should hit `player_units`. We fix this by modifying the arrow to check dynamically.

- [ ] **Step 4: Update `entities/projectiles/arrow.gd` to support both sides**

Replace the full file:

```gdscript
extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 500.0
var damage: int = 8
var _max_range: float = 400.0
var _traveled: float = 0.0
var target_group: String = "enemies"


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 4.0
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)


func _draw() -> void:
	draw_line(-direction.normalized() * 8, direction.normalized() * 8, Color(0.6, 0.4, 0.1), 3.0)
	draw_circle(direction.normalized() * 8, 2.0, Color(0.8, 0.6, 0.2))


func _physics_process(delta: float) -> void:
	var movement := direction * speed * delta * GameManager.game_speed
	position += movement
	_traveled += movement.length()
	if _traveled >= _max_range:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage") and body.is_in_group(target_group):
		body.take_damage(damage)
		queue_free()
```

Update `entities/units/archer.gd` `_perform_attack()` to set `target_group`:

```gdscript
func _perform_attack() -> void:
	if not target or not is_instance_valid(target):
		return
	var arrow := _arrow_scene.instantiate()
	arrow.position = global_position
	arrow.direction = (target.global_position - global_position).normalized()
	arrow.damage = damage
	arrow.rotation = arrow.direction.angle()
	arrow.target_group = "enemies"
	arrow.collision_layer = 0
	arrow.collision_mask = 2
	var proj_container := get_tree().current_scene.find_child("Projectiles", true, false)
	if proj_container:
		proj_container.add_child(arrow)
	else:
		get_parent().add_child(arrow)
```

And `entities/enemies/goblin_archer.gd` `_perform_attack()` already sets collision_mask = 1. Also set `target_group`:

```gdscript
func _perform_attack() -> void:
	if not target or not is_instance_valid(target):
		return
	var arrow := _arrow_scene.instantiate()
	arrow.position = global_position
	arrow.direction = (target.global_position - global_position).normalized()
	arrow.damage = damage
	arrow.rotation = arrow.direction.angle()
	arrow.target_group = "player_units"
	arrow.collision_layer = 0
	arrow.collision_mask = 1
	var proj_container := get_tree().current_scene.find_child("Projectiles", true, false)
	if proj_container:
		proj_container.add_child(arrow)
	else:
		get_parent().add_child(arrow)
```

- [ ] **Step 5: Create `entities/enemies/goblin_archer.tscn`**

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://entities/enemies/goblin_archer.gd" id="1"]

[node name="GoblinArcher" type="CharacterBody2D"]
script = ExtResource("1")
```

- [ ] **Step 6: Commit**

```bash
git add entities/enemies/orc.gd entities/enemies/orc.tscn entities/enemies/goblin_archer.gd entities/enemies/goblin_archer.tscn entities/projectiles/arrow.gd entities/units/archer.gd
git commit -m "feat: implement Orc and Goblin Archer enemies, fix arrow to support both sides"
```

---

### Task 12: Level Data (5 Levels)

**Files:**
- Create: `data/levels/level_1.json` through `data/levels/level_5.json`

- [ ] **Step 1: Create `data/levels/level_1.json` — Tutorial**

```json
{
  "level_name": "Green Meadow",
  "base_hp": 100,
  "starting_resources": {"gold": 100, "gems": 0},
  "gold_per_second": 5,
  "available_troops": ["soldier"],
  "waves": [
    {
      "enemies": [
        {"type": "goblin", "count": 3, "spawn_delay": 1.5, "spawn_y_range": [0.3, 0.7]}
      ],
      "reward": {"gold": 40, "gems": 0}
    },
    {
      "enemies": [
        {"type": "goblin", "count": 5, "spawn_delay": 1.2, "spawn_y_range": [0.2, 0.8]}
      ],
      "reward": {"gold": 50, "gems": 0}
    },
    {
      "enemies": [
        {"type": "goblin", "count": 8, "spawn_delay": 1.0, "spawn_y_range": [0.2, 0.8]}
      ],
      "reward": {"gold": 60, "gems": 0}
    }
  ]
}
```

- [ ] **Step 2: Create `data/levels/level_2.json` — Archers Unlocked**

```json
{
  "level_name": "Forest Edge",
  "base_hp": 100,
  "starting_resources": {"gold": 120, "gems": 0},
  "gold_per_second": 5,
  "available_troops": ["soldier", "archer"],
  "waves": [
    {
      "enemies": [
        {"type": "goblin", "count": 5, "spawn_delay": 1.2, "spawn_y_range": [0.2, 0.8]}
      ],
      "reward": {"gold": 40, "gems": 0}
    },
    {
      "enemies": [
        {"type": "goblin", "count": 4, "spawn_delay": 1.0, "spawn_y_range": [0.3, 0.7]},
        {"type": "orc", "count": 1, "spawn_delay": 3.0, "spawn_y_range": [0.4, 0.6]}
      ],
      "reward": {"gold": 50, "gems": 0}
    },
    {
      "enemies": [
        {"type": "goblin", "count": 6, "spawn_delay": 0.8, "spawn_y_range": [0.2, 0.8]},
        {"type": "orc", "count": 2, "spawn_delay": 2.5, "spawn_y_range": [0.3, 0.7]}
      ],
      "reward": {"gold": 60, "gems": 1}
    },
    {
      "enemies": [
        {"type": "goblin", "count": 8, "spawn_delay": 0.8, "spawn_y_range": [0.2, 0.8]},
        {"type": "orc", "count": 3, "spawn_delay": 2.0, "spawn_y_range": [0.3, 0.7]}
      ],
      "reward": {"gold": 70, "gems": 1}
    }
  ]
}
```

- [ ] **Step 3: Create `data/levels/level_3.json` — Mage + Goblin Archers**

```json
{
  "level_name": "Dark Forest",
  "base_hp": 120,
  "starting_resources": {"gold": 100, "gems": 2},
  "gold_per_second": 6,
  "available_troops": ["soldier", "archer", "mage"],
  "waves": [
    {
      "enemies": [
        {"type": "goblin", "count": 6, "spawn_delay": 1.0, "spawn_y_range": [0.2, 0.8]},
        {"type": "goblin_archer", "count": 2, "spawn_delay": 2.0, "spawn_y_range": [0.3, 0.7]}
      ],
      "reward": {"gold": 50, "gems": 1}
    },
    {
      "enemies": [
        {"type": "goblin", "count": 4, "spawn_delay": 0.8, "spawn_y_range": [0.2, 0.5]},
        {"type": "orc", "count": 2, "spawn_delay": 2.5, "spawn_y_range": [0.5, 0.8]},
        {"type": "goblin_archer", "count": 3, "spawn_delay": 1.5, "spawn_y_range": [0.3, 0.7]}
      ],
      "reward": {"gold": 60, "gems": 1}
    },
    {
      "enemies": [
        {"type": "goblin", "count": 8, "spawn_delay": 0.7, "spawn_y_range": [0.2, 0.8]},
        {"type": "orc", "count": 3, "spawn_delay": 2.0, "spawn_y_range": [0.3, 0.7]},
        {"type": "goblin_archer", "count": 4, "spawn_delay": 1.2, "spawn_y_range": [0.2, 0.8]}
      ],
      "reward": {"gold": 70, "gems": 2}
    }
  ]
}
```

- [ ] **Step 4: Create `data/levels/level_4.json` — Mixed Compositions**

```json
{
  "level_name": "Rocky Pass",
  "base_hp": 100,
  "starting_resources": {"gold": 80, "gems": 1},
  "gold_per_second": 5,
  "available_troops": ["soldier", "archer", "mage"],
  "waves": [
    {
      "enemies": [
        {"type": "orc", "count": 3, "spawn_delay": 2.0, "spawn_y_range": [0.3, 0.7]},
        {"type": "goblin_archer", "count": 3, "spawn_delay": 1.5, "spawn_y_range": [0.2, 0.8]}
      ],
      "reward": {"gold": 50, "gems": 1}
    },
    {
      "enemies": [
        {"type": "goblin", "count": 10, "spawn_delay": 0.6, "spawn_y_range": [0.2, 0.8]}
      ],
      "reward": {"gold": 40, "gems": 0}
    },
    {
      "enemies": [
        {"type": "orc", "count": 4, "spawn_delay": 1.5, "spawn_y_range": [0.4, 0.6]},
        {"type": "goblin", "count": 6, "spawn_delay": 0.8, "spawn_y_range": [0.2, 0.8]},
        {"type": "goblin_archer", "count": 4, "spawn_delay": 1.0, "spawn_y_range": [0.2, 0.8]}
      ],
      "reward": {"gold": 60, "gems": 1}
    },
    {
      "enemies": [
        {"type": "orc", "count": 5, "spawn_delay": 1.2, "spawn_y_range": [0.3, 0.7]},
        {"type": "goblin", "count": 8, "spawn_delay": 0.6, "spawn_y_range": [0.2, 0.8]},
        {"type": "goblin_archer", "count": 5, "spawn_delay": 1.0, "spawn_y_range": [0.2, 0.8]}
      ],
      "reward": {"gold": 80, "gems": 2}
    }
  ]
}
```

- [ ] **Step 5: Create `data/levels/level_5.json` — Final Stand**

```json
{
  "level_name": "The Last Stand",
  "base_hp": 120,
  "starting_resources": {"gold": 100, "gems": 2},
  "gold_per_second": 6,
  "available_troops": ["soldier", "archer", "mage"],
  "waves": [
    {
      "enemies": [
        {"type": "goblin", "count": 10, "spawn_delay": 0.5, "spawn_y_range": [0.2, 0.8]},
        {"type": "goblin_archer", "count": 4, "spawn_delay": 1.0, "spawn_y_range": [0.3, 0.7]}
      ],
      "reward": {"gold": 50, "gems": 1}
    },
    {
      "enemies": [
        {"type": "orc", "count": 5, "spawn_delay": 1.5, "spawn_y_range": [0.3, 0.7]},
        {"type": "goblin_archer", "count": 5, "spawn_delay": 1.0, "spawn_y_range": [0.2, 0.8]}
      ],
      "reward": {"gold": 60, "gems": 1}
    },
    {
      "enemies": [
        {"type": "goblin", "count": 12, "spawn_delay": 0.4, "spawn_y_range": [0.2, 0.8]},
        {"type": "orc", "count": 4, "spawn_delay": 1.2, "spawn_y_range": [0.3, 0.7]},
        {"type": "goblin_archer", "count": 6, "spawn_delay": 0.8, "spawn_y_range": [0.2, 0.8]}
      ],
      "reward": {"gold": 70, "gems": 2}
    },
    {
      "enemies": [
        {"type": "orc", "count": 6, "spawn_delay": 1.0, "spawn_y_range": [0.3, 0.7]},
        {"type": "goblin", "count": 15, "spawn_delay": 0.3, "spawn_y_range": [0.1, 0.9]},
        {"type": "goblin_archer", "count": 8, "spawn_delay": 0.6, "spawn_y_range": [0.2, 0.8]}
      ],
      "reward": {"gold": 100, "gems": 3}
    },
    {
      "enemies": [
        {"type": "orc", "count": 8, "spawn_delay": 0.8, "spawn_y_range": [0.2, 0.8]},
        {"type": "goblin", "count": 20, "spawn_delay": 0.3, "spawn_y_range": [0.1, 0.9]},
        {"type": "goblin_archer", "count": 10, "spawn_delay": 0.5, "spawn_y_range": [0.1, 0.9]}
      ],
      "reward": {"gold": 150, "gems": 5}
    }
  ]
}
```

- [ ] **Step 6: Commit**

```bash
git add data/levels/
git commit -m "feat: add 5 campaign levels with progressive difficulty and enemy variety"
```

---

### Task 13: Level Result Screen

**Files:**
- Create: `scenes/level_result/level_result.gd`
- Create: `scenes/level_result/level_result.tscn`

- [ ] **Step 1: Create `scenes/level_result/level_result.gd`**

```gdscript
extends Control

signal next_level_requested
signal retry_requested
signal back_to_menu_requested

var _title_label: Label
var _message_label: Label
var _next_btn: Button
var _retry_btn: Button
var _menu_btn: Button


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	# Darken background
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.7)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Center container
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.position = Vector2(760, 340)
	vbox.custom_minimum_size = Vector2(400, 300)
	vbox.add_theme_constant_override("separation", 20)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(vbox)

	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 48)
	vbox.add_child(_title_label)

	_message_label = Label.new()
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(_message_label)

	var btn_container := HBoxContainer.new()
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_container)

	_retry_btn = Button.new()
	_retry_btn.text = "Retry"
	_retry_btn.custom_minimum_size = Vector2(120, 45)
	_retry_btn.add_theme_font_size_override("font_size", 20)
	_retry_btn.pressed.connect(func(): retry_requested.emit())
	btn_container.add_child(_retry_btn)

	_next_btn = Button.new()
	_next_btn.text = "Next Level"
	_next_btn.custom_minimum_size = Vector2(150, 45)
	_next_btn.add_theme_font_size_override("font_size", 20)
	_next_btn.pressed.connect(func(): next_level_requested.emit())
	btn_container.add_child(_next_btn)

	_menu_btn = Button.new()
	_menu_btn.text = "Menu"
	_menu_btn.custom_minimum_size = Vector2(120, 45)
	_menu_btn.add_theme_font_size_override("font_size", 20)
	_menu_btn.pressed.connect(func(): back_to_menu_requested.emit())
	btn_container.add_child(_menu_btn)


func show_victory() -> void:
	_title_label.text = "Victory!"
	_title_label.add_theme_color_override("font_color", Color.GOLD)
	_message_label.text = "Level Complete!"
	_next_btn.visible = true
	_retry_btn.visible = true
	visible = true


func show_defeat() -> void:
	_title_label.text = "Defeat"
	_title_label.add_theme_color_override("font_color", Color.RED)
	_message_label.text = "Your base was destroyed."
	_next_btn.visible = false
	_retry_btn.visible = true
	visible = true
```

- [ ] **Step 2: Create `scenes/level_result/level_result.tscn`**

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scenes/level_result/level_result.gd" id="1"]

[node name="LevelResult" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
visible = false
script = ExtResource("1")
```

- [ ] **Step 3: Commit**

```bash
git add scenes/level_result/level_result.gd scenes/level_result/level_result.tscn
git commit -m "feat: implement LevelResult screen with victory/defeat states and navigation"
```

---

### Task 14: Main Menu + Level Select

**Files:**
- Modify: `scenes/main_menu/main_menu.gd`
- Create: `scenes/level_select/level_select.gd`
- Create: `scenes/level_select/level_select.tscn`

- [ ] **Step 1: Update `scenes/main_menu/main_menu.gd`**

```gdscript
extends Control


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	# Background
	var bg := ColorRect.new()
	bg.color = Color(0.12, 0.15, 0.2)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.position = Vector2(810, 300)
	vbox.custom_minimum_size = Vector2(300, 400)
	vbox.add_theme_constant_override("separation", 30)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "TOWER DEFENSE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color.GOLD)
	vbox.add_child(title)

	# Subtitle
	var subtitle := Label.new()
	subtitle.text = "Defend the Kingdom"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	vbox.add_child(subtitle)

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(spacer)

	# Play button
	var play_btn := Button.new()
	play_btn.text = "Play"
	play_btn.custom_minimum_size = Vector2(200, 55)
	play_btn.add_theme_font_size_override("font_size", 26)
	play_btn.pressed.connect(_on_play)
	vbox.add_child(play_btn)

	# Quit button
	var quit_btn := Button.new()
	quit_btn.text = "Quit"
	quit_btn.custom_minimum_size = Vector2(200, 55)
	quit_btn.add_theme_font_size_override("font_size", 26)
	quit_btn.pressed.connect(_on_quit)
	vbox.add_child(quit_btn)


func _on_play() -> void:
	get_tree().change_scene_to_file("res://scenes/level_select/level_select.tscn")


func _on_quit() -> void:
	get_tree().quit()
```

- [ ] **Step 2: Create `scenes/level_select/level_select.gd`**

```gdscript
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
	var hbox := HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_CENTER)
	hbox.position = Vector2(560, 440)
	hbox.add_theme_constant_override("separation", 40)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(hbox)

	for i in range(1, LEVEL_COUNT + 1):
		var level_data := _load_level_data(i)
		var level_name: String = level_data.get("level_name", "Level %d" % i)
		var unlocked := GameManager.is_level_unlocked(i)
		var completed := GameManager.campaign_progress.get(str(i), false)

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

	# Draw path lines between levels
	queue_redraw()


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
	# Load the battle scene and start the level
	var battle_scene := load("res://scenes/battle/battle.tscn").instantiate()
	get_tree().root.add_child(battle_scene)

	# Load level data
	var level_data := _load_level_data(level)

	# Connect result signals
	battle_scene.level_won.connect(_on_level_won.bind(level, battle_scene))
	battle_scene.level_lost.connect(_on_level_lost.bind(level, battle_scene))

	# Add level result overlay
	var result_scene := load("res://scenes/level_result/level_result.tscn").instantiate()
	battle_scene.add_child(result_scene)

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
	var result := battle_scene.find_child("LevelResult", true, false)
	if result:
		result.show_victory()


func _on_level_lost(level: int, battle_scene: Node) -> void:
	var result := battle_scene.find_child("LevelResult", true, false)
	if result:
		result.show_defeat()


func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
```

- [ ] **Step 3: Create `scenes/level_select/level_select.tscn`**

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scenes/level_select/level_select.gd" id="1"]

[node name="LevelSelect" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1")
```

- [ ] **Step 4: Verify — run the game**

Launch the game. Main menu should appear with "TOWER DEFENSE" title and Play/Quit buttons. Click Play → Level Select shows 5 levels, only Level 1 unlocked. Click Level 1 → Battle starts with goblins spawning and a HUD. Deploy soldiers by clicking the Soldier button then clicking in the deployment zone.

- [ ] **Step 5: Commit**

```bash
git add scenes/main_menu/main_menu.gd scenes/main_menu/main_menu.tscn scenes/level_select/level_select.gd scenes/level_select/level_select.tscn
git commit -m "feat: implement Main Menu, Level Select with progression, and game flow integration"
```

---

### Task 15: Final Integration + Polish

**Files:**
- Modify: `scenes/battle/battle.tscn` (ensure clean)
- Verify all game flow end-to-end

- [ ] **Step 1: Update `scenes/battle/battle.tscn` — minimal clean version**

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scenes/battle/battle.gd" id="1"]

[node name="Battle" type="Node2D"]
script = ExtResource("1")
```

- [ ] **Step 2: Add mouse cursor feedback for deployment**

Add to `scenes/battle/battle.gd` — a `_process` method for cursor hint:

```gdscript
func _process(_delta: float) -> void:
	if _selected_troop != "":
		var mouse_pos := get_viewport().get_mouse_position()
		var in_zone := mouse_pos.x >= battlefield.DEPLOY_ZONE_START_X and mouse_pos.x <= battlefield.DEPLOY_ZONE_END_X and mouse_pos.y >= 80.0 and mouse_pos.y <= 1000.0
		if in_zone:
			Input.set_default_cursor_shape(Input.CURSOR_CROSS)
		else:
			Input.set_default_cursor_shape(Input.CURSOR_FORBIDDEN)
	else:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
```

- [ ] **Step 3: Full end-to-end verification**

1. Launch game → Main Menu appears
2. Click "Play" → Level Select appears, Level 1 unlocked
3. Click Level 1 → Battle starts: "Green Meadow", Wave 1 banner, goblins spawn
4. Click "Soldier" button → deployment zone highlights
5. Click in deployment zone → soldier placed, 30 gold deducted
6. Soldiers fight goblins autonomously
7. Goblins killed → gold bounties added
8. All waves cleared → "Victory!" screen
9. Click "Next Level" → Level 2 starts with archers available
10. Click "Menu" → back to Level Select, Level 1 shows checkmark
11. Quit → relaunch → progress persisted (Level 2 unlocked)

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat: complete game integration with deployment cursor, full game flow end-to-end"
```

---

## Self-Review Checklist

**Spec coverage:**
- ✅ Top-down open battlefield — battlefield.gd
- ✅ Base on left, enemies from right — player_base at x=70, enemies spawn at x=1920
- ✅ Deployment zone (leftmost 25% after base) — DEPLOY_ZONE_START_X/END_X in battlefield.gd
- ✅ Gold (passive + bounty) + Gems — GameManager._process + bounty in base_enemy._die
- ✅ 3 troops: Soldier, Archer, Mage — Tasks 3, 9, 10
- ✅ 3 enemies: Goblin, Orc, Goblin Archer — Tasks 4, 11
- ✅ Unit AI (autonomous behavior) — base_unit._physics_process, base_enemy._physics_process
- ✅ Mage cluster targeting — mage._find_target
- ✅ Enemy aggro range (120px) — base_enemy.AGGRO_RANGE
- ✅ Unit collision (troops block enemies, allies overlap) — collision layers
- ✅ Wave system with inter-wave pause — wave_manager.gd
- ✅ Win/Lose conditions — battle.gd _check_victory/_on_base_destroyed
- ✅ Campaign 5 levels — level_1.json through level_5.json
- ✅ Unlock progression (Soldier → +Archer → +Mage) — available_troops in JSON
- ✅ Main Menu, Level Select, Battle, Level Result screens — Tasks 14, 13
- ✅ HUD (top bar + bottom bar) — hud.gd
- ✅ Speed controls (1x/2x/Pause) — hud.gd + GameManager.game_speed
- ✅ Save system — GameManager.save_progress/load_progress
- ✅ Wave announcement banners — wave_banner.gd
- ✅ 1920×1080 resolution — project.godot

**Placeholder scan:** No TBD, TODO, or "implement later" found. All code blocks complete.

**Type consistency:** All method names, signal names, and property names verified consistent across tasks. `target_group` on arrows used consistently. `wave_started`/`wave_completed`/`all_waves_cleared` signals match between wave_manager and battle.gd.
