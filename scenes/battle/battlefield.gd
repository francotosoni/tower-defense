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
			var end_y: float = min(y + dash_len, 1080.0)
			draw_line(Vector2(DEPLOY_ZONE_END_X, y), Vector2(DEPLOY_ZONE_END_X, end_y), DEPLOY_BORDER_COLOR, 2.0)
			y += dash_len + gap_len


func set_deploy_highlight(visible: bool) -> void:
	show_deploy_zone = visible
	queue_redraw()
