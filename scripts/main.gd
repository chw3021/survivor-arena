extends Node2D

const GRID_CELL := 80.0
const FLOOR_MARGIN := 160.0

@onready var player: CharacterBody2D = $Player
@onready var spawner: Node2D = $EnemySpawner
@onready var hud: CanvasLayer = $HUD
@onready var camera: Camera2D = $Player/Camera2D
@onready var floor_poly: Polygon2D = $Arena/Floor
@onready var grid_hint: Polygon2D = $Arena/GridHint


func _ready() -> void:
	Game.reset()
	Sfx.ensure_web_unlocked()
	Sfx.play_bgm(Sfx.BGM_ARENA, true)
	spawner.setup(player)
	hud.setup(player)
	camera.make_current()
	_keep_floor_under_player()


func _process(_delta: float) -> void:
	_keep_floor_under_player()


func _keep_floor_under_player() -> void:
	# Infinite arena: floor always covers the camera, no hard map edge.
	if player == null or not is_instance_valid(player):
		return
	var half := _cover_half()
	var p := player.global_position
	floor_poly.polygon = PackedVector2Array([
		p + Vector2(-half.x, -half.y),
		p + Vector2(half.x, -half.y),
		p + Vector2(half.x, half.y),
		p + Vector2(-half.x, half.y),
	])
	var snap := Vector2(floorf(p.x / GRID_CELL) * GRID_CELL, floorf(p.y / GRID_CELL) * GRID_CELL)
	grid_hint.polygon = PackedVector2Array([
		snap + Vector2(-40, -40),
		snap + Vector2(40, -40),
		snap + Vector2(40, 40),
		snap + Vector2(-40, 40),
	])


func _cover_half() -> Vector2:
	var vp := get_viewport().get_visible_rect().size
	var zoom := camera.zoom if camera != null else Vector2.ONE
	return Vector2(vp.x / zoom.x, vp.y / zoom.y) * 0.5 + Vector2(FLOOR_MARGIN, FLOOR_MARGIN)
