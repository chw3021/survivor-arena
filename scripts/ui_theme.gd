extends Node

## 메뉴/HUD 테마 팩. 기본=stone(플랫). grunge/clean/simple 은 9-slice 스킨.
## theme_changed 로 메뉴가 다시 그려진다.

signal theme_changed(theme_id: String)

const BODY_FONT_PATH := "res://fonts/NotoSansKR-Regular.ttf"
const FALLBACK_FONT_PATH := "res://fonts/Jua-Regular.ttf"
const SKIN_ROOT := "res://assets/ui/skins/"

const THEME_STONE := "stone"
const THEME_GRUNGE := "grunge"
const THEME_CLEAN := "clean"
const THEME_SIMPLE := "simple"

const THEME_ORDER := [THEME_STONE, THEME_GRUNGE, THEME_CLEAN, THEME_SIMPLE]

const THEME_NAMES := {
	THEME_STONE: "스톤 캐주얼",
	THEME_GRUNGE: "꼬질 귀여움",
	THEME_CLEAN: "클린 캐주얼",
	THEME_SIMPLE: "심플 오렌지",
}

## 하위호환: 예전 코드가 UiTheme.C_TEXT 등을 직접 참조.
var C_ACCENT: Color = Color(0.35, 0.78, 0.95, 1.0)
var C_ACCENT_WARM: Color = Color(0.98, 0.72, 0.28, 1.0)
var C_PANEL: Color = Color(0.2, 0.22, 0.26, 0.94)
var C_PANEL_INNER: Color = Color(0.16, 0.18, 0.22, 0.96)
var C_BTN: Color = Color(0.28, 0.32, 0.38, 1.0)
var C_BTN_HOVER: Color = Color(0.36, 0.42, 0.5, 1.0)
var C_BTN_ACTIVE: Color = Color(0.22, 0.48, 0.62, 1.0)
var C_BTN_CTA: Color = Color(0.28, 0.72, 0.42, 1.0)
var C_BTN_CTA_BORDER: Color = Color(0.18, 0.5, 0.28, 1.0)
var C_TEXT: Color = Color(0.98, 0.98, 0.99, 1.0)
var C_MUTED: Color = Color(0.82, 0.86, 0.9, 1.0)
var C_OUTLINE: Color = Color(0.05, 0.06, 0.08, 0.85)
var C_BORDER: Color = Color(0.62, 0.68, 0.76, 0.95)
var C_SLOT: Color = Color(0.24, 0.27, 0.32, 0.98)
var C_SLOT_SEL: Color = Color(0.22, 0.36, 0.44, 0.98)
var C_DIM: Color = Color(0.08, 0.09, 0.12, 0.55)
var corner_radius: int = 14
var border_width: int = 2
var bg_path: String = "res://assets/ui/menu_bg_stone.jpg"

## flat | texture
var style_mode: String = "flat"
var skin_dir: String = ""
var slice_margin: int = 16
var shadow_size: int = 8
var shadow_offset: Vector2 = Vector2(0, 3)
var decor_enabled: bool = false
var decor_size: int = 28

var theme_id: String = THEME_STONE

var _regular: Font
var _medium: Font
var _semibold: Font
var _tex_cache: Dictionary = {}


func _ready() -> void:
	font()
	call_deferred("_boot_theme")


func _boot_theme() -> void:
	if Loadout != null and str(Loadout.ui_theme_id) != "":
		apply_theme(str(Loadout.ui_theme_id), false)
	else:
		apply_theme(THEME_STONE, false)


func apply_theme(id: String, emit_signal: bool = true) -> void:
	if not THEME_NAMES.has(id):
		id = THEME_STONE
	theme_id = id
	_tex_cache.clear()
	_apply_palette(id)
	if emit_signal:
		theme_changed.emit(theme_id)


func bg_texture_path() -> String:
	if ResourceLoader.exists(bg_path):
		return bg_path
	if ResourceLoader.exists("res://assets/ui/menu_bg.jpg"):
		return "res://assets/ui/menu_bg.jpg"
	return bg_path


