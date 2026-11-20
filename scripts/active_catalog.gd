class_name ActiveCatalog
extends Object

## 액티브 아이템(스킬). 한 번에 하나만 보유. E로 사용.

const ACTIVES := [
	{
		"id": "mega_bomb",
		"name": "대형폭탄설치",
		"cooldown": 18.0,
		"dmg_type": DamageTypes.Type.EXPLOSION,
		"tags": ["폭발", "보스특화", "쿨타임김"],
		"base_damage": 120.0,
		"desc": "발밑에 지연 폭발 폭탄 설치",
	},
	{
		"id": "mine_breach",
		"name": "지뢰개척",
		"cooldown": 8.0,
		"dmg_type": DamageTypes.Type.EXPLOSION,
		"tags": ["폭발", "잡몹특화"],
		"base_damage": 45.0,
		"desc": "전방 폭발물 투척",
	},
	{
		"id": "ground_blast",
		"name": "지면폭파",
		"cooldown": 10.0,
		"dmg_type": DamageTypes.Type.PIERCE,
		"tags": ["관통", "잡몹특화", "생존용"],
		"base_damage": 35.0,
		"desc": "원형 폭발 + 넉백",
	},
	{
		"id": "mystery_gunman",
		"name": "의문의사내",
		"cooldown": 14.0,
		"dmg_type": DamageTypes.Type.PIERCE,
		"tags": ["관통", "잡몹특화"],
		"base_damage": 28.0,
		"desc": "주변 적 다수 사격 후 퇴장",
	},
	{
		"id": "heli_support",
		"name": "헬기지원사격",
		"cooldown": 16.0,
		"dmg_type": DamageTypes.Type.PIERCE,
		"tags": ["관통", "잡몹특화"],
		"base_damage": 12.0,
		"desc": "헬기가 범위를 가로지르며 사격",
	},
	{
		"id": "precision_shot",
		"name": "정밀사격",
		"cooldown": 12.0,
		"dmg_type": DamageTypes.Type.PIERCE,
		"tags": ["관통", "보스특화"],
		"base_damage": 95.0,
		"desc": "화면 내 최강 적 저격",
	},
	{
		"id": "magnet_storm",
		"name": "자기장 폭풍",
		"cooldown": 13.0,
		"dmg_type": DamageTypes.Type.ELECTRIC,
		"tags": ["전격", "잡몹특화"],
		"base_damage": 55.0,
		"desc": "전방 흡인 후 전격",
	},
	{
		"id": "shock_shield",
		"name": "전격 보호막",
		"cooldown": 15.0,
		"dmg_type": DamageTypes.Type.ELECTRIC,
		"tags": ["전격", "생존용"],
		"base_damage": 8.0,
		"desc": "전기 보호막 + 접촉 전격",
	},
	{
		"id": "combat_awaken",
		"name": "전투 각성",
		"cooldown": 20.0,
		"dmg_type": DamageTypes.Type.NONE,
		"tags": ["버프"],
		"base_damage": 0.0,
		"desc": "체력 소모 후 공속/이속 증가",
	},
	{
		"id": "combat_heal",
		"name": "전투 치료",
		"cooldown": 16.0,
		"dmg_type": DamageTypes.Type.NONE,
		"tags": ["회복"],
		"base_damage": 0.0,
		"desc": "즉시 체력 회복",
	},
]


static func get_by_id(id: String) -> Dictionary:
	for a in ACTIVES:
		if a["id"] == id:
			return a
	return ACTIVES[0]


static func random_id() -> String:
	return str(ACTIVES[randi() % ACTIVES.size()]["id"])
