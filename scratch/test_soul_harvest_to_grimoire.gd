extends Node2D

func _ready() -> void:
	print("--- TEST HARVEST SOUL TO GRIMOIRE STARTED ---")
	
	# Instantiate Necroth
	var necroth_scene = load("res://entities/characters/necroth/necroth.tscn")
	var necroth = necroth_scene.instantiate()
	add_child(necroth)
	necroth.global_position = Vector2(0, 0)
	
	var summoner = necroth.summoner
	assert(summoner != null, "Necroth must have summoner component")
	var initial_souls = summoner.subjugated_souls.size()
	print("Initial souls in Grimoire: ", initial_souls)
	
	# 1. Test standard enemy soul drop
	var drop_scene = load("res://entities/items/soul_drop_2d.tscn")
	var orc_drop = drop_scene.instantiate()
	orc_drop.source_enemy_name = "Orc Fendido Caçador"
	orc_drop.source_faction = GameEnums.Faction.FENDIDOS_DE_FERRO
	orc_drop.is_captain = false
	add_child(orc_drop)
	
	# Simulate absorption
	necroth.harvest_soul_orb(orc_drop)
	orc_drop.queue_free()
	
	assert(summoner.subjugated_souls.size() == initial_souls + 1, "Orc soul was not added to grimoire!")
	var added_orc = summoner.subjugated_souls.back()
	print("Absorbed standard soul: ", added_orc.soldier_name, " | Class: ", added_orc.soul_class, " | Faction: ", added_orc.faction)
	assert(added_orc.soldier_name == "Espectro de Orc Fendido Caçador", "Orc soldier name mismatch")
	assert(added_orc.faction == GameEnums.Faction.FENDIDOS_DE_FERRO, "Orc faction mismatch")
	
	# 2. Test Captain soul drop
	var captain_drop = drop_scene.instantiate()
	captain_drop.source_enemy_name = "Olog-hai Esmagador"
	captain_drop.source_faction = GameEnums.Faction.VAGANTES_DO_VEU
	captain_drop.is_captain = true
	
	# Create mock WarlordData for Nemesis Captain
	var warlord = WarlordData.new()
	warlord.commander_name = "Krag"
	warlord.title = "o Quebrador de Ossos"
	warlord.faction = GameEnums.Faction.VAGANTES_DO_VEU
	warlord.power_level = 28
	var str_list: Array[String] = ["Fúria Implacável", "Casca Pétrea"]
	warlord.strengths = str_list
	var weak_list: Array[String] = ["Fogo Espectral"]
	warlord.weaknesses = weak_list
	
	captain_drop.captain_warlord_data = warlord
	add_child(captain_drop)
	
	necroth.harvest_soul_orb(captain_drop)
	captain_drop.queue_free()
	
	assert(summoner.subjugated_souls.size() == initial_souls + 2, "Captain soul was not added to grimoire!")
	var added_captain = summoner.subjugated_souls.back()
	print("Absorbed Captain soul: ", added_captain.soldier_name, " | Class: ", added_captain.soul_class, " | HP: ", added_captain.max_health, " | Atk: ", added_captain.attack_damage)
	
	assert(added_captain.soldier_name == "Espectro de Krag, o Quebrador de Ossos", "Captain name incorrect: " + added_captain.soldier_name)
	assert(added_captain.soul_class == SubjugatedSoulData.SoulClass.COMANDANTE, "Captain class should be COMANDANTE")
	assert(added_captain.max_health >= 350.0, "Captain should have elevated HP")
	assert(added_captain.sacrifice_buff == SubjugatedSoulData.SacrificeBuffType.ASCENSAO_FUNEBRE, "Captain should provide ASCENSAO_FUNEBRE")
	
	# 3. Test Grimoire Screen UI binding
	var grimoire_scene = load("res://ui/screens/soul_grimoire_screen.tscn")
	var grimoire_ui = grimoire_scene.instantiate()
	add_child(grimoire_ui)
	grimoire_ui.open_grimoire(necroth.summoner)
	
	var cards_count = grimoire_ui.soul_container.get_child_count()
	print("Grimoire UI cards count rendered: ", cards_count)
	assert(cards_count >= 2, "Grimoire UI failed to render absorbed souls!")
	
	print("--- TEST HARVEST SOUL TO GRIMOIRE COMPLETED SUCCESSFULLY ---")
	get_tree().quit(0)
