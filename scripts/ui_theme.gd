extends Node

## 캐주얼 스톤톤 UI + 읽기 쉬운 한글 폰트.
## Noto Sans KR 중간~세미볼드 + 외곽선. 가는 글씨/네온 테마 금지.

const BODY_FONT_PATH := "res://fonts/NotoSansKR-Regular.ttf"
const FALLBACK_FONT_PATH := "res://fonts/Jua-Regular.ttf"

const C_ACCENT := Color(0.35, 0.78, 0.95, 1.0)
const C_ACCENT_WARM := Color(0.98, 0.72, 0.28, 1.0)
const C_PANEL := Color(0.2, 0.22, 0.26, 0.94)
const C_PANEL_INNER := Color(0.16, 0.18, 0.22, 0.96)
const C_BTN := Color(0.28, 0.32, 0.38, 1.0)
const C_BTN_HOVER := Color(0.36, 0.42, 0.5, 1.0)
const C_BTN_ACTIVE := Color(0.22, 0.48, 0.62, 1.0)
const C_TEXT := Color(0.98, 0.98, 0.99, 1.0)
const C_MUTED := Color(0.82, 0.86, 0.9, 1.0)
const C_OUTLINE := Color(0.05, 0.06, 0.08, 0.85)

var _regular: Font
var _medium: Font
var _semibold: Font


func _ready() -> void:
	font()


func font() -> Font:
	return medium_font()


func regular_font() -> Font:
	## 가는 regular는 웹에서 깨져 보이므로 medium에 가깝게.
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
	var use_size := size if size > 0 else 16
	# 한글 가독성: 너무 작은 사이즈 금지
	use_size = maxi(use_size, 14)
	node.add_theme_font_size_override("font_size", use_size)
	if color.r >= 0.0:
		node.add_theme_color_override("font_color", color)
	else:
		node.add_theme_color_override("font_color", C_TEXT)
	# 가는 획/안티앨리어싱 깨짐 완화
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


func panel_style(_accent: Color = Color(0.6, 0.65, 0.72, 0.9)) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = C_PANEL
	box.set_corner_radius_all(14)
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 14
	box.content_margin_bottom = 14
	box.border_color = Color(0.62, 0.68, 0.76, 0.95)
	box.set_border_width_all(2)
	box.shadow_color = Color(0, 0, 0, 0.35)
	box.shadow_size = 8
	box.shadow_offset = Vector2(0, 3)
	return box


func slot_style(selected: bool = false) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.24, 0.27, 0.32, 0.98) if not selected else Color(0.22, 0.36, 0.44, 0.98)
	box.set_corner_radius_all(12)
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	box.border_color = C_ACCENT if selected else Color(0.55, 0.6, 0.68, 0.9)
	box.set_border_width_all(3 if selected else 2)
	box.shadow_color = Color(0, 0, 0, 0.28)
	box.shadow_size = 4
	box.shadow_offset = Vector2(0, 2)
	return box


func button_style(kind: String = "normal") -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.set_corner_radius_all(12)
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 12
	box.content_margin_bottom = 12
	box.set_border_width_all(2)
	box.shadow_color = Color(0, 0, 0, 0.3)
	box.shadow_size = 4
	box.shadow_offset = Vector2(0, 2)
	match kind:
		"hover":
			box.bg_color = C_BTN_HOVER
			box.border_color = Color(0.78, 0.84, 0.92, 1.0)
		"active", "pressed":
			box.bg_color = C_BTN_ACTIVE
			box.border_color = C_ACCENT
		"cta":
			box.bg_color = Color(0.28, 0.72, 0.42, 1.0)
			box.border_color = Color(0.18, 0.5, 0.28, 1.0)
		_:
			box.bg_color = C_BTN
			box.border_color = Color(0.58, 0.64, 0.72, 1.0)
	return box


func style_button(b: Button, active: bool = false) -> void:
	apply_font(b, 16, C_TEXT, "semibold")
	b.add_theme_stylebox_override("normal", button_style("active" if active else "normal"))
	b.add_theme_stylebox_override("hover", button_style("hover"))
	b.add_theme_stylebox_override("pressed", button_style("pressed"))
	b.add_theme_stylebox_override("focus", button_style("hover"))
