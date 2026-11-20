extends Node

## SFX: Godot Sample + 웹 제스처 unlock
## BGM: 네이티브=Godot / 웹=HTML5 Audio(bgm/*.wav)
## 로비=테마별 bgm_lobby* / 전투=arena
## 참고: CompanyDefense docs/godot-web-audio.md

const BUS_MASTER := "Master"
const BUS_BGM := "BGM"
const BUS_SFX := "SFX"
const POOL := 10
const PLAYBACK_SAMPLE := 2
const SFX_DIR := "res://assets/sfx/"
const BGM_DIR := "res://assets/bgm/"
const BGM_LOBBY := "bgm_lobby"
const BGM_LOBBY_GRUNGE := "bgm_lobby_grunge"
const BGM_LOBBY_CLEAN := "bgm_lobby_clean"
const BGM_LOBBY_SIMPLE := "bgm_lobby_simple"
const BGM_ARENA := "arena"
const BGM_ID := BGM_LOBBY # 기본/부팅용 (메뉴)
const BGM_LOBBY_IDS := [BGM_LOBBY, BGM_LOBBY_GRUNGE, BGM_LOBBY_CLEAN, BGM_LOBBY_SIMPLE]

const SFX_IDS := [
	"gunshot", "reload", "dash", "hurt", "hit",
	"weapon_switch", "explosion", "electric", "pickup",
	"shot_pistol", "shot_shotgun", "shot_assault", "shot_sniper",
	"shot_mg", "shot_flame", "shot_taser", "shot_emp",
	"reload_pistol", "reload_shotgun", "reload_rifle", "reload_heavy", "reload_energy",
]

var volume_master: float = 1.0
var volume_bgm: float = 0.72
var volume_sfx: float = 0.9

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _cursor: int = 0
var _last_ms: Dictionary = {}
var _web_unlocked: bool = false
var _bgm: AudioStreamPlayer
var _bgm_id: String = ""
var _pending_bgm: String = BGM_ID
var _want_bgm: bool = true
var _unlock_tries: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_buses()
	_load_streams()

	for i in POOL:
		var p := AudioStreamPlayer.new()
		p.bus = BUS_SFX
		p.volume_db = 0.0
		if OS.has_feature("web"):
			p.playback_type = PLAYBACK_SAMPLE
		add_child(p)
		_players.append(p)

	if not OS.has_feature("web"):
		_bgm = AudioStreamPlayer.new()
		_bgm.bus = BUS_BGM
		_bgm.volume_db = 0.0
		add_child(_bgm)

	_alog("ready web=%s streams=%d" % [OS.has_feature("web"), _streams.size()])

	if OS.has_feature("web"):
		_publish_ctx_to_window()
		_html_bgm_preload()
		set_process(true)
		set_process_input(true)
		set_process_unhandled_input(true)
	else:
		# Loadout가 설정을 올린 뒤 볼륨 반영 + BGM 시작
		call_deferred("_boot_native_bgm")


func lobby_bgm_for_theme(theme_id: String) -> String:
	match theme_id:
		"grunge":
			return BGM_LOBBY_GRUNGE
		"clean":
			return BGM_LOBBY_CLEAN
		"simple":
			return BGM_LOBBY_SIMPLE
		_:
			return BGM_LOBBY


func _boot_native_bgm() -> void:
	apply_volumes()
	if _want_bgm:
		var id := _pending_bgm
		if id == "" or id == BGM_ID:
			if Loadout != null:
				id = lobby_bgm_for_theme(str(Loadout.ui_theme_id))
		play_bgm(id if id != "" else BGM_ID, true)


func _process(_dt: float) -> void:
	if not OS.has_feature("web"):
		set_process(false)
		return
	_publish_ctx_to_window()
	if _web_unlocked:
		set_process(false)


func _input(event: InputEvent) -> void:
	_try_web_unlock(event)


func _unhandled_input(event: InputEvent) -> void:
	_try_web_unlock(event)


func ensure_web_unlocked() -> void:
	## 웹: 이미 unlock된 경우 컨텍스트만 resume + BGM 재확인.
	## 미unlock이면 제스처 대기 (로딩에서 가짜 unlock 금지).
	if not OS.has_feature("web"):
		_ensure_bgm_playing()
		return
	if _web_unlocked:
		_resume_web_audio_context()
		_ensure_bgm_playing()
		return


