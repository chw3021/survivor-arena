extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_interval: float = 1.1
@export var max_enemies: int = 60
@export var spawn_radius_min: float = 420.0
@export var spawn_radius_max: float = 620.0

var _timer: float = 0.0
var player: Node2D


func setup(p: Node2D) -> void:
	player = p


func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	if not ("alive" in player) or not player.alive:
		return

	_timer -= delta
	if _timer > 0.0:
		return
	_timer = maxf(0.35, spawn_interval - Game.elapsed * 0.01)

	var live := get_tree().get_nodes_in_group("enemies").size()
	if live >= max_enemies:
		return

	_spawn_one()


func _spawn_one() -> void:
	if enemy_scene == null:
		return
	var enemy := enemy_scene.instantiate() as Node2D
	var angle := randf() * TAU
	var dist := randf_range(spawn_radius_min, spawn_radius_max)
	enemy.global_position = player.global_position + Vector2.RIGHT.rotated(angle) * dist
	get_parent().add_child(enemy)
	if enemy.has_method("setup"):
		enemy.setup(player, 1.0 + Game.elapsed / 45.0)
