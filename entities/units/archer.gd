extends BaseUnit

var _arrow_scene: PackedScene


func _ready() -> void:
	max_hp = 50
	damage = 8
	attack_speed = 0.8
	move_speed = 90.0
	attack_range = 300.0
	unit_color = Color(0.1, 0.7, 0.3)
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
	arrow.target_group = "enemies"
	arrow.collision_layer = 0
	arrow.collision_mask = 2
	var proj_container := get_tree().current_scene.find_child("Projectiles", true, false)
	if proj_container:
		proj_container.add_child(arrow)
	else:
		get_parent().add_child(arrow)


func _draw() -> void:
	var r := unit_radius
	# Body (green ranger)
	draw_circle(Vector2.ZERO, r, unit_color)
	draw_arc(Vector2.ZERO, r, 0, TAU, 32, unit_color.darkened(0.3), 2.0)
	# Hood (triangle on top)
	var hood := PackedVector2Array([Vector2(-r * 0.5, -r * 0.3), Vector2(0, -r * 1.3), Vector2(r * 0.5, -r * 0.3)])
	draw_colored_polygon(hood, Color(0.08, 0.5, 0.2))
	# Eyes
	draw_circle(Vector2(-3, -2), 2.0, Color.WHITE)
	draw_circle(Vector2(3, -2), 2.0, Color.WHITE)
	draw_circle(Vector2(-3, -2), 1.0, Color(0.1, 0.1, 0.1))
	draw_circle(Vector2(3, -2), 1.0, Color(0.1, 0.1, 0.1))
	# Bow
	draw_arc(Vector2(r * 0.5, 0), r * 0.8, -PI / 2.5, PI / 2.5, 16, Color(0.55, 0.35, 0.1), 2.5)
	draw_line(Vector2(r * 0.5, -r * 0.6), Vector2(r * 0.5, r * 0.6), Color(0.9, 0.85, 0.7), 1.0)  # string
	# Quiver on back
	draw_rect(Rect2(-r * 0.9, -r * 0.6, 5, r * 1.0), Color(0.45, 0.28, 0.1))
	# HP bar
	_draw_hp_bar()


func _draw_hp_bar() -> void:
	var bar_w := unit_radius * 2.2
	var bar_h := 4.0
	var bar_y := -unit_radius - 14.0
	var hp_ratio := float(hp) / float(max_hp)
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w, bar_h), Color(0.2, 0.2, 0.2))
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w * hp_ratio, bar_h), Color.GREEN_YELLOW)
