extends Area2D

## 바닥에 떨어진 액티브 아이템. 줍면 기존 액티브를 교체한다.

var active_id: String = "mega_bomb"

@onready var visual: Polygon2D = $Visual


func _ready() -> void:
	collision_layer = 8 # pickup
	collision_mask = 1 # player
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)
	_paint()


func setup(id: String) -> void:
	active_id = id
	_paint()


func _paint() -> void:
	if visual == null:
		return
	var def := ActiveCatalog.get_by_id(active_id)
	var c: Color = DamageTypes.TYPE_COLORS.get(int(def["dmg_type"]), Color.WHITE)
	visual.color = c


func _on_body_entered(body: Node) -> void:
	if body.has_method("equip_active"):
		body.equip_active(active_id)
		Sfx.play("pickup", 1.0, -2.0)
		queue_free()
