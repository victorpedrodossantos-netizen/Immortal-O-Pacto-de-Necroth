extends Node2D

func _ready() -> void:
	print("--- TEST SQUAD GROUPS & HOTBAR STARTED ---")
	
	# 1. Instantiate Necroth
	var necroth_scene = load("res://entities/characters/necroth/necroth.tscn")
	var necroth = necroth_scene.instantiate()
	add_child(necroth)
	
	var summoner = necroth.summoner
	assert(summoner != null, "SummonerComponent must exist")
	
	print("Initial Group 1 Captain: ", summoner.group_1_captain.soldier_name if summoner.group_1_captain else "None")
	print("Initial Group 1 Members: ", summoner.group_1_members.size())
	print("Initial Group 2 Captain: ", summoner.group_2_captain.soldier_name if summoner.group_2_captain else "None")
	
	# Verify seeded data: Gareth is captain of G1, Kael is member of G1, Mulgath is captain of G2
	assert(summoner.group_1_captain != null, "G1 captain must be seeded")
	assert(summoner.group_1_captain.is_group_captain == true, "G1 captain flag must be true")
	assert(summoner.group_1_members.size() == 1, "G1 must have 1 member seeded")
	assert(summoner.group_2_captain != null, "G2 captain must be seeded")
	
	# 2. Test Group Capacity: Up to 5 members + 1 captain = 6 max
	# Add 4 more souls to Grupo 1 so it reaches 5 members + 1 captain = 6
	for i in range(4):
		var extra_soul = SubjugatedSoulData.new()
		extra_soul.id = "orc_grunt_%d" % i
		extra_soul.soldier_name = "Soldado Orc %d" % (i + 1)
		extra_soul.soul_class = SubjugatedSoulData.SoulClass.TROPA_CHOQUE
		summoner.subjugated_souls.append(extra_soul)
		var added = summoner.assign_soul_to_group(extra_soul, 1)
		assert(added == true, "Should successfully add member %d to group 1" % (i + 1))
	
	assert(summoner.group_1_members.size() == 5, "G1 must have exactly 5 members")
	assert(summoner.get_group_souls(1).size() == 6, "G1 total with captain must be 6")
	print("G1 successfully populated with 1 Captain + 5 Members (Total 6)")
	
	# Attempt to add a 7th soul to G1: must fail because 5 members + 1 captain are full!
	var extra_soul_7 = SubjugatedSoulData.new()
	extra_soul_7.id = "overflow_soul"
	extra_soul_7.soldier_name = "Guerreiro Excedente"
	summoner.subjugated_souls.append(extra_soul_7)
	var added_overflow = summoner.assign_soul_to_group(extra_soul_7, 1)
	assert(added_overflow == false, "Must reject adding beyond 6 members to group 1")
	print("Overflow rejection verified (max 6 capacity respected).")
	
	# 3. Test Promoting a member to Captain
	var candidate_member = summoner.group_1_members[0] # Kael
	var old_captain = summoner.group_1_captain # Gareth
	print("Promoting member '%s' to Captain of G1..." % candidate_member.soldier_name)
	
	var promoted = summoner.promote_to_group_captain(candidate_member)
	assert(promoted == true, "Promotion must succeed")
	assert(summoner.group_1_captain == candidate_member, "Candidate must now be captain")
	assert(candidate_member.is_group_captain == true, "Candidate flag must be is_group_captain")
	assert(candidate_member.soul_class == SubjugatedSoulData.SoulClass.COMANDANTE, "Candidate soul class must be COMANDANTE")
	assert(old_captain.is_group_captain == false, "Old captain must be demoted from captain status")
	assert(summoner.group_1_members.has(old_captain), "Old captain must now be in members list")
	print("Promotion verified: New Captain is '%s', previous captain became member." % summoner.group_1_captain.soldier_name)
	
	# 4. Test Grimoire UI with buttons & states
	var grimoire_scene = load("res://ui/screens/soul_grimoire_screen.tscn")
	var grimoire_ui = grimoire_scene.instantiate()
	add_child(grimoire_ui)
	grimoire_ui.open_grimoire(summoner)
	
	assert(grimoire_ui.btn_quick_slot1 != null, "BtnQuickSlot1 must exist")
	assert(grimoire_ui.btn_quick_slot2 != null, "BtnQuickSlot2 must exist")
	assert(grimoire_ui.btn_make_captain != null, "BtnMakeCaptain must exist")
	
	# Select captain
	grimoire_ui._select_soul(summoner.group_1_captain)
	assert(grimoire_ui.btn_make_captain.disabled == true, "BtnMakeCaptain must be disabled for current captain")
	assert(grimoire_ui.btn_quick_slot1.text == "✖️ REMOVER DO GRUPO 1", "BtnQuickSlot1 should offer removal")
	
	# Select member
	grimoire_ui._select_soul(summoner.group_1_members[0])
	assert(grimoire_ui.btn_make_captain.disabled == false, "BtnMakeCaptain must be enabled for group member")
	print("Grimoire UI button states verified.")
	
	# 5. Test Diablo Hotbar with 9 slots
	var hotbar_scene = load("res://ui/components/ability_hotbar.tscn")
	var hotbar_ui = hotbar_scene.instantiate()
	add_child(hotbar_ui)
	hotbar_ui.setup_necroth(necroth)
	
	assert(hotbar_ui.slot_squad1 != null, "SlotSquad1 must exist on hotbar")
	assert(hotbar_ui.slot_squad2 != null, "SlotSquad2 must exist on hotbar")
	assert(hotbar_ui.slot_squad1.shortcut_key == "8", "SlotSquad1 key must be 8")
	assert(hotbar_ui.slot_squad2.shortcut_key == "9", "SlotSquad2 key must be 9")
	assert(hotbar_ui.slot_squad1.ability_name == "Grupo 1 (6/6)", "SlotSquad1 must reflect 6/6 members: got " + hotbar_ui.slot_squad1.ability_name)
	print("Diablo Hotbar verified: Slot 8 and Slot 9 active with member counts.")
	
	# 6. Test Squad Group Summoning
	necroth.current_ether = 200.0 # Provide plenty of ether
	var spawned_squad = summoner.summon_squad_group(1, Vector2(100, 100))
	print("Summoned G1 squad count in field: ", spawned_squad.size())
	assert(spawned_squad.size() >= 2, "Squad group should summon multiple units")
	
	# Check if first spawned has captain aura/scale
	var cap_node = spawned_squad[0]
	assert(cap_node is GenericServantSoldier, "Summoned unit must be GenericServantSoldier")
	assert(cap_node.visual_root.scale.x > 1.1, "Captain servant must have elevated scale")
	print("Captain servant visual scale and leadership verified: ", cap_node.visual_root.scale)
	
	print("--- ALL SQUAD GROUPS & HOTBAR TESTS PASSED CLEANLY ---")
	get_tree().quit(0)
