extends Control

## PC형 메인 메뉴: 사이버네온 사이드바 + 출격/무장/적특성.

enum Tab { PLAY, EQUIP, CODEX }

const ICON_DIR := "res://assets/icons/"
const BG_PATH := "res://assets/ui/menu_bg.jpg"

var _tab: int = Tab.PLAY
var _detail_id: String = ""
var _nav_btns: Array[Button] = []

@onready var bg: TextureRect = $Root/Bg
@onready var side_bar: PanelContainer = $Root/Layout/SideBar
@onready var brand: Label = $Root/Layout/SideBar/SideVBox/Brand
@onready var tagline: Label = $Root/Layout/SideBar/SideVBox/Tagline
@onready var play_btn: Button = $Root/Layout/SideBar/SideVBox/NavBox/PlayBtn
@onready var equip_btn: Button = $Root/Layout/SideBar/SideVBox/NavBox/EquipBtn
@onready var codex_btn: Button = $Root/Layout/SideBar/SideVBox/NavBox/CodexBtn
@onready var sound_btn: Button = $Root/Layout/SideBar/SideVBox/SoundBtn
@onready var play_page: Control = $Root/Layout/MainPane/PlayPage
@onready var equip_page: Control = $Root/Layout/MainPane/EquipPage
@onready var codex_page: Control = $Root/Layout/MainPane/CodexPage
@onready var settings_modal: ColorRect = $Root/SettingsModal
@onready var detail_modal: ColorRect = $Root/DetailModal


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_background()
	side_bar.add_theme_stylebox_override("panel", UiTheme.panel_style())
	UiTheme.apply_font(brand, 28, UiTheme.C_TEXT, "semibold")
	UiTheme.apply_font(tagline, 13, UiTheme.C_MUTED, "regular")
	_nav_btns = [play_btn, equip_btn, codex_btn]
	for b in _nav_btns:
		UiTheme.style_button(b, false)
	UiTheme.style_button(sound_btn, false)
	play_btn.pressed.connect(func() -> void: _show_tab(Tab.PLAY))
	equip_btn.pressed.connect(func() -> void: _show_tab(Tab.EQUIP))
	codex_btn.pressed.connect(func() -> void: _show_tab(Tab.CODEX))
	sound_btn.pressed.connect(_open_settings)
	_build_play_page()
	_build_equip_page()
	_build_codex_page()
	_show_tab(Tab.PLAY)
	settings_modal.visible = false
	detail_modal.visible = false
	Sfx.ensure_web_unlocked()
	Sfx.play_bgm(Sfx.BGM_LOBBY, false)


func _setup_background() -> void:
	if ResourceLoader.exists(BG_PATH):
		bg.texture = load(BG_PATH)
	else:
		bg.texture = null
		bg.modulate = Color(0.08, 0.1, 0.14)


func _show_tab(tab: int) -> void:
	_tab = tab
	play_page.visible = tab == Tab.PLAY
	equip_page.visible = tab == Tab.EQUIP
	codex_page.visible = tab == Tab.CODEX
	var active: Button = play_btn
	match tab:
		Tab.EQUIP:
			active = equip_btn
		Tab.CODEX:
			active = codex_btn
		_:
			active = play_btn
	for b in _nav_btns:
		UiTheme.style_button(b, b == active)
	if tab == Tab.EQUIP:
		_refresh_equip_page()
	elif tab == Tab.PLAY:
		_refresh_play_tip()


func _make_btn(text: String, min_size: Vector2 = Vector2(120, 42)) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	UiTheme.style_button(b, false)
	return b


func _section_title(text: String, size: int = 26) -> Label:
	var head := Label.new()
	head.text = text
	UiTheme.apply_font(head, size, UiTheme.C_TEXT, "semibold")
	return head


func _muted_label(text: String, size: int = 15) -> Label:
	var lab := Label.new()
	lab.text = text
	lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiTheme.apply_font(lab, size, UiTheme.C_MUTED, "medium")
	return lab


