extends Control

signal next_level_requested
signal retry_requested
signal back_to_menu_requested

var _title_label: Label
var _message_label: Label
var _next_btn: Button
var _retry_btn: Button
var _menu_btn: Button


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	# Darken background
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.7)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Center container
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(400, 0)
	vbox.add_theme_constant_override("separation", 20)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)

	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 48)
	vbox.add_child(_title_label)

	_message_label = Label.new()
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(_message_label)

	var btn_container := HBoxContainer.new()
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_container)

	_retry_btn = Button.new()
	_retry_btn.text = "Retry"
	_retry_btn.custom_minimum_size = Vector2(120, 45)
	_retry_btn.add_theme_font_size_override("font_size", 20)
	_retry_btn.pressed.connect(func(): retry_requested.emit())
	btn_container.add_child(_retry_btn)

	_next_btn = Button.new()
	_next_btn.text = "Next Level"
	_next_btn.custom_minimum_size = Vector2(150, 45)
	_next_btn.add_theme_font_size_override("font_size", 20)
	_next_btn.pressed.connect(func(): next_level_requested.emit())
	btn_container.add_child(_next_btn)

	_menu_btn = Button.new()
	_menu_btn.text = "Menu"
	_menu_btn.custom_minimum_size = Vector2(120, 45)
	_menu_btn.add_theme_font_size_override("font_size", 20)
	_menu_btn.pressed.connect(func(): back_to_menu_requested.emit())
	btn_container.add_child(_menu_btn)


func show_victory() -> void:
	_title_label.text = "Victory!"
	_title_label.add_theme_color_override("font_color", Color.GOLD)
	_message_label.text = "Level Complete!"
	_next_btn.visible = true
	_retry_btn.visible = true
	visible = true


func show_defeat() -> void:
	_title_label.text = "Defeat"
	_title_label.add_theme_color_override("font_color", Color.RED)
	_message_label.text = "Your base was destroyed."
	_next_btn.visible = false
	_retry_btn.visible = true
	visible = true
