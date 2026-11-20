extends CharacterBody2D

signal stats_changed
signal died
signal leveled_up(level: int)
signal passive_choice_offered(options: Array)

@export var move_speed: float = 220.0
@export var dash_speed: float = 520.0
@export var dash_duration: float = 0.18
@export var dash_cooldown: float = 1.0
@export var max_hp: float = 100.0

var hp: float = 100.0
var weapon_slot: int = 0 # 0=primary, 1=secondary
var attack_cooldown_left: float = 0.0
var dash_left: float = 0.0
var dash_cd_left: float = 0.0
var active_cd_left: float = 0.0
var invincible_left: float = 0.0
var facing: Vector2 = Vector2.RIGHT
var alive: bool = true

var ammo_left: int = 12
var reload_left: float = 0.0
var reload_total: float = 0.0
var sniper_charge: float = 0.0
const SNIPER_CHARGE_TIME := 0.85
var attack_count: int = 0

var xp: int = 0
var level: int = 1
var xp_to_next: int = 5

var active_id: String = "ground_blast"
var passives: Dictionary = {} # id -> rank
var choosing_passive: bool = false
var _pending_passive_picks: int = 0

var awaken_left: float = 0.0
var shield_left: float = 0.0
var attack_speed_mul: float = 1.0
var move_speed_mul: float = 1.0

# 패시브 타이머
var _bomb_support_cd: float = 0.0
var _auto_mine_cd: float = 0.0
var _sniper_support_cd: float = 0.0
var _turret_cd: float = 0.0
var _orbit_cd: float = 0.0
var _drone_cd: float = 0.0
var _tesla_cd: float = 0.0

@onready var body_visual: Polygon2D = $BodyVisual
@onready var hitbox: Area2D = $Hurtbox
@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D

var ammo_label: Label
var aim_overlay: Node2D


func _ready() -> void:
	hp = max_hp
	attack_area.monitoring = false
	attack_shape.disabled = true
	_setup_ammo_label()
	_setup_aim_overlay()
	_reset_ammo()
	_update_visual()
	_refresh_ammo_label()
	stats_changed.emit()


func _setup_aim_overlay() -> void:
	var script: Script = load("res://scripts/aim_overlay.gd")
	aim_overlay = Node2D.new()
	aim_overlay.set_script(script)
	aim_overlay.set("player", self)
	add_child(aim_overlay)


func _setup_ammo_label() -> void:
	ammo_label = Label.new()
	ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ammo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ammo_label.position = Vector2(-48, -52)
	ammo_label.size = Vector2(96, 22)
	ammo_label.z_index = 20
	UiTheme.apply_font(ammo_label, 15, Color(0.95, 0.97, 1.0, 0.95))
	ammo_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.75))
	ammo_label.add_theme_constant_override("outline_size", 4)
	add_child(ammo_label)


func _refresh_ammo_label() -> void:
	if ammo_label == null:
		return
	if reload_left > 0.0:
		# 장전은 머리 위 원형 타이머로 표시
		ammo_label.text = ""
		ammo_label.modulate = Color(1, 1, 1)
	else:
		var w := _current_weapon()
		ammo_label.text = "%d/%d" % [ammo_left, int(w["ammo"])]
		ammo_label.modulate = Color(1, 1, 1) if ammo_left > 2 else Color(1.0, 0.45, 0.4)


func _physics_process(delta: float) -> void:
	if not alive or choosing_passive or not Game.running:
		return

	_tick_timers(delta)
	_tick_passives(delta)
	_handle_movement(delta)
	_handle_actions(delta)
	move_and_slide()
	_resolve_enemy_touch(delta)
	_tick_shield_contact(delta)


func _tick_timers(delta: float) -> void:
	attack_cooldown_left = maxf(0.0, attack_cooldown_left - delta)
	dash_cd_left = maxf(0.0, dash_cd_left - delta)
	active_cd_left = maxf(0.0, active_cd_left - delta)
	invincible_left = maxf(0.0, invincible_left - delta)
	reload_left = maxf(0.0, reload_left - delta)
	awaken_left = maxf(0.0, awaken_left - delta)
	shield_left = maxf(0.0, shield_left - delta)

	if awaken_left <= 0.0:
		attack_speed_mul = 1.0
		move_speed_mul = 1.0

	if dash_left > 0.0:
		dash_left = maxf(0.0, dash_left - delta)
		if dash_left <= 0.0:
			_update_visual()

	if reload_left <= 0.0 and ammo_left <= 0:
		_reset_ammo()

	_refresh_ammo_label()
	stats_changed.emit()


