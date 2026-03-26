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
