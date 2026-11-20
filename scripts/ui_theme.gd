extends Node

## 사이버네온 UI 테마 + 한글 폰트.
## 표시: Noto Sans KR (중간 굵기). Black Han Sans는 너무 두꺼워서 쓰지 않음.

const BODY_FONT_PATH := "res://fonts/NotoSansKR-Regular.ttf"
const FALLBACK_FONT_PATH := "res://fonts/Jua-Regular.ttf"

const C_ACCENT := Color(0.25, 0.9, 1.0, 1.0)
const C_ACCENT_DIM := Color(0.2, 0.55, 0.7, 0.85)
const C_PANEL := Color(0.04, 0.07, 0.12, 0.82)
const C_PANEL_INNER := Color(0.06, 0.1, 0.16, 0.92)
const C_BTN := Color(0.08, 0.14, 0.2, 0.92)
const C_BTN_HOVER := Color(0.1, 0.22, 0.3, 0.96)
const C_BTN_ACTIVE := Color(0.08, 0.32, 0.42, 0.98)
const C_TEXT := Color(0.92, 0.96, 1.0, 1.0)
const C_MUTED := Color(0.65, 0.75, 0.84, 1.0)

var _regular: Font
var _medium: Font
var _semibold: Font


func _ready() -> void:
	font()


func font() -> Font:
	return medium_font()


func regular_font() -> Font:
	if _regular != null:
		return _regular
	_regular = _load_base()
	return _regular


func medium_font() -> Font:
	if _medium != null:
		return _medium
	_medium = _variation(500, 0.05)
	return _medium


func semibold_font() -> Font:
	if _semibold != null:
		return _semibold
	_semibold = _variation(600, 0.12)
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
	fv.variation_opentype = {0x77676874: weight} # wght
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
	if size > 0:
		node.add_theme_font_size_override("font_size", size)
	if color.r >= 0.0:
		node.add_theme_color_override("font_color", color)


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
	for child in node.get_children():
		_apply_recursive(child, f)


func panel_style(accent: Color = C_ACCENT_DIM) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = C_PANEL
	box.set_corner_radius_all(4)
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 14
	box.content_margin_bottom = 14
	box.border_color = accent
	box.set_border_width_all(1)
	box.shadow_color = Color(0.1, 0.7, 0.9, 0.18)
	box.shadow_size = 6
	return box


func slot_style(selected: bool = false) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = C_PANEL_INNER if not selected else Color(0.08, 0.2, 0.28, 0.95)
	box.set_corner_radius_all(3)
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	box.border_color = C_ACCENT if selected else Color(0.35, 0.55, 0.7, 0.45)
	box.set_border_width_all(2 if selected else 1)
	return box


func button_style(kind: String = "normal") -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.set_corner_radius_all(2)
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 12
	box.content_margin_bottom = 12
	box.set_border_width_all(1)
	match kind:
		"hover":
			box.bg_color = C_BTN_HOVER
			box.border_color = Color(0.45, 0.95, 1.0, 0.75)
		"active", "pressed":
			box.bg_color = C_BTN_ACTIVE
			box.border_color = C_ACCENT
		_:
			box.bg_color = C_BTN
			box.border_color = Color(0.3, 0.55, 0.7, 0.55)
	return box


func style_button(b: Button, active: bool = false) -> void:
	apply_font(b, 16, C_TEXT, "medium")
	b.add_theme_stylebox_override("normal", button_style("active" if active else "normal"))
	b.add_theme_stylebox_override("hover", button_style("hover"))
	b.add_theme_stylebox_override("pressed", button_style("pressed"))
	b.add_theme_stylebox_override("focus", button_style("hover"))
