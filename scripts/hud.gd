extends CanvasLayer

@onready var hp_bar: ProgressBar = $Root/TopRight/HpCol/HpBar
@onready var hp_label: Label = $Root/TopRight/HpCol/HpLabel
@onready var xp_bar: ProgressBar = $Root/TopRight/HpCol/XpBar
@onready var xp_label: Label = $Root/TopRight/HpCol/XpLabel
@onready var active_icon: ColorRect = $Root/TopLeft/ActiveRow/ActiveIcon
@onready var active_name: Label = $Root/TopLeft/ActiveRow/ActiveInfo/ActiveName
@onready var active_cd: Label = $Root/TopLeft/ActiveRow/ActiveInfo/ActiveCd
@onready var status_label: Label = $Root/StatusPanel/StatusLabel
@onready var help_label: Label = $Root/HelpLabel
@onready var overlay: ColorRect = $Root/Overlay
@onready var overlay_label: Label = $Root/Overlay/OverlayLabel
@onready var passive_select: ColorRect = $Root/PassiveSelect
@onready var passive_title: Label = $Root/PassiveSelect/Title
@onready var card_row: HBoxContainer = $Root/PassiveSelect/CardRow
@onready var top_left: PanelContainer = $Root/TopLeft
@onready var top_right: PanelContainer = $Root/TopRight
@onready var status_panel: PanelContainer = $Root/StatusPanel

var player: Node
var _offer_ids: Array[String] = []
var _card_buttons: Array[Button] = []
var _ui_font: Font


func setup(p: Node) -> void:
	player = p
	if player.has_signal("stats_changed"):
		player.stats_changed.connect(_refresh)
	if player.has_signal("died"):
		player.died.connect(_on_player_died)
	if player.has_signal("passive_choice_offered"):
		player.passive_choice_offered.connect(_on_passive_choice_offered)
	Game.kills_changed.connect(_refresh)
	Game.time_changed.connect(_refresh)
	Game.wave_changed.connect(_refresh)
	_refresh()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_style_panels()
	_apply_ui_font()
	help_label.text = "WASD 이동 | 방향키 공격 | Space 대시 | Q 주/부무기 | E 액티브 | 초록 젬=경험치 | Esc 메뉴"
	overlay.visible = false
	passive_select.visible = false
	passive_title.text = "패시브 강화 - 카드 1개를 선택하세요 (1 / 2 / 3)"
	_ensure_card_buttons()


func _style_panels() -> void:
	for panel in [top_left, top_right, status_panel]:
		panel.add_theme_stylebox_override("panel", UiTheme.panel_style())


func _apply_ui_font() -> void:
	_ui_font = UiTheme.font()
	if _ui_font == null:
		return
	var labels: Array = [
		hp_label, xp_label, active_name, active_cd, status_label, help_label,
		overlay_label, passive_title,
		$Root/TopLeft/ActiveRow/ActiveInfo/ActiveTitle,
		$Root/TopRight/HpCol/HpTitle,
		$Root/TopRight/HpCol/XpTitle,
	]
	for node in labels:
		if node:
			node.add_theme_font_override("font", _ui_font)


func _ensure_card_buttons() -> void:
	if not _card_buttons.is_empty():
		return
	for i in range(3):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(230, 240)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.clip_text = false
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
		if _ui_font:
			btn.add_theme_font_override("font", _ui_font)
			btn.add_theme_font_size_override("font_size", 17)
		btn.pressed.connect(_on_card_pressed.bind(i))
		card_row.add_child(btn)
		_card_buttons.append(btn)


