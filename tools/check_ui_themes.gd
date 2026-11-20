extends SceneTree

## 스킨 파일 존재 확인 (autoload 없이 동작).
## godot --headless --path . -s res://tools/check_ui_themes.gd


func _init() -> void:
	var ok := true
	for id in ["grunge", "clean", "simple"]:
		for f in ["panel_9slice.png", "button_9slice.png", "slot_9slice.png", "decor_corner.png"]:
			var path := "res://assets/ui/skins/%s/%s" % [id, f]
			if not ResourceLoader.exists(path):
				push_error("missing %s" % path)
				ok = false
			else:
				print("[theme] ok ", path)
	if ok:
		print("[theme] OK")
		quit(0)
	else:
		print("[theme] FAIL")
		quit(1)
