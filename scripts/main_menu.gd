extends Control

## 메인 메뉴: 플레이 / 장비 탭 + 상단 사운드 설정 + 아이템 상세 모달.

enum Tab { PLAY, EQUIP }

var _font: Font
var _tab: int = Tab.PLAY
var _detail_id: String = ""
var _assign_target: String = "primary" # primary | secondary

@onready var top_bar: HBoxContainer = $Root/TopBar
@onready var content: Control = $Root/Content
@onready var bottom_nav: HBoxContainer = $Root/BottomNav
@onready var play_page: Control = $Root/Content/PlayPage
@onready var equip_page: Control = $Root/Content/EquipPage
@onready var settings_modal: ColorRect = $Root/SettingsModal
@onready var detail_modal: ColorRect = $Root/DetailModal


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if ResourceLoader.exists("res://fonts/Jua-Regular.ttf"):
		_font = load("res://fonts/Jua-Regular.ttf")
	_style_root()
	_build_top_bar()
	_build_bottom_nav()
	_build_play_page()
	_build_equip_page()
	_build_settings_modal()
	_show_tab(Tab.PLAY)
	settings_modal.visible = false
	detail_modal.visible = false
	Sfx.ensure_web_unlocked()
	if not OS.has_feature("web"):
		Sfx.play_bgm()


func _style_root() -> void:
	$Root/Bg.color = Color(0.06, 0.08, 0.1, 1)


func _font_on(label: Label, size: int = 18, color: Color = Color(0.92, 0.95, 0.98)) -> void:
	if _font:
		label.add_theme_font_override("font", _font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)


func _make_btn(text: String, min_size: Vector2 = Vector2(120, 44)) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	if _font:
		b.add_theme_font_override("font", _font)
	b.add_theme_font_size_override("font_size", 18)
	return b


func _panel_style(panel: PanelContainer) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.09, 0.11, 0.14, 0.92)
	box.set_corner_radius_all(12)
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 14
	box.content_margin_bottom = 14
	box.border_color = Color(1, 1, 1, 0.08)
	box.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", box)


func _build_top_bar() -> void:
	for c in top_bar.get_children():
		c.queue_free()
	var title := Label.new()
	title.text = "SURVIVOR ARENA"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_font_on(title, 28)
	top_bar.add_child(title)
	var settings_btn := _make_btn("사운드 설정", Vector2(140, 44))
	settings_btn.pressed.connect(_open_settings)
	top_bar.add_child(settings_btn)


func _build_bottom_nav() -> void:
	for c in bottom_nav.get_children():
		c.queue_free()
	var play_btn := _make_btn("플레이", Vector2(180, 52))
	var equip_btn := _make_btn("장비", Vector2(180, 52))
	play_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	equip_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	play_btn.pressed.connect(func() -> void: _show_tab(Tab.PLAY))
	equip_btn.pressed.connect(func() -> void: _show_tab(Tab.EQUIP))
	bottom_nav.add_child(play_btn)
	bottom_nav.add_child(equip_btn)


func _show_tab(tab: int) -> void:
	_tab = tab
	play_page.visible = tab == Tab.PLAY
	equip_page.visible = tab == Tab.EQUIP
	if tab == Tab.EQUIP:
		_refresh_equip_page()


func _build_play_page() -> void:
	for c in play_page.get_children():
		c.queue_free()
	var panel := PanelContainer.new()
	_panel_style(panel)
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	play_page.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	panel.add_child(v)

	var head := Label.new()
	head.text = "난이도 선택"
	_font_on(head, 26)
	v.add_child(head)

	var desc := Label.new()
	desc.text = "선택한 난이도로 아레나에 진입합니다.\n장비 탭에서 주무기/보조무기를 먼저 맞춰 두세요."
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_font_on(desc, 16, Color(0.75, 0.8, 0.86))
	v.add_child(desc)

	for id in ["easy", "normal", "hard"]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var name_l := Label.new()
		name_l.text = "%s  (x%.2f)" % [Loadout.DIFFICULTY_NAMES[id], Loadout.DIFFICULTY_MULT[id]]
		name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_font_on(name_l, 20)
		row.add_child(name_l)
		var go := _make_btn("출격", Vector2(110, 44))
		var captured: String = id
		go.pressed.connect(func() -> void: _start_run(captured))
		row.add_child(go)
		v.add_child(row)

	var tip := Label.new()
	tip.text = "현재 장비: %s / %s" % [
		str(WeaponCatalog.get_by_id(Loadout.primary_id).get("name", "?")),
		str(WeaponCatalog.get_by_id(Loadout.secondary_id).get("name", "?")),
	]
	_font_on(tip, 16, Color(0.85, 0.9, 0.7))
	tip.name = "LoadoutTip"
	v.add_child(tip)


