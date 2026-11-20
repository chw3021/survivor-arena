extends CharacterBody2D

const XP_GEM_SCENE := preload("res://scenes/xp_gem.tscn")

@export var max_hp: float = 30.0
@export var move_speed: float = 95.0
@export var touch_damage: float = 10.0

var hp: float = 30.0
var target: Node2D
var armor: int = DamageTypes.Armor.LIGHT
var stun_left: float = 0.0
var base_color: Color = Color(0.9, 0.28, 0.32)

@onready var body_visual: Polygon2D = $BodyVisual


func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")
	_apply_armor_visual()


func setup(player: Node2D, difficulty: float = 1.0, forced_armor: int = -1) -> void:
	target = player
	armor = forced_armor if forced_armor >= 0 else DamageTypes.random_armor()
	max_hp = 30.0 * difficulty
	match armor:
		DamageTypes.Armor.HEAVY:
			max_hp *= 1.35
			move_speed = 80.0 + difficulty * 6.0
		DamageTypes.Armor.SPECIAL:
			max_hp *= 0.95
			move_speed = 110.0 + difficulty * 9.0
		_:
			move_speed = 95.0 + difficulty * 8.0
	hp = max_hp
	_apply_armor_visual()


func _apply_armor_visual() -> void:
	base_color = DamageTypes.ARMOR_COLORS[armor]
	if body_visual:
		body_visual.color = base_color


func _physics_process(delta: float) -> void:
	if not Game.running:
		velocity = Vector2.ZERO
		return
	stun_left = maxf(0.0, stun_left - delta)
	if stun_left > 0.0:
		velocity = Vector2.ZERO
		return
	if target == null or not is_instance_valid(target):
		velocity = Vector2.ZERO
		return
	var dir := (target.global_position - global_position).normalized()
	velocity = dir * move_speed
	move_and_slide()


func apply_stun(seconds: float) -> void:
	stun_left = maxf(stun_left, seconds)
	if body_visual:
		body_visual.color = Color(0.7, 0.9, 1.0)


func take_damage(
	amount: float,
	from_pos: Vector2 = Vector2.ZERO,
	dmg_type: int = DamageTypes.Type.NONE,
	is_emp: bool = false,
	knock_force: float = 40.0
) -> void:
	var mul := DamageTypes.multiplier(dmg_type, armor, is_emp)
	hp -= amount * mul
	if body_visual:
		body_visual.color = Color(1.0, 0.85, 0.85)
	if from_pos != Vector2.ZERO and knock_force > 0.0:
		var knock := (global_position - from_pos).normalized() * knock_force
		global_position += knock
	Vfx.burst(global_position, DamageTypes.TYPE_COLORS.get(dmg_type, Color.WHITE), 4, 55.0, 0.12)
	await get_tree().create_timer(0.06).timeout
	if is_instance_valid(body_visual):
		body_visual.color = base_color
	if hp <= 0.0:
		Game.add_kill()
		_drop_xp()
		Vfx.burst(global_position, base_color, 10, 100.0, 0.28)
		queue_free()


func _drop_xp() -> void:
	var gem := XP_GEM_SCENE.instantiate() as Node2D
	var parent := get_parent()
	if parent == null:
		return
	parent.add_child(gem)
	gem.global_position = global_position + Vector2(randf_range(-8, 8), randf_range(-8, 8))
	if gem.has_method("setup"):
		gem.setup(target, 1)
