extends CanvasLayer

signal shop_closed

const SHOP_ITEMS := [
	{"name": "Sharpen Blades", "desc": "+20% troop damage", "cost": 40, "currency": "gold", "effect": "damage_boost", "value": 1.2},
	{"name": "Swift Boots", "desc": "+15% troop speed", "cost": 35, "currency": "gold", "effect": "speed_boost", "value": 1.15},
	{"name": "Tough Armor", "desc": "+25% troop HP", "cost": 45, "currency": "gold", "effect": "hp_boost", "value": 1.25},
	{"name": "Miner Training", "desc": "+30% mine speed", "cost": 30, "currency": "gold", "effect": "mine_speed_boost", "value": 1.3},
	{"name": "Base Repair", "desc": "Restore 20 base HP", "cost": 1, "currency": "gems", "effect": "base_heal", "value": 20},
	{"name": "Gold Rush", "desc": "+50% bounty gold", "cost": 1, "currency": "gems", "effect": "bounty_boost", "value": 1.5},
	{"name": "Crystal Pickaxe", "desc": "Miners carry +50%", "cost": 2, "currency": "gems", "effect": "carry_boost", "value": 1.5},
	{"name": "War Drums", "desc": "+20% attack speed", "cost": 50, "currency": "gold", "effect": "attack_speed_boost", "value": 1.2},
	{"name": "Lucky Charm", "desc": "+1 Gem", "cost": 20, "currency": "gold", "effect": "free_gem", "value": 1},
]

var _bg: ColorRect
var _items_container: HBoxContainer
var _current_items: Array = []
var _timer_label: Label
var _auto_close_timer: float = 0.0
const AUTO_CLOSE_TIME := 12.0


func _ready() -> void:
	layer = 25
	_build_ui()
	_bg.visible = false
	set_process(false)


func _build_ui() -> void:
	_bg = ColorRect.new()
	_bg.color = Color(0, 0, 0, 0.75)
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "~ SHOP ~"
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	title.add_theme_font_size_override("font_size", 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Choose an upgrade before the next wave"
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle)

	_timer_label = Label.new()
	_timer_label.add_theme_font_size_override("font_size", 16)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_timer_label)

	_items_container = HBoxContainer.new()
	_items_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_items_container.add_theme_constant_override("separation", 30)
	vbox.add_child(_items_container)

	var skip_btn := Button.new()
	skip_btn.text = "Skip (Continue)"
	skip_btn.add_theme_font_size_override("font_size", 18)
	skip_btn.pressed.connect(_close_shop)
	vbox.add_child(skip_btn)


func _process(delta: float) -> void:
	_auto_close_timer -= delta
	if _auto_close_timer <= 0.0:
		_close_shop()
		return
	_timer_label.text = "Auto-closing in %d..." % int(ceil(_auto_close_timer))


func show_shop() -> void:
	_current_items = []
	var pool := SHOP_ITEMS.duplicate()
	pool.shuffle()
	for i in range(min(3, pool.size())):
		_current_items.append(pool[i])

	# Clear old panels
	for child in _items_container.get_children():
		child.queue_free()

	for item in _current_items:
		_items_container.add_child(_build_item_panel(item))

	_auto_close_timer = AUTO_CLOSE_TIME
	_bg.visible = true
	set_process(true)


func _build_item_panel(item: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(220, 280)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var name_lbl := Label.new()
	name_lbl.text = item["name"]
	name_lbl.add_theme_font_size_override("font_size", 22)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = item["desc"]
	desc_lbl.add_theme_font_size_override("font_size", 16)
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_lbl)

	var cost_lbl := Label.new()
	var currency: String = item["currency"]
	cost_lbl.text = "%d %s" % [item["cost"], currency]
	if currency == "gems":
		cost_lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 1.0))
	else:
		cost_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	cost_lbl.add_theme_font_size_override("font_size", 16)
	cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(cost_lbl)

	var buy_btn := Button.new()
	buy_btn.text = "Buy"
	buy_btn.add_theme_font_size_override("font_size", 16)
	buy_btn.pressed.connect(_on_buy_pressed.bind(item, buy_btn))
	vbox.add_child(buy_btn)

	return panel


func _on_buy_pressed(item: Dictionary, btn: Button) -> void:
	var cost: int = item["cost"]
	var currency: String = item["currency"]

	if currency == "gold":
		if not GameManager.spend_gold(cost):
			return
	elif currency == "gems":
		if not GameManager.spend_gems(cost):
			return

	_apply_effect(item)
	btn.disabled = true
	btn.text = "Bought"


func _apply_effect(item: Dictionary) -> void:
	var effect: String = item["effect"]
	var value: float = float(item["value"])

	match effect:
		"base_heal":
			GameManager.heal_base(int(value))
		"free_gem":
			GameManager.add_gems(int(value))
		_:
			var current: float = GameManager.active_buffs.get(effect, 1.0)
			GameManager.active_buffs[effect] = current * value


func _close_shop() -> void:
	set_process(false)
	_bg.visible = false
	shop_closed.emit()
