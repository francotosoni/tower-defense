extends BaseUnit
class_name Miner

# --- Stats ---
const MINER_MAX_HP    := 25
const MINER_DAMAGE    := 0
const MINER_SPEED     := 100.0
const MINER_RADIUS    := 10.0

# --- State machine ---
enum State { SEARCHING, WALKING_TO_NODE, MINING, RETURNING, IDLE }
var _state: State = State.SEARCHING

# --- Harvest bookkeeping ---
var _resource_node: ResourceNode = null
var _mine_timer: float = 0.0
var _mine_duration: float = 0.0
var _carried_type: ResourceNode.ResourceType = ResourceNode.ResourceType.GOLD
var _carried_amount: int = 0
var _is_carrying: bool = false

# --- Pickaxe animation ---
var _pickaxe_angle: float = 0.0
var _pickaxe_swing: float = 0.0  # 0..1 progress through a swing

# --- Scene reference for dropped loot ---
const DroppedLootScene := preload("res://entities/resources/dropped_loot.tscn")


func _ready() -> void:
	max_hp      = MINER_MAX_HP
	damage      = MINER_DAMAGE
	move_speed  = MINER_SPEED
	unit_radius = MINER_RADIUS
	unit_color  = Color(0.55, 0.38, 0.20)  # brown work clothes
	super._ready()


# ---- Override: Miner never auto-attacks --------------------------------
func _find_target() -> Node2D:
	return null


# ---- Override: drop loot on death -------------------------------------
func _die() -> void:
	if _is_carrying and _carried_amount > 0:
		var loot: DroppedLoot = DroppedLootScene.instantiate()
		loot.setup(_carried_type, _carried_amount)
		loot.global_position = global_position
		get_tree().current_scene.add_child(loot)
	unit_died.emit(self)
	queue_free()


# ---- Main AI loop (full override, no super call) ----------------------
func _physics_process(delta: float) -> void:
	var speed_mult: float = GameManager.game_speed
	var scaled_delta := delta * speed_mult

	# Apply speed buff
	var eff_speed := move_speed
	if GameManager.active_buffs.has("speed_boost"):
		eff_speed *= GameManager.active_buffs["speed_boost"]

	match _state:
		State.SEARCHING:
			_state_searching()

		State.WALKING_TO_NODE:
			_state_walking_to_node(scaled_delta, eff_speed)

		State.MINING:
			_state_mining(scaled_delta)

		State.RETURNING:
			_state_returning(scaled_delta, eff_speed)

		State.IDLE:
			_state_idle()

	# Animate
	if _is_moving:
		_anim_time += scaled_delta * 10.0
	else:
		_anim_time *= 0.9

	if _state == State.MINING:
		_pickaxe_swing = fmod(_pickaxe_swing + scaled_delta * 3.0, 1.0)
		_pickaxe_angle = sin(_pickaxe_swing * TAU) * 0.6
	else:
		_pickaxe_angle = lerp(_pickaxe_angle, 0.0, 0.15)

	queue_redraw()


# ---- State handlers ---------------------------------------------------

func _state_searching() -> void:
	velocity = Vector2.ZERO
	_is_moving = false
	var node := _find_nearest_resource_node()
	if node:
		_resource_node = node
		_state = State.WALKING_TO_NODE
	else:
		_state = State.IDLE


func _state_walking_to_node(scaled_delta: float, eff_speed: float) -> void:
	if not is_instance_valid(_resource_node) or not _resource_node.is_available():
		_resource_node = null
		_state = State.SEARCHING
		return

	var dist := global_position.distance_to(_resource_node.global_position)
	if dist <= 28.0:
		velocity = Vector2.ZERO
		move_and_slide()
		_is_moving = false
		# Begin mining
		var mine_speed_mult := 1.0
		if GameManager.active_buffs.has("mine_speed_boost"):
			mine_speed_mult = GameManager.active_buffs["mine_speed_boost"]
		_mine_duration = _resource_node.harvest_time / mine_speed_mult
		_mine_timer = _mine_duration
		_state = State.MINING
	else:
		var dir := (_resource_node.global_position - global_position).normalized()
		velocity = dir * eff_speed * GameManager.game_speed
		move_and_slide()
		_is_moving = true


