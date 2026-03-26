extends CanvasLayer

var _label: Label
var _panel: PanelContainer
var _tween: Tween


func _ready() -> void:
	layer = 20

	var anchor := Control.new()
	anchor.set_anchors_preset(Control.PRESET_TOP_WIDE)
	anchor.custom_minimum_size = Vector2(0, 250)
	add_child(anchor)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	anchor.add_child(center)

	_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.7)
	style.set_corner_radius_all(10)
	_panel.add_theme_stylebox_override("panel", style)
	_panel.modulate.a = 0.0
	center.add_child(_panel)

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