func _apply_palette(id: String) -> void:
	match id:
		THEME_GRUNGE:
			C_ACCENT = Color(0.78, 0.22, 0.22, 1.0)
			C_ACCENT_WARM = Color(0.9, 0.55, 0.25, 1.0)
			C_PANEL = Color(0.86, 0.8, 0.7, 0.92)
			C_PANEL_INNER = Color(0.8, 0.74, 0.64, 0.95)
			C_BTN = Color(0.72, 0.66, 0.56, 1.0)
			C_BTN_HOVER = Color(0.8, 0.74, 0.64, 1.0)
			C_BTN_ACTIVE = Color(0.55, 0.28, 0.26, 1.0)
			C_BTN_CTA = Color(0.72, 0.28, 0.28, 1.0)
			C_BTN_CTA_BORDER = Color(0.35, 0.12, 0.12, 1.0)
			C_TEXT = Color(0.16, 0.14, 0.12, 1.0)
			C_MUTED = Color(0.38, 0.34, 0.3, 1.0)
			C_OUTLINE = Color(0.95, 0.92, 0.86, 0.55)
			C_BORDER = Color(0.28, 0.24, 0.2, 0.9)
			C_SLOT = Color(0.9, 0.85, 0.76, 0.98)
			C_SLOT_SEL = Color(0.92, 0.78, 0.72, 0.98)
			C_DIM = Color(0.25, 0.2, 0.16, 0.45)
			corner_radius = 8
			border_width = 3
			bg_path = "res://assets/ui/menu_bg_grunge.jpg"
			style_mode = "texture"
			skin_dir = SKIN_ROOT + "grunge"
			slice_margin = 14
			shadow_size = 10
			shadow_offset = Vector2(1, 4)
			decor_enabled = true
			decor_size = 30
		THEME_CLEAN:
			# 오렌지 캐주얼 BG 위: 따뜻한 다크 카드 + 노란 CTA (흰 글자/흰 버튼 금지)
			C_ACCENT = Color(1.0, 0.78, 0.2, 1.0)
			C_ACCENT_WARM = Color(1.0, 0.7, 0.25, 1.0)
			C_PANEL = Color(0.16, 0.12, 0.1, 0.92)
			C_PANEL_INNER = Color(0.2, 0.15, 0.12, 0.95)
			C_BTN = Color(0.22, 0.16, 0.12, 1.0)
			C_BTN_HOVER = Color(0.32, 0.24, 0.16, 1.0)
			C_BTN_ACTIVE = Color(0.85, 0.55, 0.12, 1.0)
			C_BTN_CTA = Color(1.0, 0.82, 0.18, 1.0)
			C_BTN_CTA_BORDER = Color(0.72, 0.48, 0.08, 1.0)
			C_TEXT = Color(1.0, 0.98, 0.94, 1.0)
			C_MUTED = Color(0.9, 0.82, 0.7, 1.0)
			C_OUTLINE = Color(0.08, 0.05, 0.03, 0.85)
			C_BORDER = Color(0.95, 0.7, 0.28, 0.95)
			C_SLOT = Color(0.2, 0.15, 0.12, 0.96)
			C_SLOT_SEL = Color(0.35, 0.24, 0.12, 0.98)
			C_DIM = Color(0.18, 0.1, 0.05, 0.45)
			corner_radius = 16
			border_width = 3
			bg_path = "res://assets/ui/menu_bg_clean.jpg"
			style_mode = "texture"
			skin_dir = SKIN_ROOT + "clean"
			slice_margin = 16
			shadow_size = 12
			shadow_offset = Vector2(0, 5)
			decor_enabled = true
			decor_size = 26
		THEME_SIMPLE:
			C_ACCENT = Color(0.95, 0.62, 0.22, 1.0)
			C_ACCENT_WARM = Color(0.98, 0.75, 0.3, 1.0)
			C_PANEL = Color(0.96, 0.92, 0.84, 0.95)
			C_PANEL_INNER = Color(1.0, 0.97, 0.9, 0.98)
			C_BTN = Color(0.95, 0.7, 0.32, 1.0)
			C_BTN_HOVER = Color(1.0, 0.78, 0.4, 1.0)
			C_BTN_ACTIVE = Color(0.9, 0.55, 0.18, 1.0)
			C_BTN_CTA = Color(0.35, 0.78, 0.42, 1.0)
			C_BTN_CTA_BORDER = Color(0.2, 0.55, 0.28, 1.0)
			C_TEXT = Color(0.28, 0.22, 0.16, 1.0)
			C_MUTED = Color(0.45, 0.38, 0.3, 1.0)
			C_OUTLINE = Color(1.0, 0.98, 0.94, 0.65)
			C_BORDER = Color(0.9, 0.58, 0.2, 1.0)
			C_SLOT = Color(1.0, 0.96, 0.88, 0.98)
			C_SLOT_SEL = Color(1.0, 0.9, 0.7, 0.98)
			C_DIM = Color(0.55, 0.4, 0.2, 0.35)
			corner_radius = 22
			border_width = 4
			bg_path = "res://assets/ui/menu_bg_simple.jpg"
			style_mode = "texture"
			skin_dir = SKIN_ROOT + "simple"
			slice_margin = 20
			shadow_size = 6
			shadow_offset = Vector2(0, 3)
			decor_enabled = true
			decor_size = 28
		_:
			C_ACCENT = Color(0.35, 0.78, 0.95, 1.0)
			C_ACCENT_WARM = Color(0.98, 0.72, 0.28, 1.0)
			C_PANEL = Color(0.2, 0.22, 0.26, 0.94)
			C_PANEL_INNER = Color(0.16, 0.18, 0.22, 0.96)
			C_BTN = Color(0.28, 0.32, 0.38, 1.0)
			C_BTN_HOVER = Color(0.36, 0.42, 0.5, 1.0)
			C_BTN_ACTIVE = Color(0.22, 0.48, 0.62, 1.0)
			C_BTN_CTA = Color(0.28, 0.72, 0.42, 1.0)
			C_BTN_CTA_BORDER = Color(0.18, 0.5, 0.28, 1.0)
			C_TEXT = Color(0.98, 0.98, 0.99, 1.0)
			C_MUTED = Color(0.82, 0.86, 0.9, 1.0)
			C_OUTLINE = Color(0.05, 0.06, 0.08, 0.85)
			C_BORDER = Color(0.62, 0.68, 0.76, 0.95)
			C_SLOT = Color(0.24, 0.27, 0.32, 0.98)
			C_SLOT_SEL = Color(0.22, 0.36, 0.44, 0.98)
			C_DIM = Color(0.08, 0.09, 0.12, 0.55)
			corner_radius = 14
			border_width = 2
			bg_path = "res://assets/ui/menu_bg_stone.jpg"
			style_mode = "flat"
			skin_dir = ""
			slice_margin = 14
			shadow_size = 8
			shadow_offset = Vector2(0, 3)
			decor_enabled = false
			decor_size = 24