func _build_play_page() -> void:
	for c in play_page.get_children():
		c.queue_free()
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.panel_style())
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	play_page.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	panel.add_child(v)
	v.add_child(_section_title("난이도 선택"))
	v.add_child(_muted_label("로봇 군단이 납치한 고양이를 구출하러 출격합니다.\n좌측 무장 정비에서 주무기/보조무기를 먼저 맞추세요."))

	for id in ["easy", "normal", "hard"]:
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", UiTheme.slot_style(false))
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		card.add_child(row)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var name_l := Label.new()
		name_l.text = "%s  (x%.2f)" % [Loadout.DIFFICULTY_NAMES[id], Loadout.DIFFICULTY_MULT[id]]
		UiTheme.apply_font(name_l, 20, UiTheme.C_TEXT, "medium")
		info.add_child(name_l)
		var blurb := Label.new()
		match id:
			"easy":
				blurb.text = "정찰 전개 - 적응용"
			"normal":
				blurb.text = "본대 교전 - 표준 작전"
			_:
				blurb.text = "군단 본진 - 고위험"
		UiTheme.apply_font(blurb, 13, UiTheme.C_MUTED, "regular")
		info.add_child(blurb)
		var go := _make_btn("출격", Vector2(120, 44))
		UiTheme.apply_font(go, 16, UiTheme.C_TEXT, "semibold")
		go.add_theme_stylebox_override("normal", UiTheme.button_style("cta"))
		go.add_theme_stylebox_override("hover", UiTheme.button_style("cta"))
		go.add_theme_stylebox_override("pressed", UiTheme.button_style("pressed"))
		var captured: String = id
		go.pressed.connect(func() -> void: _start_run(captured))
		row.add_child(go)
		v.add_child(card)

	var tip := Label.new()
	tip.name = "LoadoutTip"
	UiTheme.apply_font(tip, 15, Color(0.85, 0.92, 0.55), "medium")
	v.add_child(tip)
	_refresh_play_tip()


func _start_run(diff: String) -> void:
	Loadout.set_difficulty(diff)
	Sfx.ensure_web_unlocked()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _build_equip_page() -> void:
	for c in equip_page.get_children():
		c.queue_free()
	var root := VBoxContainer.new()
	root.name = "RootVBox"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 12)
	equip_page.add_child(root)

	var slots := HBoxContainer.new()
	slots.add_theme_constant_override("separation", 12)
	slots.name = "Slots"
	root.add_child(slots)

	var list_panel := PanelContainer.new()
	list_panel.name = "ListPanel"
	list_panel.add_theme_stylebox_override("panel", UiTheme.panel_style())
	list_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(list_panel)
	var outer := VBoxContainer.new()
	outer.name = "Outer"
	outer.add_theme_constant_override("separation", 10)
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_panel.add_child(outer)
	outer.add_child(_section_title("보유 무기 인벤토리", 20))
	outer.add_child(_muted_label("칸을 클릭하면 상세 / 장착", 13))
	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	var grid := GridContainer.new()
	grid.name = "WeaponGrid"
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)


func _build_codex_page() -> void:
	for c in codex_page.get_children():
		c.queue_free()
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.panel_style())
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	codex_page.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 14)
	scroll.add_child(v)

	v.add_child(_section_title("적 특성 / 상성"))
	v.add_child(_muted_label(
		"로봇 잔당은 세 가지 장갑 타입으로 등장합니다.\n맞는 속성 무기로 공격하면 피해 x1.75, 안 맞으면 x0.65입니다.\n일반 속성은 항상 x1.0입니다."
	))

	var entries := [
		{
			"armor": DamageTypes.Armor.LIGHT,
			"title": "경장갑 유닛",
			"weak": "폭발",
			"desc": "얇은 외장. 화염방사기/샷건 같은 폭발 무기에 취약합니다. 빠르지만 내구가 낮습니다.",
			"tip": "추천: 샷건, 화염방사기",
		},
		{
			"armor": DamageTypes.Armor.HEAVY,
			"title": "중장갑 유닛",
			"weak": "관통",
			"desc": "두꺼운 장갑판. 관통 탄환이 아니면 피해가 잘 안 들어갑니다. 체력이 높고 이동이 느립니다.",
			"tip": "추천: 자동소총, 저격총, 기관총",
		},
		{
			"armor": DamageTypes.Armor.SPECIAL,
			"title": "특수장갑 유닛",
			"weak": "전격",
			"desc": "절연/차폐 장갑. 전격과 EMP에 약합니다. EMP 속성은 매칭 시 x2.0까지 올라갑니다.",
			"tip": "추천: 테이저건, EMP발사기",
		},
	]

	for e in entries:
		v.add_child(_codex_card(e))

	var rule := PanelContainer.new()
	rule.add_theme_stylebox_override("panel", UiTheme.slot_style(false))
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 6)
	rule.add_child(rv)
	var rh := Label.new()
	rh.text = "속성 색상 가이드"
	UiTheme.apply_font(rh, 16, UiTheme.C_TEXT, "semibold")
	rv.add_child(rh)
	for dtype in [DamageTypes.Type.NONE, DamageTypes.Type.EXPLOSION, DamageTypes.Type.PIERCE, DamageTypes.Type.ELECTRIC]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var swatch := ColorRect.new()
		swatch.custom_minimum_size = Vector2(18, 18)
		swatch.color = DamageTypes.TYPE_COLORS[dtype]
		row.add_child(swatch)
		var lab := Label.new()
		lab.text = str(DamageTypes.TYPE_NAMES[dtype])
		UiTheme.apply_font(lab, 14, DamageTypes.TYPE_COLORS[dtype], "medium")
		row.add_child(lab)
		rv.add_child(row)
	v.add_child(rule)


