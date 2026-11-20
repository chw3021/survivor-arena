class_name PassiveCatalog
extends Object

## 패시브. 5레벨 단위로 강화 특성 획득.

const PASSIVES := [
	{"id": "bomb_support", "name": "폭격 지원", "dmg_type": DamageTypes.Type.EXPLOSION, "desc": "시선 지점 지연 폭격"},
	{"id": "auto_mine", "name": "자동 지뢰", "dmg_type": DamageTypes.Type.EXPLOSION, "desc": "발밑 자동 지뢰"},
	{"id": "explosive_rounds", "name": "폭발탄약 보급", "dmg_type": DamageTypes.Type.EXPLOSION, "desc": "N회 공격마다 폭발탄"},
	{"id": "sniper_support", "name": "저격 지원", "dmg_type": DamageTypes.Type.PIERCE, "desc": "랜덤 적 지연 레이저"},
	{"id": "auto_turret", "name": "자동포탑", "dmg_type": DamageTypes.Type.PIERCE, "desc": "주변 포탑 자동공격"},
	{"id": "orbit_laser", "name": "궤도 레이저", "dmg_type": DamageTypes.Type.PIERCE, "desc": "하늘에서 직선 레이저"},
	{"id": "combat_drone", "name": "전투드론", "dmg_type": DamageTypes.Type.NONE, "desc": "따라다니며 자동공격"},
	{"id": "tesla_coil", "name": "테슬라코일", "dmg_type": DamageTypes.Type.ELECTRIC, "desc": "주변 주기 전격"},
	{"id": "emp_shockwave", "name": "EMP충격파", "dmg_type": DamageTypes.Type.ELECTRIC, "desc": "N회 공격마다 EMP", "is_emp": true},
]


static func get_by_id(id: String) -> Dictionary:
	for p in PASSIVES:
		if p["id"] == id:
			return p
	return PASSIVES[0]


static func random_id_excluding(owned: Dictionary) -> String:
	var pool: Array = []
	for p in PASSIVES:
		if not owned.has(p["id"]):
			pool.append(p["id"])
	if pool.is_empty():
		# 전부 보유 시 랜덤 강화.
		return str(PASSIVES[randi() % PASSIVES.size()]["id"])
	return str(pool[randi() % pool.size()])


## 카드 선택용 후보. 미보유 우선, 부족하면 보유 패시브 강화로 채움.
static func roll_choices(owned: Dictionary, count: int = 3) -> Array[String]:
	var fresh: Array[String] = []
	var owned_ids: Array[String] = []
	for p in PASSIVES:
		var id := str(p["id"])
		if owned.has(id):
			owned_ids.append(id)
		else:
			fresh.append(id)
	fresh.shuffle()
	owned_ids.shuffle()

	var picks: Array[String] = []
	for id in fresh:
		if picks.size() >= count:
			break
		picks.append(id)
	for id in owned_ids:
		if picks.size() >= count:
			break
		if not picks.has(id):
			picks.append(id)
	# 그래도 부족하면 전체에서 중복 없이 채움.
	var all_ids: Array[String] = []
	for p in PASSIVES:
		all_ids.append(str(p["id"]))
	all_ids.shuffle()
	for id in all_ids:
		if picks.size() >= count:
			break
		if not picks.has(id):
			picks.append(id)
	return picks
