extends Area2D

## 적 사망 시 드랍되는 경험치 젬. 가까이 가면 흡인, 접촉 시 획득.

@export var amount: int = 1
@export var attract_radius: float = 110.0
@export var collect_radius: float = 26.0
@export var attract_speed: float = 320.0

var _player: Node2D
var _pulse: float = 0.0

@onready var visual: Polygon2D = $Visual


func _ready() -> void:
	collision_layer = 8
	collision_mask = 1
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)
	add_to_group("xp_gems")
	if visual:
		visual.color = Color(0.35, 0.95, 0.7, 0.95)


func setup(player: Node2D, xp_amount: int = 1) -> void:
	_player = player
	amount = maxi(1, xp_amount)


func _process(delta: float) -> void:
	if not Game.running:
		return
	_pulse += delta * 6.0
	if visual:
		var s := 1.0 + sin(_pulse) * 0.08
		visual.scale = Vector2(s, s)
	if _player == null or not is_instance_valid(_player):
		return
	var dist := global_position.distance_to(_player.global_position)
	if dist <= collect_radius:
		_collect()
		return
	if dist <= attract_radius:
		var dir := (_player.global_position - global_position).normalized()
		global_position += dir * attract_speed * delta * (1.2 - dist / attract_radius)


func _on_body_entered(body: Node) -> void:
	if body.has_method("add_xp"):
		_player = body as Node2D
		_collect()


func _collect() -> void:
	if _player != null and is_instance_valid(_player) and _player.has_method("add_xp"):
		_player.add_xp(amount)
		Sfx.play("pickup", randf_range(1.05, 1.2), -8.0)
		Vfx.burst(global_position, Color(0.4, 1.0, 0.75), 6, 70.0, 0.2)
	queue_free()
