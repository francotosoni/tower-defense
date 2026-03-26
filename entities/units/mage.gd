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
