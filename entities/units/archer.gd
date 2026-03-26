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
	arrow.target_group = "enemies"
	arrow.collision_layer = 0
	arrow.collision_mask = 2
	var proj_container := get_tree().current_scene.find_child("Projectiles", true, false)
	if proj_container:
		proj_container.add_child(arrow)
	else:
		get_parent().add_child(arrow)


func _draw() -> void:
	# Body
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
