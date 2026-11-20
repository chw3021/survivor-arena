extends Node

## 도트/링/머즐 플래시. 파티클 없이 Polygon2D 레이어로 처리.


func burst(at: Vector2, color: Color, count: int = 10, speed: float = 140.0, life: float = 0.35) -> void:
	var parent := _scene()
	if parent == null:
		return
	for i in range(count):
		var glow := _make_poly(color, randf_range(3.0, 5.5), 0.35)
		var core := _make_poly(Color(1, 1, 1, 0.9).lerp(color, 0.35), randf_range(1.4, 2.6), 1.0)
		parent.add_child(glow)
		parent.add_child(core)
		glow.global_position = at
		core.global_position = at
		var dir := Vector2.RIGHT.rotated(randf() * TAU)
		var dist := randf_range(speed * 0.35, speed)
		var life_i := life * randf_range(0.7, 1.15)
		_fly_pair(glow, core, dir * dist, life_i)


func ring(at: Vector2, color: Color, radius: float, life: float = 0.25) -> void:
	var parent := _scene()
	if parent == null:
		return
	var node := Node2D.new()
	parent.add_child(node)
	node.global_position = at
	var fill := Polygon2D.new()
	fill.color = Color(color.r, color.g, color.b, 0.22)
	fill.polygon = _circle_points(radius, 28)
	node.add_child(fill)
	var rim := Polygon2D.new()
	rim.color = Color(color.r, color.g, color.b, 0.7)
	rim.polygon = _ring_band(radius * 0.92, radius, 28)
	node.add_child(rim)
	_fade_scale(node, 1.35, life)


func telegraph_dot(at: Vector2, color: Color, delay: float) -> void:
	var parent := _scene()
	if parent == null:
		return
	var marker := _make_poly(Color(color.r, color.g, color.b, 0.9), 5.0, 1.0)
	parent.add_child(marker)
	marker.global_position = at
	_blink_then_free(marker, delay)


func muzzle_flash(at: Vector2, dir: Vector2, color: Color) -> void:
	var parent := _scene()
	if parent == null:
		return
	var flash := Polygon2D.new()
	flash.color = Color(1, 1, 1, 0.95).lerp(color, 0.4)
	flash.polygon = PackedVector2Array([
		Vector2(-2, -5), Vector2(14, 0), Vector2(-2, 5), Vector2(2, 0)
	])
	parent.add_child(flash)
	flash.global_position = at
	flash.rotation = dir.angle()
	var bloom := _make_poly(Color(color.r, color.g, color.b, 0.45), 7.0, 1.0)
	parent.add_child(bloom)
	bloom.global_position = at
	_fade_out(flash, 0.06)
	_fade_out(bloom, 0.08)


func hit_spark(at: Vector2, color: Color) -> void:
	burst(at, color, 5, 90.0, 0.16)
	ring(at, color, 10.0, 0.1)


func projectile_visual(dtype: int, kind: String = "bullet") -> Node2D:
	var root := Node2D.new()
	var color: Color = DamageTypes.TYPE_COLORS.get(dtype, Color(0.9, 0.9, 0.95))
	var glow := Polygon2D.new()
	glow.z_index = -1
	glow.color = Color(color.r, color.g, color.b, 0.28)
	var mid := Polygon2D.new()
	mid.z_index = -1
	mid.color = Color(color.r, color.g, color.b, 0.55)
	var core := Polygon2D.new()
	core.color = Color(1, 1, 1, 0.96).lerp(color, 0.25)
	match kind:
		"orb":
			glow.polygon = _circle_points(14.0, 14)
			mid.polygon = _circle_points(9.0, 12)
			core.polygon = _circle_points(5.5, 10)
		_:
			# Needle shell: elongated body + bright tip (not a flat arrow).
			match dtype:
				DamageTypes.Type.PIERCE:
					glow.polygon = PackedVector2Array([
						Vector2(-14, -4), Vector2(18, 0), Vector2(-14, 4)
					])
					mid.polygon = PackedVector2Array([
						Vector2(-10, -2.4), Vector2(14, 0), Vector2(-10, 2.4)
					])
					core.polygon = PackedVector2Array([
						Vector2(-4, -1.2), Vector2(16, 0), Vector2(-4, 1.2)
					])
				DamageTypes.Type.EXPLOSION:
					glow.polygon = PackedVector2Array([
						Vector2(-8, -7), Vector2(10, -3), Vector2(12, 0), Vector2(10, 3), Vector2(-8, 7), Vector2(-4, 0)
					])
					mid.polygon = PackedVector2Array([
						Vector2(-5, -4), Vector2(8, -2), Vector2(9, 0), Vector2(8, 2), Vector2(-5, 4)
					])
					core.polygon = _circle_points(3.5, 8)
				DamageTypes.Type.ELECTRIC:
					glow.polygon = PackedVector2Array([
						Vector2(-12, -2), Vector2(-2, -6), Vector2(4, -1), Vector2(16, 0),
						Vector2(4, 1), Vector2(-2, 6), Vector2(-12, 2)
					])
					mid.polygon = PackedVector2Array([
						Vector2(-8, -1.5), Vector2(0, -3.5), Vector2(12, 0), Vector2(0, 3.5), Vector2(-8, 1.5)
					])
					core.polygon = PackedVector2Array([
						Vector2(-3, -0.8), Vector2(11, 0), Vector2(-3, 0.8)
					])
				_:
					glow.polygon = PackedVector2Array([
						Vector2(-11, -5), Vector2(8, -2.5), Vector2(15, 0), Vector2(8, 2.5), Vector2(-11, 5), Vector2(-7, 0)
					])
					mid.polygon = PackedVector2Array([
						Vector2(-7, -2.8), Vector2(10, 0), Vector2(-7, 2.8)
					])
					core.polygon = PackedVector2Array([
						Vector2(-2, -1.3), Vector2(12, 0), Vector2(-2, 1.3)
					])
	root.add_child(glow)
	root.add_child(mid)
	root.add_child(core)
	return root