func play(key: String, pitch_scale: float = 1.0, volume_db: float = 0.0, gap_ms: int = 35) -> void:
	if not _streams.has(key) or _players.is_empty():
		return
	if volume_master <= 0.001 or volume_sfx <= 0.001:
		return
	if OS.has_feature("web") and not _web_unlocked:
		return
	var now := Time.get_ticks_msec()
	if now - int(_last_ms.get(key, -99999)) < gap_ms:
		return
	_last_ms[key] = now
	_play_now(key, pitch_scale, volume_db)


func play_bgm(id: String = BGM_ID, force: bool = false) -> void:
	_pending_bgm = id
	_want_bgm = true
	if OS.has_feature("web"):
		if not force and not _web_unlocked:
			_alog("play_bgm(%s) deferred" % id)
			return
		if volume_master <= 0.001 or volume_bgm <= 0.001:
			_html_bgm_stop()
			_bgm_id = ""
			return
		if not force and _bgm_id == id and _html_bgm_is_playing(id):
			_html_bgm_set_volume()
			return
		_bgm_id = id
		_html_bgm_play(id, true)
		return

	if _bgm == null or not _streams.has(id):
		_alog("play_bgm skip: bgm=%s has=%s" % [_bgm != null, _streams.has(id)])
		return
	if volume_master <= 0.001 or volume_bgm <= 0.001:
		if _bgm.playing:
			_bgm.stop()
		_bgm_id = ""
		return
	if not force and _bgm_id == id and _bgm.playing:
		return
	_bgm_id = id
	_bgm.stream = _streams[id]
	_bgm.play()
	_alog("native play_bgm(%s)" % id)


func stop_bgm() -> void:
	_want_bgm = false
	_bgm_id = ""
	_pending_bgm = ""
	if OS.has_feature("web"):
		_html_bgm_stop()
	elif _bgm:
		_bgm.stop()


func apply_volumes() -> void:
	_set_bus_linear(BUS_MASTER, volume_master)
	_set_bus_linear(BUS_BGM, volume_bgm)
	_set_bus_linear(BUS_SFX, volume_sfx)
	if OS.has_feature("web"):
		_html_bgm_set_volume()
	# 볼륨을 0→복구하거나 설정 로드 후 BGM이 꺼져 있으면 재시작
	_ensure_bgm_playing()


func _ensure_bgm_playing() -> void:
	if not _want_bgm:
		return
	if volume_master <= 0.001 or volume_bgm <= 0.001:
		return
	var id := _pending_bgm if _pending_bgm != "" else BGM_ID
	if OS.has_feature("web"):
		if not _web_unlocked:
			return
		if _bgm_id != id or not _html_bgm_is_playing(id):
			play_bgm(id, true)
		else:
			_html_bgm_set_volume()
		return
	if _bgm == null:
		return
	if not _bgm.playing or _bgm_id != id:
		play_bgm(id, true)


func _play_now(id: String, pitch: float, volume_db: float) -> void:
	var p: AudioStreamPlayer = _players[_cursor]
	_cursor = (_cursor + 1) % _players.size()
	p.stream = _streams[id]
	p.pitch_scale = clampf(pitch, 0.7, 1.4)
	p.volume_db = volume_db
	if AudioServer.get_bus_index(p.bus) < 0:
		p.bus = BUS_MASTER
	p.play()


func _try_web_unlock(event: InputEvent) -> void:
	if not OS.has_feature("web") or _web_unlocked:
		return
	if not (event is InputEventMouseButton or event is InputEventScreenTouch \
			or event is InputEventKey or event is InputEventJoypadButton):
		return
	if event is InputEventMouseButton and not event.pressed:
		return
	if event is InputEventScreenTouch and not event.pressed:
		return
	if event is InputEventKey and not event.pressed:
		return
	if event is InputEventJoypadButton and not event.pressed:
		return
	_unlock_tries += 1
	_alog("gesture try=%d type=%s" % [_unlock_tries, event.get_class()])
	_finish_web_unlock()


func _finish_web_unlock() -> void:
	if _web_unlocked:
		return
	_publish_ctx_to_window()
	var ctx := _resume_web_audio_context()
	_alog("unlock ctx=%s" % ctx)
	var master_idx := AudioServer.get_bus_index(BUS_MASTER)
	if master_idx >= 0:
		AudioServer.set_bus_mute(master_idx, false)
	apply_volumes()
	if _streams.has("weapon_switch"):
		_play_now("weapon_switch", 1.0, -6.0)
	_web_unlocked = true
	play_bgm(_pending_bgm if _pending_bgm != "" else BGM_ID, true)
	set_process_input(false)
	set_process_unhandled_input(false)
	_alog("fully unlocked")


