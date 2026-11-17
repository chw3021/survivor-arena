extends CharacterBody2D

signal stats_changed
signal died

const WEAPONS := [
	{"id": "slash", "name": "Slash", "damage": 18.0, "cooldown": 0.28, "range": 56.0, "kind": "melee"},
	{"id": "bolt", "name": "Bolt", "damage": 12.0, "cooldown": 0.22, "range": 260.0, "kind": "ranged"},
]

@export var move_speed: float = 220.0
@export var dash_speed: float = 520.0
@export var dash_duration: float = 0.18
@export var dash_cooldown: float = 1.0
@export var max_hp: float = 100.0
@export var active_cooldown: float = 6.0

var hp: float = 100.0
var weapon_index: int = 0
var attack_cooldown_left: float = 0.0
var dash_left: float = 0.0
var dash_cd_left: float = 0.0
var active_cd_left: float = 0.0
var invincible_left: float = 0.0
var facing: Vector2 = Vector2.RIGHT
var alive: bool = true

@onready var body_visual: Polygon2D = $BodyVisual
@onready var hitbox: Area2D = $Hurtbox
@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D


func _ready() -> void:
	hp = max_hp
	attack_area.monitoring = false
	attack_shape.disabled = true
	_update_visual()
	stats_changed.emit()


func _physics_process(delta: float) -> void:
	if not alive:
		return

	_tick_timers(delta)
	_handle_movement(delta)
	_handle_actions()
	move_and_slide()
	_resolve_enemy_touch(delta)


func _tick_timers(delta: float) -> void:
	attack_cooldown_left = maxf(0.0, attack_cooldown_left - delta)
	dash_cd_left = maxf(0.0, dash_cd_left - delta)
	active_cd_left = maxf(0.0, active_cd_left - delta)
	invincible_left = maxf(0.0, invincible_left - delta)

	if dash_left > 0.0:
		dash_left = maxf(0.0, dash_left - delta)
		if dash_left <= 0.0:
			_update_visual()

	stats_changed.emit()


func _handle_movement(_delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_dir != Vector2.ZERO:
		facing = input_dir.normalized()

	if dash_left > 0.0:
		velocity = facing * dash_speed
		return

	velocity = input_dir * move_speed


func _handle_actions() -> void:
	if Input.is_action_just_pressed("dash"):
		_try_dash()
	if Input.is_action_just_pressed("weapon_next"):
		weapon_index = (weapon_index + 1) % WEAPONS.size()
		stats_changed.emit()
	if Input.is_action_just_pressed("active_item"):
		_try_active()

	var attack_dir := Input.get_vector("attack_left", "attack_right", "attack_up", "attack_down")
	if attack_dir != Vector2.ZERO and attack_cooldown_left <= 0.0:
		_attack(attack_dir.normalized())


func _try_dash() -> void:
	if dash_cd_left > 0.0 or dash_left > 0.0:
		return
	dash_left = dash_duration
	dash_cd_left = dash_cooldown
	invincible_left = dash_duration
	_update_visual()


func _try_active() -> void:
	if active_cd_left > 0.0:
		return
	active_cd_left = active_cooldown
	# Placeholder active: knockback burst + light damage around player.
	for body in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(body):
			continue
		var enemy := body as Node2D
		if enemy.global_position.distance_to(global_position) > 120.0:
			continue
		if enemy.has_method("take_damage"):
			enemy.take_damage(25.0, global_position)
	_flash(Color(0.4, 1.0, 0.7))


func _attack(dir: Vector2) -> void:
	facing = dir
	var weapon: Dictionary = WEAPONS[weapon_index]
	attack_cooldown_left = float(weapon["cooldown"])

	if weapon["kind"] == "melee":
		_melee_attack(dir, float(weapon["damage"]), float(weapon["range"]))
	else:
		_ranged_attack(dir, float(weapon["damage"]), float(weapon["range"]))


func _melee_attack(dir: Vector2, damage: float, reach: float) -> void:
	attack_area.rotation = dir.angle()
	attack_shape.position = Vector2(reach * 0.55, 0.0)
	attack_shape.disabled = false
	attack_area.monitoring = true
	await get_tree().physics_frame
	await get_tree().physics_frame

	for body in attack_area.get_overlapping_bodies():
		if body.is_in_group("enemies") and body.has_method("take_damage"):
			body.take_damage(damage, global_position)

	await get_tree().create_timer(0.08).timeout
	if is_instance_valid(attack_area):
		attack_area.monitoring = false
		attack_shape.disabled = true


func _ranged_attack(dir: Vector2, damage: float, reach: float) -> void:
	var bolt := Area2D.new()
	bolt.collision_layer = 0
	bolt.collision_mask = 2 # enemy
	bolt.monitoring = true
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 8.0
	shape.shape = circle
	bolt.add_child(shape)

	var visual := Polygon2D.new()
	visual.color = Color(0.95, 0.85, 0.25)
	visual.polygon = PackedVector2Array([
		Vector2(-6, -4), Vector2(10, 0), Vector2(-6, 4)
	])
	bolt.add_child(visual)

	get_parent().add_child(bolt)
	bolt.global_position = global_position + dir * 20.0
	bolt.rotation = dir.angle()

	var traveled := 0.0
	var speed := 480.0
	var hit := false

	bolt.body_entered.connect(func(body: Node) -> void:
		if hit:
			return
		if body.is_in_group("enemies") and body.has_method("take_damage"):
			hit = true
			body.take_damage(damage, global_position)
			bolt.queue_free()
	)

	while is_instance_valid(bolt) and traveled < reach and not hit:
		var step: float = speed / float(Engine.physics_ticks_per_second)
		bolt.global_position += dir * step
		traveled += step
		await get_tree().physics_frame

	if is_instance_valid(bolt):
		bolt.queue_free()


func _resolve_enemy_touch(delta: float) -> void:
	if invincible_left > 0.0:
		return
	for body in hitbox.get_overlapping_bodies():
		if body.is_in_group("enemies"):
			take_damage(12.0 * delta * 8.0) # ~contact DPS placeholder
			break


func take_damage(amount: float) -> void:
	if not alive or invincible_left > 0.0:
		return
	hp = maxf(0.0, hp - amount)
	_flash(Color(1.0, 0.35, 0.35))
	stats_changed.emit()
	if hp <= 0.0:
		alive = false
		velocity = Vector2.ZERO
		died.emit()


func get_weapon_name() -> String:
	return str(WEAPONS[weapon_index]["name"])


func get_dash_ready_ratio() -> float:
	if dash_cd_left <= 0.0:
		return 1.0
	return 1.0 - (dash_cd_left / dash_cooldown)


func get_active_ready_ratio() -> float:
	if active_cd_left <= 0.0:
		return 1.0
	return 1.0 - (active_cd_left / active_cooldown)


func _update_visual() -> void:
	if invincible_left > 0.0 or dash_left > 0.0:
		body_visual.color = Color(0.55, 0.95, 1.0)
	else:
		body_visual.color = Color(0.25, 0.72, 0.95)


func _flash(color: Color) -> void:
	body_visual.color = color
	await get_tree().create_timer(0.08).timeout
	if is_instance_valid(self):
		_update_visual()
