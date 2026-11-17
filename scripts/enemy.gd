extends CharacterBody2D

@export var max_hp: float = 30.0
@export var move_speed: float = 95.0
@export var touch_damage: float = 10.0

var hp: float = 30.0
var target: Node2D

@onready var body_visual: Polygon2D = $BodyVisual


func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")
	body_visual.color = Color(0.9, 0.28, 0.32)


func setup(player: Node2D, difficulty: float = 1.0) -> void:
	target = player
	max_hp = 30.0 * difficulty
	hp = max_hp
	move_speed = 95.0 + difficulty * 8.0


func _physics_process(_delta: float) -> void:
	if target == null or not is_instance_valid(target):
		velocity = Vector2.ZERO
		return
	var dir := (target.global_position - global_position).normalized()
	velocity = dir * move_speed
	move_and_slide()


func take_damage(amount: float, from_pos: Vector2 = Vector2.ZERO) -> void:
	hp -= amount
	body_visual.color = Color(1.0, 0.75, 0.75)
	if from_pos != Vector2.ZERO:
		var knock := (global_position - from_pos).normalized() * 40.0
		global_position += knock
	await get_tree().create_timer(0.06).timeout
	if is_instance_valid(body_visual):
		body_visual.color = Color(0.9, 0.28, 0.32)
	if hp <= 0.0:
		Game.add_kill()
		queue_free()