func _load_streams() -> void:
	for id in SFX_IDS:
		var path: String = SFX_DIR + id + ".wav"
		if not ResourceLoader.exists(path):
			_alog("missing sfx: %s" % path)
			continue
		var stream: AudioStream = load(path)
		if stream == null:
			continue
		if OS.has_feature("web") and AudioServer.has_method("register_stream_as_sample"):
			AudioServer.register_stream_as_sample(stream)
		_streams[id] = stream

	if not OS.has_feature("web"):
		for bgm_id in BGM_LOBBY_IDS:
			_load_native_bgm(bgm_id)
		_load_native_bgm(BGM_ARENA)

	_alog("loaded count=%d" % _streams.size())


func _load_native_bgm(bgm_id: String) -> void:
	var bgm_path: String = BGM_DIR + bgm_id + ".wav"
	if not ResourceLoader.exists(bgm_path):
		_alog("missing bgm: %s" % bgm_path)
		return
	var bgm_stream: AudioStream = load(bgm_path)
	if bgm_stream is AudioStreamWAV:
		bgm_stream = bgm_stream.duplicate()
		(bgm_stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	_streams[bgm_id] = bgm_stream
	_alog("loaded native bgm %s" % bgm_id)


func _ensure_buses() -> void:
	_ensure_bus(BUS_BGM)
	_ensure_bus(BUS_SFX)


func _ensure_bus(name: String) -> void:
	if AudioServer.get_bus_index(name) >= 0:
		return
	var idx := AudioServer.bus_count
	AudioServer.bus_count = idx + 1
	AudioServer.set_bus_name(idx, name)
	AudioServer.set_bus_send(idx, BUS_MASTER)


func _set_bus_linear(bus: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus)
	if idx < 0:
		return
	var v := clampf(linear, 0.0, 1.0)
	AudioServer.set_bus_mute(idx, v <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(v, 0.0001)))


func _alog(msg: String) -> void:
	var line := "[Audio] %s" % msg
	print(line)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("console.log(%s)" % JSON.stringify(line))


func _publish_ctx_to_window() -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval("""
		(function () {
			try {
				if (typeof GodotAudio !== 'undefined' && GodotAudio.ctx) {
					window.__godotAudioContext = GodotAudio.ctx;
					window.GodotAudio = GodotAudio;
				}
			} catch (e) {}
		})();
	""")


func _resume_web_audio_context() -> String:
	if not OS.has_feature("web"):
		return "n/a"
	var state: Variant = JavaScriptBridge.eval("""
		(function () {
			try {
				var ctx = (typeof GodotAudio !== 'undefined' && GodotAudio.ctx)
					|| window.__godotAudioContext || null;
				if (!ctx) return 'no-ctx';
				window.__godotAudioContext = ctx;
				if (ctx.state === 'suspended' && ctx.resume) ctx.resume();
				try {
					var buf = ctx.createBuffer(1, 1, 22050);
					var src = ctx.createBufferSource();
					src.buffer = buf;
					src.connect(ctx.destination);
					src.start(0);
				} catch (e2) {}
				return String(ctx.state);
			} catch (e) {
				return 'error:' + String(e);
			}
		})();
	""")
	return str(state)


