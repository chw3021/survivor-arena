extends Node

signal kills_changed(value: int)
signal time_changed(seconds: float)
signal wave_changed(value: int)

var kills: int = 0
var elapsed: float = 0.0
var wave: int = 1
var running: bool = true


func _process(delta: float) -> void:
	if not running:
		return
	elapsed += delta
	time_changed.emit(elapsed)


func add_kill() -> void:
	kills += 1
	kills_changed.emit(kills)


func set_wave(value: int) -> void:
	wave = value
	wave_changed.emit(wave)


func reset() -> void:
	kills = 0
	elapsed = 0.0
	wave = 1
	running = true
	kills_changed.emit(kills)
	time_changed.emit(elapsed)
	wave_changed.emit(wave)