func _handle_movement(_delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_dir != Vector2.ZERO:
		facing = input_dir.normalized()

	if dash_left > 0.0:
		velocity = facing * dash_speed
		return

	velocity = input_dir * move_speed * move_speed_mul


func _handle_actions(delta: float) -> void:
	if Input.is_action_just_pressed("dash"):
		_try_dash()
	if Input.is_action_just_pressed("weapon_next"):
		weapon_slot = 1 - weapon_slot
		sniper_charge = 0.0
		_reset_ammo()
		Sfx.play("weapon_switch", 1.0 + weapon_slot * 0.05)
		stats_changed.emit()
	if Input.is_action_just_pressed("active_item"):
		_try_active()

	var attack_dir := Input.get_vector("attack_left", "attack_right", "attack_up", "attack_down")
	if attack_dir != Vector2.ZERO:
		facing = attack_dir.normalized()
		if reload_left > 0.0 or attack_cooldown_left > 0.0:
			return
		if _is_sniper_equipped():
			sniper_charge = minf(1.0, sniper_charge + delta / SNIPER_CHARGE_TIME)
			if sniper_charge >= 1.0:
				_attack(facing)
				sniper_charge = 0.0
		else:
			sniper_charge = 0.0
			_attack(facing)
	else:
		if _is_sniper_equipped() and sniper_charge > 0.0:
			sniper_charge = maxf(0.0, sniper_charge - delta * 1.6)
		else:
			sniper_charge = 0.0


func _try_dash() -> void:
	if dash_cd_left > 0.0 or dash_left > 0.0:
		return
	dash_left = dash_duration
	dash_cd_left = dash_cooldown
	invincible_left = dash_duration
	Sfx.play("dash", randf_range(0.95, 1.08))
	Vfx.burst(global_position, Color(0.55, 0.95, 1.0), 8, 180.0, 0.25)
	_update_visual()


func equip_active(id: String) -> void:
	active_id = id
	active_cd_left = 0.0
	stats_changed.emit()


func _try_active() -> void:
	if active_cd_left > 0.0:
		return
	var def := ActiveCatalog.get_by_id(active_id)
	active_cd_left = float(def["cooldown"])
	var scale := DamageTypes.stage_damage_scale(Game.elapsed)
	var dmg := float(def["base_damage"]) * scale
	var dtype: int = int(def["dmg_type"])
	match str(def["id"]):
		"mega_bomb":
			_active_mega_bomb(dmg, dtype)
		"mine_breach":
			_active_mine_breach(dmg, dtype)
		"ground_blast":
			_active_ground_blast(dmg, dtype)
		"mystery_gunman":
			_active_mystery_gunman(dmg, dtype)
		"heli_support":
			_active_heli_support(dmg, dtype)
		"precision_shot":
			_active_precision_shot(dmg, dtype)
		"magnet_storm":
			_active_magnet_storm(dmg, dtype)
		"shock_shield":
			shield_left = 4.0
			invincible_left = maxf(invincible_left, 0.35)
			Sfx.play("electric")
			Vfx.ring(global_position, DamageTypes.TYPE_COLORS[DamageTypes.Type.ELECTRIC], 48.0, 0.4)
		"combat_awaken":
			take_damage(max_hp * 0.08, true)
			awaken_left = 6.0
			attack_speed_mul = 1.45
			move_speed_mul = 1.35
			_flash(Color(1.0, 0.85, 0.35))
		"combat_heal":
			hp = minf(max_hp, hp + max_hp * 0.28)
			Vfx.burst(global_position, Color(0.4, 1.0, 0.55), 12, 100.0, 0.4)
			stats_changed.emit()
		_:
			pass


func _active_mega_bomb(dmg: float, dtype: int) -> void:
	var pos := global_position
	Vfx.telegraph_dot(pos, DamageTypes.TYPE_COLORS[dtype], 1.4)
	await get_tree().create_timer(1.4).timeout
	if not is_instance_valid(self):
		return
	_explode_at(pos, 110.0, dmg, dtype, 90.0, false)
	Sfx.play("explosion", 0.85, 2.0)


func _active_mine_breach(dmg: float, dtype: int) -> void:
	var pos := global_position + facing * 140.0
	Vfx.telegraph_dot(pos, DamageTypes.TYPE_COLORS[dtype], 0.35)
	await get_tree().create_timer(0.35).timeout
	_explode_at(pos, 85.0, dmg, dtype, 55.0, false)
	Sfx.play("explosion", 1.1)


func _active_ground_blast(dmg: float, dtype: int) -> void:
	_explode_at(global_position, 130.0, dmg, dtype, 110.0, false)
	Sfx.play("explosion", 1.0)
	Vfx.ring(global_position, DamageTypes.TYPE_COLORS[dtype], 130.0, 0.3)


func _active_mystery_gunman(dmg: float, dtype: int) -> void:
	Sfx.play("gunshot", 0.9)
	var enemies := _enemies_sorted_by_distance()
	var n := mini(8, enemies.size())
	for i in range(n):
		var e: Node2D = enemies[i]
		_deal_to(e, dmg, dtype, false, 20.0)
		Vfx.burst(e.global_position, DamageTypes.TYPE_COLORS[dtype], 4, 80.0, 0.2)
		Sfx.play("gunshot", randf_range(0.95, 1.15), -6.0)
		await get_tree().create_timer(0.08).timeout


func _active_heli_support(dmg: float, dtype: int) -> void:
	var start := global_position + Vector2(-220, -160)
	var end := global_position + Vector2(220, 160)
	var steps := 10
	for i in range(steps):
		var t := float(i) / float(steps - 1)
		var pos := start.lerp(end, t)
		Vfx.telegraph_dot(pos, DamageTypes.TYPE_COLORS[dtype], 0.12)
		_explode_at(pos, 55.0, dmg, dtype, 25.0, false)
		Sfx.play("gunshot", 0.8, -8.0)
		await get_tree().create_timer(0.12).timeout


func _active_precision_shot(dmg: float, dtype: int) -> void:
	var target := _strongest_enemy()
	if target == null:
		return
	Vfx.telegraph_dot(target.global_position, Color(1, 0.2, 0.2), 0.45)
	await get_tree().create_timer(0.45).timeout
	if is_instance_valid(target):
		_deal_to(target, dmg, dtype, false, 10.0)
		Vfx.burst(target.global_position, DamageTypes.TYPE_COLORS[dtype], 14, 160.0, 0.35)
		Sfx.play("gunshot", 0.7, 3.0)


func _active_magnet_storm(dmg: float, dtype: int) -> void:
	var center := global_position + facing * 90.0
	Vfx.ring(center, DamageTypes.TYPE_COLORS[dtype], 100.0, 0.5)
	for body in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(body):
			continue
		var e := body as Node2D
		if e.global_position.distance_to(center) > 120.0:
			continue
		e.global_position = e.global_position.lerp(center, 0.45)
	await get_tree().create_timer(0.25).timeout
	_explode_at(center, 110.0, dmg, dtype, 40.0, false)
	Sfx.play("electric")


func _attack(dir: Vector2) -> void:
	facing = dir
	var weapon: Dictionary = _current_weapon()
	if ammo_left <= 0:
		_start_reload(float(weapon["reload"]))
		return

	ammo_left -= 1
	attack_cooldown_left = float(weapon["cooldown"]) / attack_speed_mul
	attack_count += 1
	_on_attack_fired(weapon)

	var damage := float(weapon["damage"])
	var dtype: int = int(weapon["dmg_type"])
	var reach := float(weapon["range"])

	match str(weapon["kind"]):
		"cone":
			_cone_attack(dir, damage, reach, float(weapon["spread"]), dtype)
		"beam":
			_beam_attack(dir, damage, reach, dtype, float(weapon.get("stun", 0.0)))
		"emp_orb":
			_emp_orb_attack(dir, damage, reach, float(weapon["speed"]), float(weapon.get("aoe", 70.0)), dtype)
		_:
			_projectile_attack(dir, weapon)

	if ammo_left <= 0 or str(weapon.get("id", "")) == "sniper":
		_start_reload(float(weapon["reload"]))


func _is_sniper_equipped() -> bool:
	return str(_current_weapon().get("id", "")) == "sniper"


func get_aim_dir() -> Vector2:
	var attack_dir := Input.get_vector("attack_left", "attack_right", "attack_up", "attack_down")
	if attack_dir != Vector2.ZERO:
		return attack_dir.normalized()
	return facing.normalized() if facing != Vector2.ZERO else Vector2.RIGHT


func _on_attack_fired(weapon: Dictionary) -> void:
	var shot_key := WeaponCatalog.shot_sfx(weapon)
	var pitch := randf_range(0.94, 1.08)
	var vol_db := -2.0
	var gap := 35
	match str(weapon.get("id", "")):
		"flamethrower":
			pitch = randf_range(0.9, 1.15)
			vol_db = -8.0
			gap = 55
		"machine_gun":
			pitch = randf_range(0.92, 1.1)
			vol_db = -6.0
			gap = 28
		"assault_rifle":
			vol_db = -4.0
			gap = 30
		"sniper":
			pitch = randf_range(0.9, 1.02)
			vol_db = 1.0
			gap = 80
		"shotgun":
			pitch = randf_range(0.88, 1.05)
			vol_db = 0.0
			gap = 60
		"taser", "emp_launcher":
			pitch = randf_range(0.95, 1.12)
			vol_db = -3.0
			gap = 40
	Sfx.play(shot_key, pitch, vol_db, gap)

	# 폭발탄약 / EMP충격파
	if passives.has("explosive_rounds"):
		var every := maxi(1, 8 - int(passives["explosive_rounds"]))
		if attack_count % every == 0:
			_explode_at(global_position + facing * 70.0, 55.0, 18.0 + 6.0 * float(passives["explosive_rounds"]), DamageTypes.Type.EXPLOSION, 30.0, false)
			Sfx.play("explosion", 1.2, -6.0)
	if passives.has("emp_shockwave"):
		var every2 := maxi(1, 10 - int(passives["emp_shockwave"]))
		if attack_count % every2 == 0:
			_explode_at(global_position, 90.0, 22.0 + 7.0 * float(passives["emp_shockwave"]), DamageTypes.Type.ELECTRIC, 35.0, true)
			Sfx.play("electric", 0.9)


func _projectile_attack(dir: Vector2, weapon: Dictionary) -> void:
	var pellets: int = int(weapon["pellets"])
	var spread: float = float(weapon["spread"])
	for i in range(pellets):
		var angle := 0.0
		if pellets > 1:
			angle = lerpf(-spread, spread, float(i) / float(pellets - 1))
		elif spread > 0.0:
			angle = randf_range(-spread, spread)
		var shot_dir := dir.rotated(angle)
		_spawn_bullet(shot_dir, weapon)


func _spawn_bullet(dir: Vector2, weapon: Dictionary) -> void:
	var dtype: int = int(weapon["dmg_type"])
	var color: Color = DamageTypes.TYPE_COLORS[dtype]
	Vfx.muzzle_flash(global_position + dir * 22.0, dir, color)

	var bolt := Area2D.new()
	bolt.collision_layer = 0
	bolt.collision_mask = 2
	bolt.monitoring = true
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 7.0
	shape.shape = circle
	bolt.add_child(shape)
	bolt.add_child(Vfx.projectile_visual(dtype, "bullet"))

	get_parent().add_child(bolt)
	bolt.global_position = global_position + dir * 24.0
	bolt.rotation = dir.angle()
	var trail_w := 8.0
	match dtype:
		DamageTypes.Type.PIERCE:
			trail_w = 7.0
		DamageTypes.Type.EXPLOSION:
			trail_w = 12.0
		DamageTypes.Type.ELECTRIC:
			trail_w = 10.0
		_:
			trail_w = 8.0
	Vfx.attach_trail(bolt, color, trail_w, 12)

	var damage := float(weapon["damage"])
	var reach := float(weapon["range"])
	var speed := float(weapon["speed"])
	var pierce_left: int = int(weapon["pierce"])
	var traveled := 0.0
	var hit_ids: Dictionary = {}
	var streak_acc := 0.0

	bolt.body_entered.connect(func(body: Node) -> void:
		if not is_instance_valid(bolt):
			return
		if not body.is_in_group("enemies"):
			return
		var id := body.get_instance_id()
		if hit_ids.has(id):
			return
		hit_ids[id] = true
		_deal_to(body, damage, dtype, false, 28.0)
		Vfx.hit_spark(body.global_position, color)
		if pierce_left <= 0:
			bolt.queue_free()
		else:
			pierce_left -= 1
	)

	while is_instance_valid(bolt) and traveled < reach:
		var step: float = speed / float(Engine.physics_ticks_per_second)
		bolt.global_position += dir * step
		traveled += step
		streak_acc += step
		if streak_acc >= 22.0:
			streak_acc = 0.0
			Vfx.trail_streak(bolt.global_position, dir, color, 16.0)
		await get_tree().physics_frame

	if is_instance_valid(bolt):
		bolt.queue_free()


func _cone_attack(dir: Vector2, damage: float, reach: float, spread: float, dtype: int) -> void:
	var color: Color = DamageTypes.TYPE_COLORS[dtype]
	Vfx.muzzle_flash(global_position + dir * 20.0, dir, color)
	Vfx.burst(global_position + dir * 40.0, color, 12, 110.0, 0.22)
	Vfx.ring(global_position + dir * 50.0, color, 28.0, 0.12)
	for body in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(body):
			continue
		var e := body as Node2D
		var to := e.global_position - global_position
		if to.length() > reach:
			continue
		if absf(dir.angle_to(to.normalized())) > spread:
			continue
		_deal_to(e, damage, dtype, false, 18.0)


func _beam_attack(dir: Vector2, damage: float, reach: float, dtype: int, stun: float) -> void:
	var color: Color = DamageTypes.TYPE_COLORS[dtype]
	Vfx.muzzle_flash(global_position + dir * 18.0, dir, color)
	Vfx.trail_streak(global_position + dir * (reach * 0.55), dir, color, reach * 0.9)
	for i in range(3):
		Vfx.trail_streak(
			global_position + dir * (reach * (0.25 + i * 0.22)) + dir.orthogonal() * randf_range(-6.0, 6.0),
			dir,
			color,
			reach * 0.2
		)
	Vfx.burst(global_position + dir * (reach * 0.5), color, 8, 70.0, 0.18)
	for body in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(body):
			continue
		var e := body as Node2D
		var to := e.global_position - global_position
		if to.length() > reach:
			continue
		if absf(dir.angle_to(to.normalized())) > 0.35:
			continue
		_deal_to(e, damage, dtype, false, 12.0)
		if e.has_method("apply_stun"):
			e.apply_stun(stun)


func _emp_orb_attack(dir: Vector2, damage: float, reach: float, speed: float, aoe: float, dtype: int) -> void:
	var orb := Area2D.new()
	orb.collision_layer = 0
	orb.collision_mask = 2
	orb.monitoring = true
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 10.0
	shape.shape = circle
	orb.add_child(shape)
	orb.add_child(Vfx.projectile_visual(dtype, "orb"))
	get_parent().add_child(orb)
	orb.global_position = global_position + dir * 22.0
	var orb_color: Color = DamageTypes.TYPE_COLORS[dtype]
	Vfx.muzzle_flash(orb.global_position, dir, orb_color)
	Vfx.attach_trail(orb, orb_color, 14.0, 14)

	var traveled := 0.0
	var exploded := false
	var do_explode := func() -> void:
		if exploded or not is_instance_valid(orb):
			return
		exploded = true
		var pos := orb.global_position
		orb.queue_free()
		_explode_at(pos, aoe, damage, dtype, 40.0, true)
		Sfx.play("electric", 0.9, -2.0, 80)

	orb.body_entered.connect(func(body: Node) -> void:
		if body.is_in_group("enemies"):
			do_explode.call()
	)

	while is_instance_valid(orb) and traveled < reach and not exploded:
		var step: float = speed / float(Engine.physics_ticks_per_second)
		orb.global_position += dir * step
		traveled += step
		await get_tree().physics_frame

	if not exploded:
		do_explode.call()


func _tick_passives(delta: float) -> void:
	_bomb_support_cd = maxf(0.0, _bomb_support_cd - delta)
	_auto_mine_cd = maxf(0.0, _auto_mine_cd - delta)
	_sniper_support_cd = maxf(0.0, _sniper_support_cd - delta)
	_turret_cd = maxf(0.0, _turret_cd - delta)
	_orbit_cd = maxf(0.0, _orbit_cd - delta)
	_drone_cd = maxf(0.0, _drone_cd - delta)
	_tesla_cd = maxf(0.0, _tesla_cd - delta)

	if passives.has("bomb_support") and _bomb_support_cd <= 0.0:
		_bomb_support_cd = maxf(2.2, 4.0 - 0.4 * float(passives["bomb_support"]))
		var pos := global_position + facing * 150.0
		var rank: int = int(passives["bomb_support"])
		Vfx.telegraph_dot(pos, DamageTypes.TYPE_COLORS[DamageTypes.Type.EXPLOSION], 0.7)
		_delayed_explode(pos, 60.0, 20.0 + 8.0 * rank, DamageTypes.Type.EXPLOSION, 0.7)

	if passives.has("auto_mine") and _auto_mine_cd <= 0.0:
		_auto_mine_cd = maxf(2.5, 5.0 - 0.45 * float(passives["auto_mine"]))
		var pos2 := global_position
		var rank2: int = int(passives["auto_mine"])
		Vfx.telegraph_dot(pos2, DamageTypes.TYPE_COLORS[DamageTypes.Type.EXPLOSION], 1.0)
		_delayed_explode(pos2, 50.0, 18.0 + 7.0 * rank2, DamageTypes.Type.EXPLOSION, 1.0)

	if passives.has("sniper_support") and _sniper_support_cd <= 0.0:
		_sniper_support_cd = maxf(2.0, 3.8 - 0.35 * float(passives["sniper_support"]))
		var enemies := get_tree().get_nodes_in_group("enemies")
		if not enemies.is_empty():
			var e: Node2D = enemies[randi() % enemies.size()]
			var rank3: int = int(passives["sniper_support"])
			Vfx.telegraph_dot(e.global_position, DamageTypes.TYPE_COLORS[DamageTypes.Type.PIERCE], 0.55)
			_delayed_snipe(e, 22.0 + 9.0 * rank3, 0.55)

	if passives.has("auto_turret") and _turret_cd <= 0.0:
		_turret_cd = maxf(0.35, 0.7 - 0.05 * float(passives["auto_turret"]))
		var nearest := _nearest_enemy(180.0)
		if nearest:
			_deal_to(nearest, 6.0 + 3.0 * float(passives["auto_turret"]), DamageTypes.Type.PIERCE, false, 8.0)
			Vfx.burst(nearest.global_position, DamageTypes.TYPE_COLORS[DamageTypes.Type.PIERCE], 3, 40.0, 0.12)

	if passives.has("orbit_laser") and _orbit_cd <= 0.0:
		_orbit_cd = maxf(3.0, 6.0 - 0.4 * float(passives["orbit_laser"]))
		_fire_orbit_laser(int(passives["orbit_laser"]))

	if passives.has("combat_drone") and _drone_cd <= 0.0:
		_drone_cd = maxf(0.28, 0.55 - 0.04 * float(passives["combat_drone"]))
		var n := _nearest_enemy(160.0)
		if n:
			var dtype: int = [DamageTypes.Type.EXPLOSION, DamageTypes.Type.PIERCE, DamageTypes.Type.ELECTRIC][randi() % 3]
			_deal_to(n, 5.0 + 2.5 * float(passives["combat_drone"]), dtype, false, 10.0)
			Vfx.burst(n.global_position, DamageTypes.TYPE_COLORS[dtype], 3, 50.0, 0.12)

	if passives.has("tesla_coil") and _tesla_cd <= 0.0:
		_tesla_cd = maxf(0.45, 0.9 - 0.07 * float(passives["tesla_coil"]))
		_explode_at(global_position, 75.0 + 8.0 * float(passives["tesla_coil"]), 7.0 + 3.0 * float(passives["tesla_coil"]), DamageTypes.Type.ELECTRIC, 10.0, false)
		Vfx.ring(global_position, DamageTypes.TYPE_COLORS[DamageTypes.Type.ELECTRIC], 70.0, 0.15)


func _fire_orbit_laser(rank: int) -> void:
	var origin := global_position + Vector2(0, -40)
	var dir := facing
	Sfx.play("gunshot", 0.6, -4.0)
	for i in range(8 + rank):
		var pos := origin + dir * float(i) * 36.0
		_explode_at(pos, 28.0, 8.0 + 3.0 * float(rank), DamageTypes.Type.PIERCE, 5.0, false)
		Vfx.burst(pos, DamageTypes.TYPE_COLORS[DamageTypes.Type.PIERCE], 2, 20.0, 0.1)
		await get_tree().create_timer(0.05).timeout


func _delayed_explode(pos: Vector2, radius: float, dmg: float, dtype: int, delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	_explode_at(pos, radius, dmg, dtype, 35.0, false)
	Sfx.play("explosion", 1.05, -4.0)


func _delayed_snipe(enemy: Node2D, dmg: float, delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	if is_instance_valid(enemy):
		_deal_to(enemy, dmg, DamageTypes.Type.PIERCE, false, 15.0)
		Sfx.play("gunshot", 0.75)
		Vfx.burst(enemy.global_position, DamageTypes.TYPE_COLORS[DamageTypes.Type.PIERCE], 6, 70.0, 0.2)


func _explode_at(pos: Vector2, radius: float, dmg: float, dtype: int, knock: float, is_emp: bool) -> void:
	Vfx.burst(pos, DamageTypes.TYPE_COLORS[dtype], 12, radius * 1.2, 0.3)
	Vfx.ring(pos, DamageTypes.TYPE_COLORS[dtype], radius, 0.22)
	for body in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(body):
			continue
		var e := body as Node2D
		if e.global_position.distance_to(pos) > radius:
			continue
		_deal_to(e, dmg, dtype, is_emp, knock)


func _deal_to(body: Node, amount: float, dtype: int, is_emp: bool, knock: float) -> void:
	if body.has_method("take_damage"):
		body.take_damage(amount, global_position, dtype, is_emp, knock)
		Sfx.play("hit", randf_range(0.95, 1.1), -8.0)


func add_xp(amount: int = 1) -> void:
	xp += amount
	while xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		xp_to_next = 4 + level * 2
		leveled_up.emit(level)
		if level % 5 == 0:
			_pending_passive_picks += 1
		hp = minf(max_hp, hp + 8.0)
		stats_changed.emit()
	_offer_passive_choice_if_needed()


func _offer_passive_choice_if_needed() -> void:
	if choosing_passive or _pending_passive_picks <= 0 or not alive:
		return
	var options: Array[String] = PassiveCatalog.roll_choices(passives, 3)
	if options.is_empty():
		_pending_passive_picks = 0
		return
	choosing_passive = true
	Game.running = false
	passive_choice_offered.emit(options)


func apply_passive(id: String) -> void:
	if passives.has(id):
		passives[id] = int(passives[id]) + 1
	else:
		passives[id] = 1
	Sfx.play("pickup", 1.15)
	Vfx.burst(global_position, Color(1.0, 0.9, 0.4), 16, 120.0, 0.4)
	_pending_passive_picks = maxi(0, _pending_passive_picks - 1)
	choosing_passive = false
	stats_changed.emit()
	if _pending_passive_picks > 0:
		_offer_passive_choice_if_needed()
	else:
		Game.running = true


func _start_reload(duration: float) -> void:
	if reload_left > 0.0:
		return
	reload_total = maxf(0.05, duration)
	reload_left = reload_total
	ammo_left = 0
	sniper_charge = 0.0
	var w := _current_weapon()
	var reload_key := WeaponCatalog.reload_sfx(w)
	var pitch := randf_range(0.96, 1.05)
	if reload_key == "reload_heavy":
		pitch = randf_range(0.85, 0.95)
	elif reload_key == "reload_energy":
		pitch = randf_range(0.98, 1.08)
	Sfx.play(reload_key, pitch, 0.0, 120)
	_refresh_ammo_label()


func _reset_ammo() -> void:
	var weapon := _current_weapon()
	ammo_left = int(weapon["ammo"])
	reload_left = 0.0
	reload_total = 0.0
	sniper_charge = 0.0
	_refresh_ammo_label()


func _current_weapon_id() -> String:
	return Loadout.secondary_id if weapon_slot == 1 else Loadout.primary_id


func _current_weapon() -> Dictionary:
	var w := WeaponCatalog.get_by_id(_current_weapon_id())
	if w.is_empty():
		return WeaponCatalog.get_weapon(0)
	return w


func _resolve_enemy_touch(delta: float) -> void:
	if invincible_left > 0.0 or shield_left > 0.0:
		return
	for body in hitbox.get_overlapping_bodies():
		if body.is_in_group("enemies"):
			take_damage(12.0 * delta * 8.0)
			break


func _tick_shield_contact(delta: float) -> void:
	if shield_left <= 0.0:
		return
	invincible_left = maxf(invincible_left, 0.05)
	for body in hitbox.get_overlapping_bodies():
		if body.is_in_group("enemies"):
			_deal_to(body, (8.0 + 4.0) * delta * 6.0, DamageTypes.Type.ELECTRIC, false, 8.0)


func take_damage(amount: float, from_self: bool = false) -> void:
	if not alive:
		return
	if not from_self and (invincible_left > 0.0 or shield_left > 0.0):
		return
	hp = maxf(0.0, hp - amount)
	if not from_self:
		Sfx.play("hurt", randf_range(0.9, 1.05))
		_flash(Color(1.0, 0.35, 0.35))
	stats_changed.emit()
	if hp <= 0.0:
		alive = false
		velocity = Vector2.ZERO
		died.emit()


func get_weapon_name() -> String:
	var w := _current_weapon()
	var tname: String = DamageTypes.TYPE_NAMES[int(w["dmg_type"])]
	var slot_name := "주" if weapon_slot == 0 else "부"
	return "%s/%s(%s)" % [slot_name, str(w["name"]), tname]


func get_active_name() -> String:
	return str(ActiveCatalog.get_by_id(active_id)["name"])


func get_dash_ready_ratio() -> float:
	if dash_cd_left <= 0.0:
		return 1.0
	return 1.0 - (dash_cd_left / dash_cooldown)


func get_active_ready_ratio() -> float:
	if active_cd_left <= 0.0:
		return 1.0
	var cd := float(ActiveCatalog.get_by_id(active_id)["cooldown"])
	return 1.0 - (active_cd_left / cd)


func get_ammo_text() -> String:
	if reload_left > 0.0:
		return "장전중"
	var w := _current_weapon()
	return "%d/%d" % [ammo_left, int(w["ammo"])]


func get_passive_summary() -> String:
	if passives.is_empty():
		return "없음"
	var parts: PackedStringArray = []
	for id in passives.keys():
		var def := PassiveCatalog.get_by_id(str(id))
		parts.append("%s Lv%d" % [str(def["name"]), int(passives[id])])
	return ", ".join(parts)


func _enemies_sorted_by_distance() -> Array:
	var arr: Array = []
	for body in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(body):
			arr.append(body)
	arr.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return a.global_position.distance_squared_to(global_position) < b.global_position.distance_squared_to(global_position)
	)
	return arr


func _nearest_enemy(max_dist: float) -> Node2D:
	var best: Node2D = null
	var best_d := max_dist * max_dist
	for body in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(body):
			continue
		var e := body as Node2D
		var d := e.global_position.distance_squared_to(global_position)
		if d < best_d:
			best_d = d
			best = e
	return best


func _strongest_enemy() -> Node2D:
	var best: Node2D = null
	var best_hp := -1.0
	for body in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(body):
			continue
		if "hp" in body and float(body.hp) > best_hp:
			best_hp = float(body.hp)
			best = body as Node2D
	return best


func _update_visual() -> void:
	if shield_left > 0.0:
		body_visual.color = Color(0.45, 0.85, 1.0)
	elif invincible_left > 0.0 or dash_left > 0.0:
		body_visual.color = Color(0.55, 0.95, 1.0)
	elif awaken_left > 0.0:
		body_visual.color = Color(1.0, 0.75, 0.25)
	else:
		body_visual.color = Color(0.25, 0.72, 0.95)


func _flash(color: Color) -> void:
	body_visual.color = color
	await get_tree().create_timer(0.08).timeout
	if is_instance_valid(self):
		_update_visual()
