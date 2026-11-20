extends Node2D

## 조준 궤적(화살표/원뿔/저격 수축) + 머리 위 원형 장전 타이머.

var player: Node = null


func _ready() -> void:
	z_index = 18
	set_process(true)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if player == null or not is_instance_valid(player):
		return
	if not bool(player.get("alive")):
		return
	if bool(player.get("choosing_passive")):
		return

	_draw_reload_ring()
	_draw_aim_preview()


func _draw_reload_ring() -> void:
	var reload_left: float = float(player.get("reload_left"))
	var reload_total: float = float(player.get("reload_total"))
	if reload_left <= 0.0 or reload_total <= 0.001:
		return
	var ratio: float = 1.0 - clampf(reload_left / reload_total, 0.0, 1.0)
	var center := Vector2(0.0, -58.0)
	var radius := 14.0
	draw_arc(center, radius, 0.0, TAU, 48, Color(0.05, 0.05, 0.08, 0.55), 4.0, true)
	var start := -PI * 0.5
	var end := start + TAU * ratio
	var col := Color(1.0, 0.78, 0.28, 0.95)
	draw_arc(center, radius, start, end, 48, col, 4.0, true)
	# 진행 파이 채우기 (얇은 부채)
	if ratio > 0.001:
		var pts: PackedVector2Array = PackedVector2Array()
		pts.append(center)
		var steps := maxi(2, int(36.0 * ratio))
		for i in range(steps + 1):
			var t := float(i) / float(steps)
			var a := lerpf(start, end, t)
			pts.append(center + Vector2(cos(a), sin(a)) * (radius - 2.0))
		draw_colored_polygon(pts, Color(1.0, 0.72, 0.22, 0.35))


func _draw_aim_preview() -> void:
	if float(player.get("reload_left")) > 0.0:
		return
	var weapon: Dictionary = player.call("_current_weapon")
	if weapon.is_empty():
		return
	var dir: Vector2 = player.call("get_aim_dir")
	if dir == Vector2.ZERO:
		dir = player.get("facing")
	if dir == Vector2.ZERO:
		return
	dir = dir.normalized()

	var reach: float = float(weapon.get("range", 200.0))
	var dtype: int = int(weapon.get("dmg_type", 0))
	var base: Color = DamageTypes.TYPE_COLORS.get(dtype, Color(0.9, 0.9, 0.95))
	var col := Color(base.r, base.g, base.b, 0.55)
	var tip := Color(base.r, base.g, base.b, 0.9)
	var origin := dir * 18.0
	var wid := str(weapon.get("id", ""))
	var kind := str(weapon.get("kind", "projectile"))
	var pellets: int = int(weapon.get("pellets", 1))
	var spread: float = float(weapon.get("spread", 0.0))

	if wid == "sniper":
		var charge: float = float(player.get("sniper_charge"))
		var cone_spread: float = lerpf(0.38, 0.0, clampf(charge, 0.0, 1.0))
		if cone_spread > 0.025:
			_draw_cone(origin, dir, reach, cone_spread, col, tip)
		else:
			_draw_arrow(origin, dir, reach, tip)
		return

	if kind == "cone" or pellets > 1:
		var cone_spread: float = spread
		if pellets > 1:
			cone_spread = spread
		_draw_cone(origin, dir, reach, maxf(cone_spread, 0.12), col, tip)
		return

	# 권총/단발 투사체/빔/EMP: 화살표
	_draw_arrow(origin, dir, reach, tip)


func _draw_arrow(origin: Vector2, dir: Vector2, reach: float, col: Color) -> void:
	var tip := origin + dir * reach
	draw_line(origin, tip, col, 2.0, true)
	var back := -dir
	var left := back.rotated(-0.55) * 14.0
	var right := back.rotated(0.55) * 14.0
	draw_line(tip, tip + left, col, 2.0, true)
	draw_line(tip, tip + right, col, 2.0, true)


func _draw_cone(origin: Vector2, dir: Vector2, reach: float, spread: float, fill: Color, edge: Color) -> void:
	var left_dir := dir.rotated(-spread)
	var right_dir := dir.rotated(spread)
	var left := origin + left_dir * reach
	var right := origin + right_dir * reach
	var pts := PackedVector2Array([origin, left])
	var arc_steps := 10
	for i in range(1, arc_steps):
		var t := float(i) / float(arc_steps)
		var a := lerpf(-spread, spread, t)
		pts.append(origin + dir.rotated(a) * reach)
	pts.append(right)
	var fill_col := Color(fill.r, fill.g, fill.b, 0.18)
	draw_colored_polygon(pts, fill_col)
	draw_line(origin, left, edge, 2.0, true)
	draw_line(origin, right, edge, 2.0, true)
	draw_arc(origin, reach, dir.angle() - spread, dir.angle() + spread, 16, edge, 1.5, true)