func trail_dot(at: Vector2, color: Color) -> void:
	var parent := _scene()
	if parent == null:
		return
	var d := _make_poly(Color(color.r, color.g, color.b, 0.55), randf_range(1.5, 2.8), 1.0)
	parent.add_child(d)
	d.global_position = at
	_fade_out(d, 0.12)


func _scene() -> Node:
	return get_tree().current_scene


func _make_poly(color: Color, size: float, _a: float) -> Polygon2D:
	var p := Polygon2D.new()
	p.color = color
	p.polygon = PackedVector2Array([
		Vector2(-size, -size), Vector2(size, -size), Vector2(size, size), Vector2(-size, size)
	])
	return p


func _circle_points(radius: float, segments: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(segments):
		var a := TAU * float(i) / float(segments)
		pts.append(Vector2(cos(a), sin(a)) * radius)
	return pts


func _ring_band(inner_r: float, outer_r: float, segments: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(segments + 1):
		var a := TAU * float(i) / float(segments)
		pts.append(Vector2(cos(a), sin(a)) * outer_r)
	for i in range(segments, -1, -1):
		var a2 := TAU * float(i) / float(segments)
		pts.append(Vector2(cos(a2), sin(a2)) * inner_r)
	return pts


func _fly_pair(glow: Polygon2D, core: Polygon2D, delta_pos: Vector2, life: float) -> void:
	var start := glow.global_position
	var t := 0.0
	while is_instance_valid(glow) and t < life:
		t += get_process_delta_time()
		var u := clampf(t / life, 0.0, 1.0)
		var ease_u := 1.0 - (1.0 - u) * (1.0 - u)
		var pos := start + delta_pos * ease_u
		glow.global_position = pos
		if is_instance_valid(core):
			core.global_position = pos
			core.modulate.a = 1.0 - u
		glow.modulate.a = (1.0 - u) * 0.7
		glow.scale = Vector2.ONE * (1.0 + u * 0.4)
		await get_tree().process_frame
	if is_instance_valid(glow):
		glow.queue_free()
	if is_instance_valid(core):
		core.queue_free()


func _fade_scale(node: Node2D, end_scale: float, life: float) -> void:
	var t := 0.0
	while is_instance_valid(node) and t < life:
		t += get_process_delta_time()
		var u := clampf(t / life, 0.0, 1.0)
		node.scale = Vector2.ONE * lerpf(1.0, end_scale, u)
		node.modulate.a = 1.0 - u
		await get_tree().process_frame
	if is_instance_valid(node):
		node.queue_free()


func _fade_out(node: CanvasItem, life: float) -> void:
	var t := 0.0
	while is_instance_valid(node) and t < life:
		t += get_process_delta_time()
		var u := clampf(t / life, 0.0, 1.0)
		node.modulate.a = 1.0 - u
		await get_tree().process_frame
	if is_instance_valid(node):
		node.queue_free()


func _blink_then_free(marker: Polygon2D, delay: float) -> void:
	var t := 0.0
	while is_instance_valid(marker) and t < delay:
		t += get_process_delta_time()
		marker.visible = int(t * 10.0) % 2 == 0
		marker.scale = Vector2.ONE * (1.0 + sin(t * 18.0) * 0.15)
		await get_tree().process_frame
	if is_instance_valid(marker):
		marker.queue_free()