func _start_run(diff: String) -> void:
	Loadout.set_difficulty(diff)
	Sfx.ensure_web_unlocked()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _build_equip_page() -> void:
	for c in equip_page.get_children():
		c.queue_free()
	var root := VBoxContainer.new()
	root.name = "RootVBox"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 12)
	equip_page.add_child(root)

	var slots := HBoxContainer.new()
	slots.add_theme_constant_override("separation", 12)
	slots.name = "Slots"
	root.add_child(slots)

	var list_panel := PanelContainer.new()
	list_panel.name = "ListPanel"
	_panel_style(list_panel)
	list_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(list_panel)
	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_panel.add_child(scroll)
	var list := VBoxContainer.new()
	list.name = "WeaponList"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)


func _refresh_equip_page() -> void:
	var slots: HBoxContainer = equip_page.get_node("RootVBox/Slots")
	for c in slots.get_children():
		c.queue_free()
	slots.add_child(_slot_card("주무기", Loadout.primary_id, "primary"))
	slots.add_child(_slot_card("보조무기", Loadout.secondary_id, "secondary"))

	var list: VBoxContainer = equip_page.get_node("RootVBox/ListPanel/Scroll/WeaponList")
	for c in list.get_children():
		c.queue_free()
	var title := Label.new()
	title.text = "보유 무기 (장착 / 상세)"
	_font_on(title, 20)
	list.add_child(title)

	for w in WeaponCatalog.WEAPONS:
		var id := str(w["id"])
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var swatch := ColorRect.new()
		swatch.custom_minimum_size = Vector2(18, 36)
		swatch.color = DamageTypes.TYPE_COLORS.get(int(w["dmg_type"]), Color.WHITE)
		row.add_child(swatch)
		var lab := Label.new()
		lab.text = "%s  ·  %s" % [str(w["name"]), WeaponCatalog.type_label(int(w["dmg_type"]))]
		lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_font_on(lab, 17)
		row.add_child(lab)
		var detail := _make_btn("상세", Vector2(80, 40))
		detail.pressed.connect(_open_detail.bind(id))
		row.add_child(detail)
		var pbtn := _make_btn("주무기", Vector2(90, 40))
		pbtn.pressed.connect(func() -> void:
			Loadout.set_primary(id)
			_refresh_equip_page()
			_refresh_play_tip()
		)
		row.add_child(pbtn)
		var sbtn := _make_btn("보조", Vector2(80, 40))
		sbtn.pressed.connect(func() -> void:
			Loadout.set_secondary(id)
			_refresh_equip_page()
			_refresh_play_tip()
		)
		row.add_child(sbtn)
		list.add_child(row)


func _slot_card(title: String, weapon_id: String, slot_key: String) -> PanelContainer:
	var panel := PanelContainer.new()
	_panel_style(panel)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	panel.add_child(v)
	var t := Label.new()
	t.text = title
	_font_on(t, 16, Color(0.7, 0.78, 0.86))
	v.add_child(t)
	var w := WeaponCatalog.get_by_id(weapon_id)
	var name_l := Label.new()
	name_l.text = str(w.get("name", "없음"))
	_font_on(name_l, 22)
	v.add_child(name_l)
	var meta := Label.new()
	meta.text = "%s · 피해 %.0f · 탄창 %d" % [
		WeaponCatalog.type_label(int(w.get("dmg_type", 0))),
		float(w.get("damage", 0.0)),
		int(w.get("ammo", 0)),
	]
	_font_on(meta, 14, Color(0.8, 0.85, 0.7))
	v.add_child(meta)
	var open := _make_btn("상세 보기", Vector2(120, 36))
	open.pressed.connect(_open_detail.bind(weapon_id))
	v.add_child(open)
	return panel


func _refresh_play_tip() -> void:
	var tip := play_page.find_child("LoadoutTip", true, false)
	if tip is Label:
		tip.text = "현재 장비: %s / %s" % [
			str(WeaponCatalog.get_by_id(Loadout.primary_id).get("name", "?")),
			str(WeaponCatalog.get_by_id(Loadout.secondary_id).get("name", "?")),
		]