func font() -> Font:
	return medium_font()


func regular_font() -> Font:
	if _regular != null:
		return _regular
	_regular = _variation(560, 0.18)
	return _regular


func medium_font() -> Font:
	if _medium != null:
		return _medium
	_medium = _variation(620, 0.28)
	return _medium


func semibold_font() -> Font:
	if _semibold != null:
		return _semibold
	_semibold = _variation(700, 0.38)
	return _semibold


func _load_base() -> Font:
	if ResourceLoader.exists(BODY_FONT_PATH):
		return load(BODY_FONT_PATH)
	if ResourceLoader.exists(FALLBACK_FONT_PATH):
		return load(FALLBACK_FONT_PATH)
	return null


func _variation(weight: int, embolden: float) -> Font:
	var base := _load_base()
	if base == null:
		return null
	var fv := FontVariation.new()
	fv.base_font = base
	fv.variation_opentype = {0x77676874: weight}
	fv.variation_embolden = embolden
	return fv


func apply_font(node: Control, size: int = -1, color: Color = Color(-1, -1, -1, -1), weight: String = "medium") -> void:
	var f: Font
	match weight:
		"regular":
			f = regular_font()
		"semibold":
			f = semibold_font()
		_:
			f = medium_font()
	if f == null or node == null:
		return
	node.add_theme_font_override("font", f)
	var use_size := size if size > 0 else 16
	use_size = maxi(use_size, 14)
	node.add_theme_font_size_override("font_size", use_size)
	if color.r >= 0.0:
		node.add_theme_color_override("font_color", color)
	else:
		node.add_theme_color_override("font_color", C_TEXT)
	node.add_theme_color_override("font_outline_color", C_OUTLINE)
	node.add_theme_constant_override("outline_size", 2 if use_size < 20 else 3)


func apply_tree(root: Node) -> void:
	var f := medium_font()
	if f == null or root == null:
		return
	_apply_recursive(root, f)


func _apply_recursive(node: Node, f: Font) -> void:
	if node is Control:
		var c := node as Control
		if c is Label or c is Button or c is LineEdit or c is RichTextLabel or c is CheckBox or c is OptionButton:
			c.add_theme_font_override("font", f)
			c.add_theme_color_override("font_outline_color", C_OUTLINE)
			c.add_theme_constant_override("outline_size", 2)
	for child in node.get_children():
		_apply_recursive(child, f)


