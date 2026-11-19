extends Node2D

## Vampire Survivors-style timed waves: old enemies stay, next wave stacks on top.
## Spawns just outside the camera view around the player.

@export var enemy_scene: PackedScene
@export var max_enemies: int = 80
@export var wave_duration: float = 25.0
@export var spawn_margin: float = 48.0
@export var base_spawn_interval: float = 1.25
@export var min_spawn_interval: float = 0.28

var player: Node2D
var _spawn_timer: float = 0.0
var _wave_timer: float = 0.0
var _wave: int = 1


func setup(p: Node2D) -> void:
	player = p
	_wave = 1
	_wave_timer = wave_duration
	_spawn_timer = 0.35
	Game.set_wave(_wave)


func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	if not ("alive" in player) or not player.alive:
		return

	_wave_timer -= delta
	if _wave_timer <= 0.0:
		_advance_wave()

	_spawn_timer -= delta
	if _spawn_timer > 0.0:
		return

	_spawn_timer = _current_interval()
	_spawn_batch(_batch_size())


func _advance_wave() -> void:
	_wave += 1
	_wave_timer = wave_duration
	Game.set_wave(_wave)
	# Wave open burst — leftover mobs from previous waves keep chasing.
	_spawn_batch(_batch_size() + 2)
	_spawn_timer = _current_interval() * 0.55


func _current_interval() -> float:
	# VS-like: starts ~1.25s, tightens with wave and run time.
	var by_wave := base_spawn_interval - float(_wave - 1) * 0.08
	var by_time := Game.elapsed * 0.012
	return maxf(min_spawn_interval, by_wave - by_time)


func _batch_size() -> int:
	# Early: 1–2. Later waves drip more per tick.
	return mini(6, 1 + (_wave - 1) / 2 + (1 if _wave >= 3 else 0))


func _spawn_batch(count: int) -> void:
	var live := get_tree().get_nodes_in_group("enemies").size()
	var room := max_enemies - live
	if room <= 0:
		return
	for _i in mini(count, room):
		_spawn_one()


func _spawn_one() -> void:
	if enemy_scene == null:
		return
	var enemy := enemy_scene.instantiate() as Node2D
	enemy.global_position = _spawn_pos_outside_view()
	get_parent().add_child(enemy)
	if enemy.has_method("setup"):
		# Difficulty scales with wave + run time; leftover waves keep their stats.
		var difficulty := 1.0 + float(_wave - 1) * 0.18 + Game.elapsed / 50.0
		enemy.setup(player, difficulty)


func _spawn_pos_outside_view() -> Vector2:
	var half := _view_half_extents()
	var outer := half + Vector2(spawn_margin, spawn_margin)
	var side := randi() % 4
	var local := Vector2.ZERO
	match side:
		0:
			local = Vector2(randf_range(-outer.x, outer.x), -outer.y)
		1:
			local = Vector2(randf_range(-outer.x, outer.x), outer.y)
		2:
			local = Vector2(-outer.x, randf_range(-outer.y, outer.y))
		_:
			local = Vector2(outer.x, randf_range(-outer.y, outer.y))
	return player.global_position + local


func _view_half_extents() -> Vector2:
	var vp_size := get_viewport().get_visible_rect().size
	var cam := get_viewport().get_camera_2d()
	var zoom := cam.zoom if cam != null else Vector2.ONE
	# Visible half-size in world units (player-centered FOV).
	return Vector2(vp_size.x / zoom.x, vp_size.y / zoom.y) * 0.5
