extends CanvasLayer

@onready var hp_bar: ProgressBar = $Root/VBox/HpBar
@onready var info_label: Label = $Root/VBox/InfoLabel
@onready var help_label: Label = $Root/HelpLabel
@onready var overlay: ColorRect = $Root/Overlay
@onready var overlay_label: Label = $Root/Overlay/OverlayLabel

var player: Node


func setup(p: Node) -> void:
	player = p
	if player.has_signal("stats_changed"):
		player.stats_changed.connect(_refresh)
	if player.has_signal("died"):
		player.died.connect(_on_player_died)
	Game.kills_changed.connect(_refresh)
	Game.time_changed.connect(_refresh)
	_refresh()


func _ready() -> void:
	help_label.text = "WASD Move | Arrows Attack | Space Dash(i-frames) | Q Weapon | E Active"
	overlay.visible = false


func _refresh(_arg: Variant = null) -> void:
	if player == null or not is_instance_valid(player):
		return
	hp_bar.max_value = player.max_hp
	hp_bar.value = player.hp
	var t := int(Game.elapsed)
	var mm := t / 60
	var ss := t % 60
	info_label.text = "HP %d/%d | Weapon: %s | Dash %.0f%% | Active %.0f%% | Kills %d | %02d:%02d" % [
		int(player.hp),
		int(player.max_hp),
		player.get_weapon_name(),
		player.get_dash_ready_ratio() * 100.0,
		player.get_active_ready_ratio() * 100.0,
		Game.kills,
		mm,
		ss,
	]


func _on_player_died() -> void:
	Game.running = false
	overlay.visible = true
	overlay_label.text = "You Died\nKills: %d\nPress R to restart" % Game.kills


func _unhandled_input(event: InputEvent) -> void:
	if overlay.visible and event is InputEventKey and event.pressed and event.keycode == KEY_R:
		get_tree().reload_current_scene()
		Game.reset()