func _state_mining(scaled_delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()
	_is_moving = false

	if not is_instance_valid(_resource_node) or not _resource_node.is_available():
		_resource_node = null
		_state = State.SEARCHING
		return

	_mine_timer -= scaled_delta
	if _mine_timer <= 0.0:
		var result := _resource_node.harvest()
		if result.is_empty():
			_resource_node = null
			_state = State.SEARCHING
			return
		_carried_type   = result["type"]
		_carried_amount = result["amount"]
		# Apply carry buff
		if GameManager.active_buffs.has("carry_boost"):
			_carried_amount = int(_carried_amount * GameManager.active_buffs["carry_boost"])
		_is_carrying = true
		_resource_node = null
		_state = State.RETURNING


func _state_returning(scaled_delta: float, eff_speed: float) -> void:
	var base := _find_player_base()
	if not base:
		_state = State.IDLE
		return

	var dist := global_position.distance_to(base.global_position)
	if dist <= 35.0:
		# Deposit
		velocity = Vector2.ZERO
		move_and_slide()
		_is_moving = false
		_deposit_resources()
		_state = State.SEARCHING
	else:
		var dir := (base.global_position - global_position).normalized()
		velocity = dir * eff_speed * GameManager.game_speed
		move_and_slide()
		_is_moving = true


func _state_idle() -> void:
	velocity = Vector2.ZERO
	_is_moving = false
	# Retry searching periodically (checked each frame, cheap)
	var node := _find_nearest_resource_node()
	if node:
		_state = State.SEARCHING


# ---- Helpers ----------------------------------------------------------

func _find_nearest_resource_node() -> ResourceNode:
	var nodes := get_tree().get_nodes_in_group("resource_nodes")
	var closest: ResourceNode = null
	var closest_dist := INF
	for n in nodes:
		if not is_instance_valid(n):
			continue
		var rn := n as ResourceNode
		if rn == null or not rn.is_available():
			continue
		var d := global_position.distance_to(rn.global_position)
		if d < closest_dist:
			closest_dist = d
			closest = rn
	return closest


func _find_player_base() -> Node2D:
	var bases := get_tree().get_nodes_in_group("player_base")
	if bases.is_empty():
		return null
	return bases[0] as Node2D


func _deposit_resources() -> void:
	if not _is_carrying:
		return
	match _carried_type:
		ResourceNode.ResourceType.SILVER, ResourceNode.ResourceType.GOLD:
			GameManager.add_gold(_carried_amount)
		ResourceNode.ResourceType.GEM:
			if GameManager.has_method("add_gems"):
				GameManager.add_gems(_carried_amount)
			else:
				GameManager.add_gold(_carried_amount)
	_is_carrying = false
	_carried_amount = 0


# ---- Brotato-style drawing --------------------------------------------
func _draw() -> void:
	var bounce := sin(_anim_time) * 2.5 if _is_moving else 0.0
	var oy := bounce

	# Shadow
	draw_circle(Vector2(0, 14), 8, Color(0, 0, 0, 0.18))

	# Resource bag on back (when carrying)
	if _is_carrying:
		var bag_color := Color(0.55, 0.38, 0.18)
		match _carried_type:
			ResourceNode.ResourceType.SILVER:
				bag_color = Color(0.65, 0.67, 0.70)
			ResourceNode.ResourceType.GOLD:
				bag_color = Color(0.85, 0.70, 0.10)
			ResourceNode.ResourceType.GEM:
				bag_color = Color(0.25, 0.70, 0.85)
		draw_circle(Vector2(-8, 2 + oy), 5, bag_color)
		draw_circle(Vector2(-9, -1 + oy), 4, bag_color.darkened(0.1))

	# Body (small, brown work clothes)
	draw_rect(Rect2(-5, -1 + oy, 10, 10), unit_color)
	# Dungaree straps
	draw_line(Vector2(-3, -1 + oy), Vector2(-3, -6 + oy), Color(0.30, 0.20, 0.08), 1.5)
	draw_line(Vector2(3, -1 + oy), Vector2(3, -6 + oy), Color(0.30, 0.20, 0.08), 1.5)

	# Head (big)
	var head_y := -13.0 + oy * 1.2
	var skin_col := Color(0.95, 0.80, 0.62)
	draw_circle(Vector2(0, head_y), 11, skin_col)

	# Eyes
	draw_circle(Vector2(-3.5, head_y - 1.0), 2.5, Color.WHITE)
	draw_circle(Vector2(3.5, head_y - 1.0), 2.5, Color.WHITE)
	draw_circle(Vector2(-2.5, head_y - 1.0), 1.5, Color(0.1, 0.1, 0.1))
	draw_circle(Vector2(4.5, head_y - 1.0), 1.5, Color(0.1, 0.1, 0.1))

	# Hard hat (yellow)
	var hat_y := head_y - 9.0
	draw_rect(Rect2(-11, hat_y, 22, 5), Color(0.95, 0.82, 0.05))  # brim
	draw_rect(Rect2(-8, hat_y - 6, 16, 7), Color(0.95, 0.82, 0.05))  # dome

	# Headlamp
	draw_circle(Vector2(0, hat_y - 2), 3, Color(1.0, 1.0, 0.85))
	draw_circle(Vector2(0, hat_y - 2), 1.5, Color(1.0, 1.0, 1.0))

	# Floating pickaxe (right side, swings when mining)
	var pk_ox := 14.0
	var pk_oy := -4.0 + oy
	var pk_rot := _pickaxe_angle
	# Handle
	var h_start := Vector2(pk_ox, pk_oy)
	var h_dir := Vector2(cos(pk_rot - 0.3), sin(pk_rot - 0.3))
	var h_end := h_start + h_dir * 14.0
	draw_line(h_start, h_end, Color(0.45, 0.30, 0.12), 2.5)
	# Pick head
	var tip := h_end + h_dir * 5.0
	var perp := Vector2(-h_dir.y, h_dir.x)
	var pick_pts := PackedVector2Array([
		h_end - perp * 2.0,
		h_end + perp * 2.0,
		tip
	])
	draw_colored_polygon(pick_pts, Color(0.6, 0.62, 0.65))

	# HP bar
	var bar_w := 22.0
	var bar_h := 3.0
	var bar_y := -30.0
	var hp_ratio := float(hp) / float(max_hp)
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w, bar_h), Color(0.2, 0.2, 0.2))
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w * hp_ratio, bar_h), Color.GREEN_YELLOW)

	# Mining progress bar (shown only while mining)
	if _state == State.MINING and _mine_duration > 0.0:
		var prog := 1.0 - (_mine_timer / _mine_duration)
		prog = clamp(prog, 0.0, 1.0)
		var mb_y := -35.0
		draw_rect(Rect2(-bar_w / 2, mb_y, bar_w, bar_h), Color(0.2, 0.1, 0.0))
		draw_rect(Rect2(-bar_w / 2, mb_y, bar_w * prog, bar_h), Color(0.95, 0.75, 0.05))
