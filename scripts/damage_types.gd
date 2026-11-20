class_name DamageTypes
extends Object

## 공격 속성 / 적 장갑 상성.
## 경장갑(LIGHT) → 폭발, 중장갑(HEAVY) → 관통, 특수장갑(SPECIAL) → 전격.

enum Type { NONE, EXPLOSION, PIERCE, ELECTRIC }
enum Armor { LIGHT, HEAVY, SPECIAL }

const TYPE_NAMES := {
	Type.NONE: "일반",
	Type.EXPLOSION: "폭발",
	Type.PIERCE: "관통",
	Type.ELECTRIC: "전격",
}

const ARMOR_NAMES := {
	Armor.LIGHT: "경장갑",
	Armor.HEAVY: "중장갑",
	Armor.SPECIAL: "특수장갑",
}

const ARMOR_COLORS := {
	Armor.LIGHT: Color(0.92, 0.28, 0.28),
	Armor.HEAVY: Color(0.92, 0.82, 0.22),
	Armor.SPECIAL: Color(0.28, 0.55, 0.98),
}

const TYPE_COLORS := {
	Type.NONE: Color(0.85, 0.85, 0.9),
	Type.EXPLOSION: Color(1.0, 0.35, 0.15),
	Type.PIERCE: Color(0.95, 0.88, 0.25),
	Type.ELECTRIC: Color(0.35, 0.75, 1.0),
}


static func is_match(dmg_type: int, armor: int) -> bool:
	return (
		(dmg_type == Type.EXPLOSION and armor == Armor.LIGHT)
		or (dmg_type == Type.PIERCE and armor == Armor.HEAVY)
		or (dmg_type == Type.ELECTRIC and armor == Armor.SPECIAL)
	)


static func multiplier(dmg_type: int, armor: int, is_emp: bool = false) -> float:
	if dmg_type == Type.NONE:
		return 1.0
	if is_match(dmg_type, armor):
		return 2.0 if is_emp else 1.75
	return 0.65


static func stage_damage_scale(elapsed: float) -> float:
	# 60초마다 스테이지 +1, 액티브 피해 소폭 상승.
	var stage := int(elapsed / 60.0) + 1
	return 1.0 + float(stage - 1) * 0.12


static func random_armor() -> int:
	return [Armor.LIGHT, Armor.HEAVY, Armor.SPECIAL][randi() % 3]
