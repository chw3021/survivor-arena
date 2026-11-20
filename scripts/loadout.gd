extends Node

## 장비/난이도/설정 영속. 메뉴 ↔ 인게임 공유.

signal loadout_changed
signal settings_changed

const SAVE_PATH := "user://survivor_settings.cfg"

var primary_id: String = "pistol"
var secondary_id: String = "shotgun"
var difficulty: String = "normal" # easy | normal | hard

const DIFFICULTY_MULT := {
	"easy": 0.75,
	"normal": 1.0,
	"hard": 1.45,
}

const DIFFICULTY_NAMES := {
	"easy": "쉬움",
	"normal": "보통",
	"hard": "어려움",
}


func _ready() -> void:
	load_settings()


func difficulty_mult() -> float:
	return float(DIFFICULTY_MULT.get(difficulty, 1.0))


func set_primary(id: String) -> void:
	if WeaponCatalog.get_by_id(id).is_empty():
		return
	if id == secondary_id:
		secondary_id = primary_id
	primary_id = id
	loadout_changed.emit()
	save_settings()


func set_secondary(id: String) -> void:
	if WeaponCatalog.get_by_id(id).is_empty():
		return
	if id == primary_id:
		primary_id = secondary_id
	secondary_id = id
	loadout_changed.emit()
	save_settings()


func set_difficulty(id: String) -> void:
	if not DIFFICULTY_MULT.has(id):
		return
	difficulty = id
	save_settings()


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("loadout", "primary", primary_id)
	cfg.set_value("loadout", "secondary", secondary_id)
	cfg.set_value("run", "difficulty", difficulty)
	cfg.set_value("audio", "master", Sfx.volume_master)
	cfg.set_value("audio", "bgm", Sfx.volume_bgm)
	cfg.set_value("audio", "sfx", Sfx.volume_sfx)
	cfg.save(SAVE_PATH)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	primary_id = str(cfg.get_value("loadout", "primary", primary_id))
	secondary_id = str(cfg.get_value("loadout", "secondary", secondary_id))
	difficulty = str(cfg.get_value("run", "difficulty", difficulty))
	Sfx.volume_master = clampf(float(cfg.get_value("audio", "master", Sfx.volume_master)), 0.0, 1.0)
	Sfx.volume_bgm = clampf(float(cfg.get_value("audio", "bgm", Sfx.volume_bgm)), 0.0, 1.0)
	Sfx.volume_sfx = clampf(float(cfg.get_value("audio", "sfx", Sfx.volume_sfx)), 0.0, 1.0)
	Sfx.apply_volumes()
	settings_changed.emit()