func _skin_tex(file_name: String) -> Texture2D:
	if skin_dir == "":
		return null
	var path := "%s/%s" % [skin_dir, file_name]
	if _tex_cache.has(path):
		return _tex_cache[path]
	if not ResourceLoader.exists(path):
		return null
	var tex: Texture2D = load(path)
	_tex_cache[path] = tex
	return tex


func _texture_box(file_name: String, margin_l: float, margin_t: float, margin_r: float, margin_b: float) -> StyleBoxTexture:
	var tex := _skin_tex(file_name)
	if tex == null:
		return null
	var box := StyleBoxTexture.new()
	box.texture = tex
	var sm := float(slice_margin)
	box.texture_margin_left = sm
	box.texture_margin_top = sm
	box.texture_margin_right = sm
	box.texture_margin_bottom = sm
	box.content_margin_left = margin_l
	box.content_margin_top = margin_t
	box.content_margin_right = margin_r
	box.content_margin_bottom = margin_b
	return box


func apply_panel(panel: PanelContainer) -> void:
	if panel == null:
		return
	panel.add_theme_stylebox_override("panel", panel_style())


func apply_slot(panel: PanelContainer, selected: bool = false) -> void:
	if panel == null:
		return
	panel.add_theme_stylebox_override("panel", slot_style(selected))


## host 는 PanelContainer 가 아닌 Control 셸이어야 한다 (컨테이너 레이아웃 깨짐 방지).
func decorate_panel(host: Control) -> void:
	if host == null:
		return
	for c in host.get_children():
		if str(c.name).begins_with("__theme_decor"):
			c.queue_free()
	if not decor_enabled or style_mode != "texture":
		return
	var tex := _skin_tex("decor_corner.png")
	if tex == null:
		return
	_add_decor(host, tex, Control.PRESET_TOP_LEFT, false, false, 0)
	_add_decor(host, tex, Control.PRESET_TOP_RIGHT, true, false, 1)
	_add_decor(host, tex, Control.PRESET_BOTTOM_LEFT, false, true, 2)
	_add_decor(host, tex, Control.PRESET_BOTTOM_RIGHT, true, true, 3)


func _add_decor(host: Control, tex: Texture2D, preset: int, flip_h: bool, flip_v: bool, idx: int) -> void:
	var tr := TextureRect.new()
	tr.name = "__theme_decor_%d" % idx
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.custom_minimum_size = Vector2(decor_size, decor_size)
	tr.size = Vector2(decor_size, decor_size)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.flip_h = flip_h
	tr.flip_v = flip_v
	tr.z_index = 8
	tr.set_anchors_and_offsets_preset(preset)
	var inset := 4.0
	match preset:
		Control.PRESET_TOP_LEFT:
			tr.offset_left = inset
			tr.offset_top = inset
			tr.offset_right = inset + decor_size
			tr.offset_bottom = inset + decor_size
		Control.PRESET_TOP_RIGHT:
			tr.offset_left = -inset - decor_size
			tr.offset_top = inset
			tr.offset_right = -inset
			tr.offset_bottom = inset + decor_size
		Control.PRESET_BOTTOM_LEFT:
			tr.offset_left = inset
			tr.offset_top = -inset - decor_size
			tr.offset_right = inset + decor_size
			tr.offset_bottom = -inset
		_:
			tr.offset_left = -inset - decor_size
			tr.offset_top = -inset - decor_size
			tr.offset_right = -inset
			tr.offset_bottom = -inset
	host.add_child(tr)


func panel_style(_accent: Color = Color(0.6, 0.65, 0.72, 0.9)) -> StyleBox:
	if style_mode == "texture":
		var tex_box := _texture_box("panel_9slice.png", 18, 16, 18, 16)
		if tex_box != null:
			return tex_box
	var box := StyleBoxFlat.new()
	box.bg_color = C_PANEL
	box.set_corner_radius_all(corner_radius)
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 14
	box.content_margin_bottom = 14
	box.border_color = C_BORDER
	box.set_border_width_all(border_width)
	box.shadow_color = Color(0, 0, 0, 0.3)
	box.shadow_size = shadow_size
	box.shadow_offset = shadow_offset
	return box


