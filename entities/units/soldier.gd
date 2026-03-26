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
