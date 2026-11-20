extends Node

## 프로젝트 UI 공통 폰트/스타일.
## 표시용: Black Han Sans / 본문 폴백: Noto Sans KR
## 특수 구두점 대신 ASCII -/ / ... 사용.

const DISPLAY_FONT_PATH := "res://fonts/BlackHanSans-Regular.ttf"
const BODY_FONT_PATH := "res://fonts/NotoSansKR-Regular.ttf"
const FALLBACK_FONT_PATH := "res://fonts/Jua-Regular.ttf"

var _display: Font
var _body: Font


func _ready() -> void:
	font()
	display_font()


func font() -> Font:
	## 기본 UI 폰트 (버튼/라벨) - 게임용 두꺼운 고딕.
	return display_font()


func display_font() -> Font:
	if _display != null:
		return _display
	if ResourceLoader.exists(DISPLAY_FONT_PATH):
		_display = load(DISPLAY_FONT_PATH)
	elif ResourceLoader.exists(BODY_FONT_PATH):
		_display = _make_bold_body()
	elif ResourceLoader.exists(FALLBACK_FONT_PATH):
		_display = load(FALLBACK_FONT_PATH)
	return _display


func body_font() -> Font:
	if _body != null:
		return _body
	if ResourceLoader.exists(BODY_FONT_PATH):
		_body = _make_bold_body()
	else:
		_body = display_font()
	return _body


func _make_bold_body() -> Font:
	var base: Font = load(BODY_FONT_PATH)
	var fv := FontVariation.new()
	fv.base_font = base
	# 가변 폰트 굵기 + 살짝 embolden (웹/에디터 모두 커버)
	fv.variation_opentype = {0x77676874: 700} # wght
	fv.variation_embolden = 0.3
	return fv


func apply_font(node: Control, size: int = -1, color: Color = Color(-1, -1, -1, -1), use_body: bool = false) -> void:
	var f := body_font() if use_body else display_font()
	if f == null or node == null:
		return
	node.add_theme_font_override("font", f)
	if size > 0:
		node.add_theme_font_size_override("font_size", size)
	if color.r >= 0.0:
		node.add_theme_color_override("font_color", color)


func apply_tree(root: Node) -> void:
	var f := display_font()
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
