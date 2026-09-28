extends Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var chamber_scene = load("res://scenes/test_chamber_2d.tscn")
	var chamber = chamber_scene.instantiate()
	add_child(chamber)
	
	# Open grimoire after 3 frames
	await get_tree().create_timer(0.2).timeout
	chamber._toggle_grimoire()
	print("Grimoire opened, waiting to capture...")
	await get_tree().create_timer(0.3).timeout
	
	var img: Image = get_viewport().get_texture().get_image()
	var out_path = "/home/victor/.gemini/antigravity-ide/brain/adf0d656-e746-41bd-9cf3-239e958d9da4/grimoire_redesign_screenshot.png"
	img.save_png(out_path)
	print("Full chamber grimoire screenshot saved to: ", out_path)
	get_tree().quit(0)
