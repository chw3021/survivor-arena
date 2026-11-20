extends Node

## 프로젝트 UI 공통 폰트/스타일.
## 한글은 Noto Sans KR 고정. 특수 구두점 대신 ASCII -/ / ... 사용.

const FONT_PATH := "res://fonts/NotoSansKR-Regular.ttf"
const FALLBACK_FONT_PATH := "res://fonts/Jua-Regular.ttf"

var _font: Font


func font() -> Font:
	if _font != null:
		return _font
	if ResourceLoader.exists(FONT_PATH):
		_font = load(FONT_PATH)
	elif ResourceLoader.exists(FALLBACK_FONT_PATH):
		_font = load(FALLBACK_FONT_PATH)
	return _font


func apply_font(node: Control, size: int = -1, color: Color = Color(-1, -1, -1, -1)) -> void:
	var f := font()
	if f == null or node == null:
		return
	node.add_theme_font_override("font", f)
	if size > 0:
		node.add_theme_font_size_override("font_size", size)
	if color.r >= 0.0:
		node.add_theme_color_override("font_color", color)


func apply_tree(root: Node) -> void:
	var f := font()
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


func panel_style(accent: Color = Color(0.25, 0.85, 0.95, 0.35)) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.05, 0.07, 0.1, 0.78)
	box.set_corner_radius_all(10)
	box.content_margin_left = 14
	box.content_margin_right = 14
	box.content_margin_top = 12
	box.content_margin_bottom = 12
	box.border_color = accent
	box.set_border_width_all(1)
	return box


func slot_style(selected: bool = false) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.08, 0.1, 0.14, 0.9) if not selected else Color(0.12, 0.18, 0.22, 0.95)
	box.set_corner_radius_all(8)
	box.content_margin_left = 8
	box.content_margin_right = 8
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	box.border_color = Color(0.35, 0.9, 1.0, 0.85) if selected else Color(1, 1, 1, 0.12)
	box.set_border_width_all(2 if selected else 1)
	return box
