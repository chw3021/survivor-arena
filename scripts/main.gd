extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var spawner: Node2D = $EnemySpawner
@onready var hud: CanvasLayer = $HUD
@onready var camera: Camera2D = $Player/Camera2D


func _ready() -> void:
	Game.reset()
	spawner.setup(player)
	hud.setup(player)
	camera.make_current()