func _build_settings_modal() -> void:
	for c in settings_modal.get_children():
		c.queue_free()
	settings_modal.color = Color(0.02, 0.03, 0.04, 0.78)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	settings_modal.add_child(center)
	var panel := PanelContainer.new()
	_panel_style(panel)
	panel.custom_minimum_size = Vector2(420, 320)
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)
	var title := Label.new()
	title.text = "사운드 설정"
	_font_on(title, 24)
	v.add_child(title)
	v.add_child(_volume_row("마스터", "master", Sfx.volume_master))
	v.add_child(_volume_row("BGM", "bgm", Sfx.volume_bgm))
	v.add_child(_volume_row("효과음", "sfx", Sfx.volume_sfx))
	var close := _make_btn("닫기", Vector2(120, 44))
	close.pressed.connect(func() -> void:
		settings_modal.visible = false
		Loadout.save_settings()
	)
	v.add_child(close)


func _volume_row(label_text: String, key: String, value: float) -> HBoxContainer:
	var row := HBoxContainer.new()
	var lab := Label.new()
	lab.text = label_text
	lab.custom_minimum_size = Vector2(90, 0)
	_font_on(lab, 18)
	row.add_child(lab)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(func(v: float) -> void:
		match key:
			"master":
				Sfx.volume_master = v
			"bgm":
				Sfx.volume_bgm = v
			"sfx":
				Sfx.volume_sfx = v
		Sfx.apply_volumes()
		Sfx.ensure_web_unlocked()
	)
	row.add_child(slider)
	return row


func _open_settings() -> void:
	Sfx.ensure_web_unlocked()
	_build_settings_modal()
	settings_modal.visible = true


func _build_detail_modal() -> void:
	pass


func _open_detail(id: String) -> void:
	_detail_id = id
	var w := WeaponCatalog.get_by_id(id)
	if w.is_empty():
		return
	for c in detail_modal.get_children():
		c.queue_free()
	detail_modal.color = Color(0.02, 0.03, 0.04, 0.78)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	detail_modal.add_child(center)
	var panel := PanelContainer.new()
	_panel_style(panel)
	panel.custom_minimum_size = Vector2(480, 380)
	center.add_child(panel)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	panel.add_child(body)

	var title := Label.new()
	title.text = str(w["name"])
	_font_on(title, 28)
	body.add_child(title)

	var type_l := Label.new()
	type_l.text = "속성: %s" % WeaponCatalog.type_label(int(w["dmg_type"]))
	_font_on(type_l, 18, DamageTypes.TYPE_COLORS.get(int(w["dmg_type"]), Color.WHITE))
	body.add_child(type_l)

	var lines := [
		"설명: %s" % str(w.get("note", "")),
		"피해: %.1f" % float(w["damage"]),
		"공격 간격: %.2fs" % float(w["cooldown"]),
		"사거리: %.0f" % float(w["range"]),
		"탄창: %d · 장전: %.2fs" % [int(w["ammo"]), float(w["reload"])],
		"종류: %s" % str(w["kind"]),
	]
	if int(w.get("pierce", 0)) > 0:
		lines.append("관통: %d" % int(w["pierce"]))
	if int(w.get("pellets", 1)) > 1:
		lines.append("펠릿: %d" % int(w["pellets"]))
	for line in lines:
		var lab := Label.new()
		lab.text = line
		lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_font_on(lab, 16, Color(0.82, 0.86, 0.9))
		body.add_child(lab)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var pbtn := _make_btn("주무기로", Vector2(120, 44))
	pbtn.pressed.connect(func() -> void:
		Loadout.set_primary(id)
		detail_modal.visible = false
		_refresh_equip_page()
		_refresh_play_tip()
	)
	row.add_child(pbtn)
	var sbtn := _make_btn("보조무기로", Vector2(130, 44))
	sbtn.pressed.connect(func() -> void:
		Loadout.set_secondary(id)
		detail_modal.visible = false
		_refresh_equip_page()
		_refresh_play_tip()
	)
	row.add_child(sbtn)
	var close := _make_btn("닫기", Vector2(100, 44))
	close.pressed.connect(func() -> void: detail_modal.visible = false)
	row.add_child(close)
	body.add_child(row)
	detail_modal.visible = true
