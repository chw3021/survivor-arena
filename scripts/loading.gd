extends Control

@onready var bar: ProgressBar = $Center/VBox/Bar
@onready var tip: Label = $Center/VBox/Tip

var _t: float = 0.0
var _done: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_font()
	bar.value = 0.0
	tip.text = "아레나 준비 중..."
	Sfx.ensure_web_unlocked()


func _apply_font() -> void:
	UiTheme.apply_font($Center/VBox/Title, 42)
	UiTheme.apply_font(tip, 16)


func _process(delta: float) -> void:
	if _done:
		return
	_t += delta
	bar.value = minf(100.0, (_t / 1.35) * 100.0)
	if _t < 0.45:
		tip.text = "시스템 초기화..."
	elif _t < 0.9:
		tip.text = "무기 데이터 로드..."
	else:
		tip.text = "전장 진입 준비..."
	if bar.value >= 100.0:
		_done = true
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
