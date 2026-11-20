extends Node

## 가벼운 도트/원형 VFX. 파티클 엔진 없이 Polygon2D로 처리.


func burst(at: Vector2, color: Color, count: int = 10, speed: float = 140.0, life: float = 0.35) -> void:
	var parent := get_tree().current_scene
	if parent == null:
		return
	for i in range(count):
		var dot := Polygon2D.new()
		dot.color = color
		var s := randf_range(2.0, 4.5)
		dot.polygon = PackedVector2Array([
			Vector2(-s, -s), Vector2(s, -s), Vector2(s, s), Vector2(-s, s)
		])
		parent.add_child(dot)
		dot.global_position = at
		var dir := Vector2.RIGHT.rotated(randf() * TAU)
		var dist := randf_range(speed * 0.4, speed)
		_fly_dot(dot, dir * dist, life * randf_range(0.7, 1.2))


func ring(at: Vector2, color: Color, radius: float, life: float = 0.25) -> void:
	var parent := get_tree().current_scene
	if parent == null:
		return
	var ring_node := Node2D.new()
	parent.add_child(ring_node)
	ring_node.global_position = at
	var poly := Polygon2D.new()
	poly.color = Color(color.r, color.g, color.b, 0.55)
	poly.polygon = _circle_points(radius, 24)
	ring_node.add_child(poly)
	_fade_ring(ring_node, poly, radius * 1.35, life)


func telegraph_dot(at: Vector2, color: Color, delay: float) -> void:
	var parent := get_tree().current_scene
	if parent == null:
		return
	var marker := Polygon2D.new()
	marker.color = Color(color.r, color.g, color.b, 0.85)
	marker.polygon = PackedVector2Array([
		Vector2(-5, -5), Vector2(5, -5), Vector2(5, 5), Vector2(-5, 5)
	])
	parent.add_child(marker)
	marker.global_position = at
	_blink_then_free(marker, delay)


func _circle_points(radius: float, segments: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(segments):
		var a := TAU * float(i) / float(segments)
		pts.append(Vector2(cos(a), sin(a)) * radius)
	return pts


func _fly_dot(dot: Polygon2D, delta_pos: Vector2, life: float) -> void:
	var start := dot.global_position
	var t := 0.0
	while is_instance_valid(dot) and t < life:
		t += get_process_delta_time()
		var u := clampf(t / life, 0.0, 1.0)
		dot.global_position = start + delta_pos * u
		dot.modulate.a = 1.0 - u
		await get_tree().process_frame
	if is_instance_valid(dot):
		dot.queue_free()


func _fade_ring(node: Node2D, poly: Polygon2D, end_r: float, life: float) -> void:
	var start_pts := poly.polygon
	var t := 0.0
	while is_instance_valid(node) and t < life:
		t += get_process_delta_time()
		var u := clampf(t / life, 0.0, 1.0)
		var scale := 1.0 + (end_r / maxf(1.0, _approx_radius(start_pts)) - 1.0) * u
		node.scale = Vector2(scale, scale)
		poly.modulate.a = 1.0 - u
		await get_tree().process_frame
	if is_instance_valid(node):
		node.queue_free()


func _approx_radius(pts: PackedVector2Array) -> float:
	if pts.is_empty():
		return 1.0
	return pts[0].length()


func _blink_then_free(marker: Polygon2D, delay: float) -> void:
	var t := 0.0
	while is_instance_valid(marker) and t < delay:
		t += get_process_delta_time()
		marker.visible = int(t * 8.0) % 2 == 0
		await get_tree().process_frame
	if is_instance_valid(marker):
		marker.queue_free()
