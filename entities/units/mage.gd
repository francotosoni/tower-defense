extends BaseUnit

var _bolt_scene: PackedScene
var _aoe_radius: float = 90.0


func _ready() -> void:
	max_hp = 40
	damage = 15
	attack_speed = 1.5
	move_speed = 75.0
	attack_range = 270.0
	unit_color = Color(0.6, 0.2, 0.8)
	unit_radius = 13.0
	_bolt_scene = load("res://entities/projectiles/magic_bolt.tscn")
	super._ready()


func _find_target() -> Node2D:
	var enemies := get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return null
	var best_target: Node2D = null
	var best_count := 0
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
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
	var r := unit_radius
	# Robe (purple body)
	draw_circle(Vector2.ZERO, r, unit_color)
	draw_arc(Vector2.ZERO, r, 0, TAU, 32, unit_color.darkened(0.3), 2.0)
	# Wizard hat
	var hat := PackedVector2Array([Vector2(-r * 0.7, -r * 0.2), Vector2(0, -r * 1.8), Vector2(r * 0.7, -r * 0.2)])
	draw_colored_polygon(hat, Color(0.4, 0.1, 0.6))
	# Hat brim
	draw_line(Vector2(-r * 0.9, -r * 0.2), Vector2(r * 0.9, -r * 0.2), Color(0.4, 0.1, 0.6), 3.0)
	# Star on hat
	draw_circle(Vector2(0, -r * 1.1), 3.0, Color(1.0, 0.9, 0.2))
	# Eyes (glowing)
	draw_circle(Vector2(-3, 0), 2.5, Color(0.9, 0.7, 1.0))
	draw_circle(Vector2(3, 0), 2.5, Color(0.9, 0.7, 1.0))
	# Staff
	draw_line(Vector2(r * 0.6, -r * 0.5), Vector2(r * 0.6, r * 1.0), Color(0.5, 0.3, 0.15), 2.5)
	draw_circle(Vector2(r * 0.6, -r * 0.6), 4.0, Color(0.4, 0.8, 1.0))  # crystal orb
	# HP bar
	_draw_hp_bar()


func _draw_hp_bar() -> void:
	var bar_w := unit_radius * 2.2
	var bar_h := 4.0
	var bar_y := -unit_radius - 18.0
	var hp_ratio := float(hp) / float(max_hp)
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w, bar_h), Color(0.2, 0.2, 0.2))
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w * hp_ratio, bar_h), Color.GREEN_YELLOW)