func _codex_card(e: Dictionary) -> PanelContainer:
	var armor: int = int(e["armor"])
	var color: Color = DamageTypes.ARMOR_COLORS[armor]
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.slot_style(false))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	panel.add_child(h)

	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(88, 88)
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Color(color.r, color.g, color.b, 0.22)
	badge_style.border_color = color
	badge_style.set_border_width_all(2)
	badge_style.set_corner_radius_all(4)
	badge.add_theme_stylebox_override("panel", badge_style)
	var badge_l := Label.new()
	badge_l.text = str(DamageTypes.ARMOR_NAMES[armor])
	badge_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UiTheme.apply_font(badge_l, 14, color, "semibold")
	badge.add_child(badge_l)
	h.add_child(badge)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 4)
	h.add_child(col)
	var title := Label.new()
	title.text = str(e["title"])
	UiTheme.apply_font(title, 18, UiTheme.C_TEXT, "semibold")
	col.add_child(title)
	var weak := Label.new()
	weak.text = "약점 속성: %s" % str(e["weak"])
	UiTheme.apply_font(weak, 14, color, "medium")
	col.add_child(weak)
	var desc := Label.new()
	desc.text = str(e["desc"])
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiTheme.apply_font(desc, 13, UiTheme.C_MUTED, "regular")
	col.add_child(desc)
	var tip := Label.new()
	tip.text = str(e["tip"])
	UiTheme.apply_font(tip, 13, Color(0.7, 0.95, 0.85), "medium")
	col.add_child(tip)
	return panel


func _refresh_equip_page() -> void:
	var root := equip_page.get_node_or_null("RootVBox")
	if root == null:
		_build_equip_page()
		root = equip_page.get_node("RootVBox")
	var slots: HBoxContainer = root.get_node("Slots")
	while slots.get_child_count() > 0:
		var sc := slots.get_child(0)
		slots.remove_child(sc)
		sc.free()
	slots.add_child(_slot_card("주무기", Loadout.primary_id, "primary"))
	slots.add_child(_slot_card("보조무기", Loadout.secondary_id, "secondary"))

	var grid: GridContainer = root.get_node("ListPanel/Outer/Scroll/WeaponGrid")
	while grid.get_child_count() > 0:
		var ch := grid.get_child(0)
		grid.remove_child(ch)
		ch.free()
	for w in WeaponCatalog.WEAPONS:
		grid.add_child(_inventory_cell(w))


func _icon_for(weapon_id: String) -> Texture2D:
	var path := ICON_DIR + weapon_id + ".svg"
	if ResourceLoader.exists(path):
		return load(path)
	return null