func _html_bgm_preload() -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval("""
		(function () {
			window.__saBgm = window.__saBgm || {};
			window.__saBgmVol = window.__saBgmVol || 0.72;
			window.__saBgmFadeOut = 2.5;
			window.__saBgmFadeIn = 1.0;
			window.__saBindBgm = window.__saBindBgm || function (a, id) {
				if (a.__saBound) return;
				a.__saBound = true;
				a.__saId = id;
				a.__saLoop = true;
				a.__saFading = false;
				a.__saFadeIn = null;
				a.addEventListener('timeupdate', function () {
					if (!a.__saLoop || !a.duration || a.paused || a.__saFading) return;
					var left = a.duration - a.currentTime;
					if (left <= window.__saBgmFadeOut && left > 0.05) {
						a.__saFading = true;
					}
					if (a.__saFading) {
						var t = Math.max(0, a.duration - a.currentTime);
						a.volume = Math.max(0, window.__saBgmVol * (t / window.__saBgmFadeOut));
					}
				});
				a.addEventListener('ended', function () {
					if (!a.__saLoop) return;
					a.__saFading = false;
					if (a.__saFadeIn) { clearInterval(a.__saFadeIn); a.__saFadeIn = null; }
					try { a.currentTime = 0; } catch (e) {}
					a.volume = 0;
					var p = a.play();
					var startFade = function () {
						var t0 = performance.now();
						a.__saFadeIn = setInterval(function () {
							var u = Math.min(1, (performance.now() - t0) / (window.__saBgmFadeIn * 1000));
							a.volume = window.__saBgmVol * u;
							if (u >= 1) {
								clearInterval(a.__saFadeIn);
								a.__saFadeIn = null;
								a.volume = window.__saBgmVol;
							}
						}, 40);
					};
					if (p && p.then) p.then(startFade).catch(function (e) {
						console.warn('[Audio/html] loop restart fail', id, String(e));
					});
					else startFade();
				});
			};
			['bgm_lobby', 'bgm_lobby_grunge', 'bgm_lobby_clean', 'bgm_lobby_simple', 'arena'].forEach(function (id) {
				if (!window.__saBgm[id]) {
					var a = new Audio('bgm/' + id + '.wav');
					a.preload = 'auto';
					a.loop = false;
					window.__saBindBgm(a, id);
					window.__saBgm[id] = a;
				}
			});
			console.log('[Audio/html] preload lobby themes+arena');
		})();
	""")


func _html_bgm_play(id: String, _loop: bool) -> void:
	if not OS.has_feature("web"):
		return
	var vol := clampf(volume_bgm * volume_master, 0.0, 1.0)
	var js := """
		(function () {
			try {
				window.__saBgm = window.__saBgm || {};
				window.__saBgmVol = %s;
				var id = %s;
				Object.keys(window.__saBgm).forEach(function (k) {
					var el = window.__saBgm[k];
					if (!el || k === id) return;
					el.pause();
					if (el.__saFadeIn) { clearInterval(el.__saFadeIn); el.__saFadeIn = null; }
					el.__saFading = false;
					try { el.currentTime = 0; } catch (e) {}
				});
				var a = window.__saBgm[id];
				if (!a) {
					a = new Audio('bgm/' + id + '.wav');
					a.preload = 'auto';
					a.loop = false;
					window.__saBgm[id] = a;
				}
				if (window.__saBindBgm) window.__saBindBgm(a, id);
				a.__saLoop = true;
				a.__saFading = false;
				if (a.__saFadeIn) { clearInterval(a.__saFadeIn); a.__saFadeIn = null; }
				a.volume = window.__saBgmVol;
				var p = a.play();
				if (p && p.then) {
					p.then(function () {
						console.log('[Audio/html] playing', id, 'vol=' + a.volume);
					}).catch(function (e) {
						console.warn('[Audio/html] play fail', id, String(e));
					});
				}
			} catch (e) {
				console.warn('[Audio/html] play error', e);
			}
		})();
	""" % [JSON.stringify(vol), JSON.stringify(id)]
	JavaScriptBridge.eval(js)
	_alog("html5 play_bgm(%s) vol=%.2f" % [id, vol])


func _html_bgm_is_playing(id: String) -> bool:
	if not OS.has_feature("web"):
		return false
	var r: Variant = JavaScriptBridge.eval("""
		(function () {
			var a = (window.__saBgm || {})[%s];
			return !!(a && !a.paused && a.currentTime > 0);
		})();
	""" % JSON.stringify(id))
	return bool(r)


func _html_bgm_stop() -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval("""
		(function () {
			var m = window.__saBgm || {};
			Object.keys(m).forEach(function (k) {
				if (!m[k]) return;
				m[k].pause();
				if (m[k].__saFadeIn) { clearInterval(m[k].__saFadeIn); m[k].__saFadeIn = null; }
				m[k].__saFading = false;
				try { m[k].currentTime = 0; } catch (e) {}
			});
		})();
	""")


func _html_bgm_set_volume() -> void:
	if not OS.has_feature("web"):
		return
	var vol := clampf(volume_bgm * volume_master, 0.0, 1.0)
	JavaScriptBridge.eval("""
		(function () {
			var vol = %s;
			window.__saBgmVol = vol;
			var m = window.__saBgm || {};
			Object.keys(m).forEach(function (k) {
				var a = m[k];
				if (!a || a.__saFading || a.__saFadeIn) return;
				a.volume = Math.max(0, Math.min(1, vol));
			});
		})();
	""" % JSON.stringify(vol))