func slot_style(selected: bool = false) -> StyleBox:
	if style_mode == "texture":
		var tex_box := _texture_box("slot_9slice.png", 12, 12, 12, 12)
		if tex_box != null:
			if selected:
				tex_box.modulate = Color(1.08, 1.02, 0.95, 1.0).lerp(C_ACCENT, 0.25)
			return tex_box
	var box := StyleBoxFlat.new()
	box.bg_color = C_SLOT_SEL if selected else C_SLOT
	box.set_corner_radius_all(maxi(8, corner_radius - 2))
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	box.border_color = C_ACCENT if selected else C_BORDER
	box.set_border_width_all(border_width + (1 if selected else 0))
	box.shadow_color = Color(0, 0, 0, 0.25)
	box.shadow_size = 4
	box.shadow_offset = Vector2(0, 2)
	return box


## StyleBoxTexture.modulate 는 웹에서 버튼에 거의 안 먹어서, 버튼은 항상 Flat.
func button_style(kind: String = "normal") -> StyleBox:
	var box := StyleBoxFlat.new()
	box.set_corner_radius_all(maxi(10, corner_radius - 2))
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 12
	box.content_margin_bottom = 12
	box.set_border_width_all(border_width)
	box.shadow_color = Color(0, 0, 0, 0.28)
	box.shadow_size = 4
	box.shadow_offset = Vector2(0, 2)
	match kind:
		"hover":
			box.bg_color = C_BTN_HOVER
			box.border_color = C_ACCENT
		"active", "pressed":
			box.bg_color = C_BTN_ACTIVE
			box.border_color = C_ACCENT
		"cta":
			box.bg_color = C_BTN_CTA
			box.border_color = C_BTN_CTA_BORDER
		_:
			box.bg_color = C_BTN
			box.border_color = C_BORDER
	return box


func contrast_on(bg: Color) -> Color:
	if bg.get_luminance() > 0.55:
		return Color(0.14, 0.11, 0.08, 1.0)
	return Color(0.99, 0.98, 0.96, 1.0)


func is_light_surface() -> bool:
	return C_SLOT.get_luminance() > 0.55 or C_PANEL.get_luminance() > 0.55


## 밝은 패널(꼬질/심플) 위에서 노랑/연한 속성색이 안 죽는 버전.
func readable_color(c: Color, against: Color = Color(-1, -1, -1, -1)) -> Color:
	var bg := against if against.a >= 0.0 else C_SLOT
	var bg_lum := bg.get_luminance()
	var c_lum := c.get_luminance()
	if bg_lum > 0.55 and c_lum > 0.42:
		var h := c.h
		var s := clampf(c.s * 1.35, 0.55, 1.0)
		var v := clampf(c.v * 0.42, 0.22, 0.48)
		if c_lum > 0.75 and c.s < 0.2:
			# 거의 흰/회색 라벨 -> 잉크색
			return Color(0.28, 0.22, 0.18, 1.0)
		return Color.from_hsv(h, s, v, 1.0)
	if bg_lum < 0.35 and c_lum < 0.28:
		return c.lightened(0.35)
	return c


func type_color(dmg_type: int) -> Color:
	var base: Color = DamageTypes.TYPE_COLORS.get(dmg_type, Color(0.85, 0.9, 0.95))
	return readable_color(base)


func button_label_color(kind: String = "normal") -> Color:
	match kind:
		"hover":
			return contrast_on(C_BTN_HOVER)
		"active", "pressed":
			return contrast_on(C_BTN_ACTIVE)
		"cta":
			return contrast_on(C_BTN_CTA)
		_:
			return contrast_on(C_BTN)


func style_button(b: Button, active: bool = false) -> void:
	var kind := "active" if active else "normal"
	apply_font(b, 16, button_label_color(kind), "semibold")
	b.add_theme_stylebox_override("normal", button_style(kind))
	b.add_theme_stylebox_override("hover", button_style("hover"))
	b.add_theme_stylebox_override("pressed", button_style("pressed"))
	b.add_theme_stylebox_override("focus", button_style("hover"))


func style_cta_button(b: Button) -> void:
	apply_font(b, 16, button_label_color("cta"), "semibold")
	b.add_theme_stylebox_override("normal", button_style("cta"))
	b.add_theme_stylebox_override("hover", button_style("cta"))
	b.add_theme_stylebox_override("pressed", button_style("pressed"))
	b.add_theme_stylebox_override("focus", button_style("cta"))
