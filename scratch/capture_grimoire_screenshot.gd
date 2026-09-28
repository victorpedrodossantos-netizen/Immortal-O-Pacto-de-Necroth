extends Node2D

var frame_count: int = 0

func _ready() -> void:
	var necroth_scene = load("res://entities/characters/necroth/necroth.tscn")
	var necroth = necroth_scene.instantiate()
	add_child(necroth)
	
	var grimoire_scene = load("res://ui/screens/soul_grimoire_screen.tscn")
	var grimoire_ui = grimoire_scene.instantiate()
	add_child(grimoire_ui)
	grimoire_ui.open_grimoire(necroth.summoner)

func _process(_delta: float) -> void:
	frame_count += 1
	if frame_count == 5:
		var img: Image = get_viewport().get_texture().get_image()
		var out_path = "/home/victor/.gemini/antigravity-ide/brain/adf0d656-e746-41bd-9cf3-239e958d9da4/grimoire_redesign_screenshot.png"
		img.save_png(out_path)
		print("Screenshot saved to: ", out_path)
		get_tree().quit(0)