func _inventory_cell(w: Dictionary) -> PanelContainer:
	var id := str(w["id"])
	var selected := id == Loadout.primary_id or id == Loadout.secondary_id
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(120, 148)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", UiTheme.slot_style(selected))
	panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(v)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(72, 72)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = _icon_for(id)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(icon)

	var name_l := Label.new()
	name_l.text = str(w["name"])
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTheme.apply_font(name_l, 15, UiTheme.C_TEXT, "semibold")
	name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(name_l)

	var meta := Label.new()
	meta.text = WeaponCatalog.type_label(int(w["dmg_type"]))
	meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTheme.apply_font(meta, 14, DamageTypes.TYPE_COLORS.get(int(w["dmg_type"]), Color(0.85, 0.9, 0.95)), "medium")
	meta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(meta)

	if id == Loadout.primary_id:
		var badge := Label.new()
		badge.text = "주무기"
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UiTheme.apply_font(badge, 11, UiTheme.C_ACCENT, "medium")
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(badge)
	elif id == Loadout.secondary_id:
		var badge2 := Label.new()
		badge2.text = "보조"
		badge2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UiTheme.apply_font(badge2, 11, Color(0.95, 0.85, 0.55), "medium")
		badge2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(badge2)

	panel.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_open_detail(id)
	)
	return panel


func _slot_card(title: String, weapon_id: String, _slot_key: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.panel_style(Color(0.35, 0.85, 1.0, 0.55)))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	panel.add_child(h)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(64, 64)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = _icon_for(weapon_id)
	h.add_child(icon)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var t := Label.new()
	t.text = title
	UiTheme.apply_font(t, 13, UiTheme.C_MUTED, "regular")
	v.add_child(t)
	var w := WeaponCatalog.get_by_id(weapon_id)
	var name_l := Label.new()
	name_l.text = str(w.get("name", "없음"))
	UiTheme.apply_font(name_l, 20, UiTheme.C_TEXT, "semibold")
	v.add_child(name_l)
	var meta := Label.new()
	meta.text = "%s / 피해 %.0f / 탄창 %d" % [
		WeaponCatalog.type_label(int(w.get("dmg_type", 0))),
		float(w.get("damage", 0.0)),
		int(w.get("ammo", 0)),
	]
	UiTheme.apply_font(meta, 13, Color(0.8, 0.9, 0.7), "regular")
	v.add_child(meta)
	var open := _make_btn("상세", Vector2(90, 36))
	open.pressed.connect(_open_detail.bind(weapon_id))
	h.add_child(open)
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
	settings_modal.color = Color(0.01, 0.03, 0.06, 0.82)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	settings_modal.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.panel_style())
	panel.custom_minimum_size = Vector2(420, 320)
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)
	v.add_child(_section_title("사운드 설정", 22))
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
	UiTheme.apply_font(lab, 16, UiTheme.C_TEXT, "medium")
	row.add_child(lab)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
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
	slider.set_value_no_signal(value)
	row.add_child(slider)
	return row


func _open_settings() -> void:
	Sfx.ensure_web_unlocked()
	_build_settings_modal()
	settings_modal.visible = true


func _open_detail(id: String) -> void:
	_detail_id = id
	var w := WeaponCatalog.get_by_id(id)
	if w.is_empty():
		return
	for c in detail_modal.get_children():
		c.queue_free()
	detail_modal.color = Color(0.01, 0.03, 0.06, 0.82)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	detail_modal.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.panel_style())
	panel.custom_minimum_size = Vector2(520, 400)
	center.add_child(panel)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 16)
	panel.add_child(body)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(120, 120)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = _icon_for(id)
	body.add_child(icon)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 8)
	body.add_child(col)

	var title := Label.new()
	title.text = str(w["name"])
	UiTheme.apply_font(title, 26, UiTheme.C_TEXT, "semibold")
	col.add_child(title)

	var type_l := Label.new()
	type_l.text = "속성: %s" % WeaponCatalog.type_label(int(w["dmg_type"]))
	UiTheme.apply_font(type_l, 16, DamageTypes.TYPE_COLORS.get(int(w["dmg_type"]), Color.WHITE), "medium")
	col.add_child(type_l)

	var lines := [
		"설명: %s" % str(w.get("note", "")),
		"피해: %.1f" % float(w["damage"]),
		"공격 간격: %.2fs" % float(w["cooldown"]),
		"사거리: %.0f" % float(w["range"]),
		"탄창: %d / 장전: %.2fs" % [int(w["ammo"]), float(w["reload"])],
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
		UiTheme.apply_font(lab, 14, UiTheme.C_MUTED, "regular")
		col.add_child(lab)

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
	col.add_child(row)
	detail_modal.visible = true
