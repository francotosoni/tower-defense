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