func _refresh(_arg: Variant = null) -> void:
	if player == null or not is_instance_valid(player):
		return
	if not ("max_hp" in player):
		return

	hp_bar.max_value = player.max_hp
	hp_bar.value = player.hp
	hp_label.text = "%d / %d" % [int(player.hp), int(player.max_hp)]

	xp_bar.max_value = maxf(1.0, float(player.xp_to_next))
	xp_bar.value = float(player.xp)
	xp_label.text = "Lv %d   %d / %d" % [int(player.level), int(player.xp), int(player.xp_to_next)]

	var def := ActiveCatalog.get_by_id(str(player.active_id))
	var dtype: int = int(def["dmg_type"])
	active_icon.color = DamageTypes.TYPE_COLORS.get(dtype, Color(0.8, 0.8, 0.85))
	active_name.text = str(def["name"])
	var ready := float(player.get_active_ready_ratio())
	if ready >= 0.999:
		active_cd.text = "준비 완료  /  E"
		active_cd.modulate = Color(0.75, 1.0, 0.7)
	else:
		active_cd.text = "재사용 %.0f%%" % (ready * 100.0)
		active_cd.modulate = Color(1.0, 0.85, 0.55)

	var t := int(Game.elapsed)
	var mm := t / 60
	var ss := t % 60
	var diff_name: String = str(Loadout.DIFFICULTY_NAMES.get(Loadout.difficulty, Loadout.difficulty))
	status_label.text = "난이도  %s\n무기  %s\n대시  %.0f%%   /   Wave %d\n처치 %d   /   %02d:%02d\n패시브  %s" % [
		diff_name,
		player.get_weapon_name(),
		player.get_dash_ready_ratio() * 100.0,
		Game.wave,
		Game.kills,
		mm,
		ss,
		player.get_passive_summary(),
	]


func _on_passive_choice_offered(options: Array) -> void:
	_ensure_card_buttons()
	_offer_ids.clear()
	for opt in options:
		_offer_ids.append(str(opt))
	while _offer_ids.size() < 3:
		_offer_ids.append(_offer_ids[0] if not _offer_ids.is_empty() else "bomb_support")

	for i in range(3):
		var id := _offer_ids[i]
		var def := PassiveCatalog.get_by_id(id)
		var dtype: int = int(def["dmg_type"])
		var type_name: String = DamageTypes.TYPE_NAMES.get(dtype, "일반")
		var color: Color = DamageTypes.TYPE_COLORS.get(dtype, Color.WHITE)
		var owned_rank := 0
		if player != null and "passives" in player and player.passives.has(id):
			owned_rank = int(player.passives[id])
		var next_rank := owned_rank + 1
		var rank_text := "신규 Lv1" if owned_rank <= 0 else "강화 Lv%d → Lv%d" % [owned_rank, next_rank]
		_card_buttons[i].text = "[ %d ]\n\n%s\n(%s)\n\n%s\n\n%s" % [
			i + 1,
			str(def["name"]),
			type_name,
			str(def["desc"]),
			rank_text,
		]
		_card_buttons[i].modulate = Color(color.r * 0.55 + 0.45, color.g * 0.55 + 0.45, color.b * 0.55 + 0.45)

	passive_select.visible = true
	Sfx.play("pickup", 0.9, -4.0)


func _on_card_pressed(index: int) -> void:
	Sfx.ensure_web_unlocked()
	_select_card(index)


func _select_card(index: int) -> void:
	if not passive_select.visible:
		return
	if index < 0 or index >= _offer_ids.size():
		return
	if player == null or not is_instance_valid(player):
		return
	if not player.has_method("apply_passive"):
		return
	Sfx.ensure_web_unlocked()
	var id := _offer_ids[index]
	passive_select.visible = false
	_offer_ids.clear()
	player.apply_passive(id)
	_refresh()


func _on_player_died() -> void:
	Game.running = false
	passive_select.visible = false
	overlay.visible = true
	overlay_label.text = "전투 종료\n처치: %d\nR 재시작  /  M 메뉴" % Game.kills


func _go_menu() -> void:
	get_tree().paused = false
	Game.reset()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if passive_select.visible and event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1, KEY_KP_1:
				_select_card(0)
				get_viewport().set_input_as_handled()
			KEY_2, KEY_KP_2:
				_select_card(1)
				get_viewport().set_input_as_handled()
			KEY_3, KEY_KP_3:
				_select_card(2)
				get_viewport().set_input_as_handled()
		return

	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_go_menu()
		get_viewport().set_input_as_handled()
		return

	if overlay.visible and event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			get_tree().paused = false
			get_tree().reload_current_scene()
			Game.reset()
		elif event.keycode == KEY_M:
			_go_menu()
