class_name SummonerComponent
extends Node2D

const SubjugatedSoulData = preload("res://resources/subjugated_soul_data.gd")
const GenericServantSoldier = preload("res://entities/characters/servants/generic_servant_soldier.gd")

## Componente de Evocação e Comando do Exército Espectral de Necroth
## Gerencia o Primeiro Guardião (Carrasco do Limbo) e o Tabuleiro de Almas Subjulgadas.

signal servant_count_changed(current_count: int, max_count: int)
signal guardian_state_changed(is_active: bool)
signal subjugated_souls_updated

@export var codex: CodexResource
@export var carrasco_scene: PackedScene
@export var generic_servant_scene: PackedScene
@export var max_field_servants: int = 12

var active_guardian: Node2D = null
var active_servants: Array[Node2D] = []
var subjugated_souls: Array[SubjugatedSoulData] = []

# Grupos de Esquadrão (Capitão + até 5 membros = máx 6 por grupo)
var group_1_captain: SubjugatedSoulData = null
var group_1_members: Array[SubjugatedSoulData] = []
var group_2_captain: SubjugatedSoulData = null
var group_2_members: Array[SubjugatedSoulData] = []

var quick_slot_1: SubjugatedSoulData:
	get:
		return group_1_captain if group_1_captain else (group_1_members[0] if not group_1_members.is_empty() else null)
	set(val):
		if val: assign_soul_to_group(val, 1)

var quick_slot_2: SubjugatedSoulData:
	get:
		return group_2_captain if group_2_captain else (group_2_members[0] if not group_2_members.is_empty() else null)
	set(val):
		if val: assign_soul_to_group(val, 2)

func _ready() -> void:
	if not codex:
		codex = CodexResource.new()
	if not carrasco_scene:
		carrasco_scene = load("res://entities/characters/servants/carrasco_do_limbo/carrasco_do_limbo.tscn")
	if not generic_servant_scene:
		generic_servant_scene = load("res://entities/characters/servants/generic_servant_soldier.tscn")
	
	_seed_initial_subjugated_souls()

func _seed_initial_subjugated_souls() -> void:
	if not subjugated_souls.is_empty():
		return
	
	# Alma 1: Guerreiro de Choque promovido a Capitão do Grupo 1
	var s1: SubjugatedSoulData = SubjugatedSoulData.new()
	s1.id = "gareth_choque"
	s1.soldier_name = "Gareth, O Rompe-Escudos"
	s1.soul_class = SubjugatedSoulData.SoulClass.COMANDANTE
	s1.faction = GameEnums.Faction.FENDIDOS_DE_FERRO
	s1.max_health = 240.0
	s1.attack_damage = 28.0
	s1.move_speed = 180.0
	s1.sacrifice_buff = SubjugatedSoulData.SacrificeBuffType.COURAÇA_FERRO
	s1.lore_description = "Capitão veterano com aura defensiva implacável e postura de comando."
	s1.assigned_group = 1
	s1.is_group_captain = true
	subjugated_souls.append(s1)
	group_1_captain = s1
	
	# Alma 2: Flanqueador Ágil alocado no Grupo 1
	var s2: SubjugatedSoulData = SubjugatedSoulData.new()
	s2.id = "kael_flanqueador"
	s2.soldier_name = "Kael, Lâmina Espectral"
	s2.soul_class = SubjugatedSoulData.SoulClass.FLANQUEADOR
	s2.faction = GameEnums.Faction.PACTO_NECROTH
	s2.max_health = 130.0
	s2.attack_damage = 32.0
	s2.move_speed = 230.0
	s2.sacrifice_buff = SubjugatedSoulData.SacrificeBuffType.PASSO_FANTASMA
	s2.lore_description = "Assassino das fendas umbrais veloz como o próprio sopro do Limbo."
	s2.assigned_group = 1
	s2.is_group_captain = false
	subjugated_souls.append(s2)
	group_1_members.append(s2)
	
	# Alma 3: Taumaturgo de Suporte alocado no Grupo 2
	var s3: SubjugatedSoulData = SubjugatedSoulData.new()
	s3.id = "mulgath_mago"
	s3.soldier_name = "Mulgath, Piromante do Limbo"
	s3.soul_class = SubjugatedSoulData.SoulClass.SUPORTE_DISTANCIA
	s3.faction = GameEnums.Faction.PUTRIDOS_DO_LIMO
	s3.max_health = 110.0
	s3.attack_damage = 26.0
	s3.move_speed = 185.0
	s3.sacrifice_buff = SubjugatedSoulData.SacrificeBuffType.MANANCIAL_VAZIO
	s3.lore_description = "Canalizador de fogo fátuo e vapores corrosivos à longa distância."
	s3.assigned_group = 2
	s3.is_group_captain = true
	subjugated_souls.append(s3)
	group_2_captain = s3
	
	emit_signal("subjugated_souls_updated")

## Atribui ou remove alma de um grupo (Grupo 1 ou Grupo 2)
## Capacidade por grupo: 1 Capitão + até 5 membros = 6 soldados no total
func assign_soul_to_group(soul: SubjugatedSoulData, group_num: int) -> bool:
	if not soul:
		return false
	
	# Se já está neste grupo, alterna desvinculando
	if soul.assigned_group == group_num:
		remove_soul_from_group(soul)
		return true
	
	# Se estava em outro grupo, remove de lá primeiro
	if soul.assigned_group != 0:
		remove_soul_from_group(soul)
	
	if group_num == 1:
		if not group_1_captain and (soul.is_group_captain or soul.soul_class == SubjugatedSoulData.SoulClass.COMANDANTE):
			group_1_captain = soul
			soul.is_group_captain = true
		elif group_1_members.size() < 5:
			group_1_members.append(soul)
			soul.is_group_captain = false
		elif not group_1_captain:
			# Membros cheios (5), mas sem capitão: promove a capitão
			group_1_captain = soul
			soul.is_group_captain = true
		else:
			# Grupo 1 completamente cheio (1 Capitão + 5 Membros)
			return false
	elif group_num == 2:
		if not group_2_captain and (soul.is_group_captain or soul.soul_class == SubjugatedSoulData.SoulClass.COMANDANTE):
			group_2_captain = soul
			soul.is_group_captain = true
		elif group_2_members.size() < 5:
			group_2_members.append(soul)
			soul.is_group_captain = false
		elif not group_2_captain:
			group_2_captain = soul
			soul.is_group_captain = true
		else:
			# Grupo 2 completamente cheio
			return false
	else:
		return false
	
	soul.assigned_group = group_num
	emit_signal("subjugated_souls_updated")
	return true

## Remove alma do seu grupo atual
func remove_soul_from_group(soul: SubjugatedSoulData) -> void:
	if not soul:
		return
	
	if group_1_captain == soul:
		group_1_captain = null
	if group_1_members.has(soul):
		group_1_members.erase(soul)
	if group_2_captain == soul:
		group_2_captain = null
	if group_2_members.has(soul):
		group_2_members.erase(soul)
	
	soul.assigned_group = 0
	soul.is_group_captain = false
	emit_signal("subjugated_souls_updated")

## Transforma a alma selecionada no Capitão do Grupo em que ela estiver
func promote_to_group_captain(soul: SubjugatedSoulData) -> bool:
	if not soul:
		return false
	
	# Se a alma não estiver em nenhum grupo, tenta inseri-la no Grupo 1 primeiro
	if soul.assigned_group == 0:
		assign_soul_to_group(soul, 1)
	
	var g_num: int = soul.assigned_group
	if g_num == 1:
		if group_1_captain == soul:
			return true # Já é o capitão
		var prev_cap: SubjugatedSoulData = group_1_captain
		if group_1_members.has(soul):
			group_1_members.erase(soul)
		group_1_captain = soul
		soul.is_group_captain = true
		soul.soul_class = SubjugatedSoulData.SoulClass.COMANDANTE
		# Rebaixa o capitão antigo para membro se houver vaga
		if prev_cap:
			prev_cap.is_group_captain = false
			if group_1_members.size() < 5:
				group_1_members.append(prev_cap)
			else:
				prev_cap.assigned_group = 0
	elif g_num == 2:
		if group_2_captain == soul:
			return true
		var prev_cap: SubjugatedSoulData = group_2_captain
		if group_2_members.has(soul):
			group_2_members.erase(soul)
		group_2_captain = soul
		soul.is_group_captain = true
		soul.soul_class = SubjugatedSoulData.SoulClass.COMANDANTE
		if prev_cap:
			prev_cap.is_group_captain = false
			if group_2_members.size() < 5:
				group_2_members.append(prev_cap)
			else:
				prev_cap.assigned_group = 0
	
	emit_signal("subjugated_souls_updated")
	return true

## Retorna lista de todas as almas de um grupo (Capitão + Membros)
func get_group_souls(group_num: int) -> Array[SubjugatedSoulData]:
	var result: Array[SubjugatedSoulData] = []
	if group_num == 1:
		if group_1_captain: result.append(group_1_captain)
		for m in group_1_members: result.append(m)
	elif group_num == 2:
		if group_2_captain: result.append(group_2_captain)
		for m in group_2_members: result.append(m)
	return result

## Invoca todo o esquadrão de um grupo de uma só vez (Capitão + Membros)
func summon_squad_group(group_num: int, target_pos: Vector2 = Vector2.ZERO) -> Array[Node2D]:
	var souls_to_summon: Array[SubjugatedSoulData] = get_group_souls(group_num)
	var spawned_nodes: Array[Node2D] = []
	
	if souls_to_summon.is_empty():
		return spawned_nodes
	
	if target_pos == Vector2.ZERO:
		target_pos = global_position + Vector2(80, 0)
	
	var captain_soul: SubjugatedSoulData = group_1_captain if group_num == 1 else group_2_captain
	var captain_node: Node2D = null
	
	# Invoca o Capitão primeiro
	if captain_soul and not captain_soul.is_summoned:
		captain_node = summon_subjugated_soul(captain_soul, target_pos)
		if captain_node:
			spawned_nodes.append(captain_node)
	
	# Invoca os membros em formação circular ao redor do Capitão
	var members: Array[SubjugatedSoulData] = group_1_members if group_num == 1 else group_2_members
	var member_count: int = members.size()
	for i in range(member_count):
		var m_soul: SubjugatedSoulData = members[i]
		if not m_soul.is_summoned:
			var angle: float = (TAU / maxf(1.0, float(member_count))) * i
			var offset: Vector2 = Vector2(cos(angle), sin(angle)) * 75.0
			var member_pos: Vector2 = (captain_node.global_position if captain_node else target_pos) + offset
			var m_node: Node2D = summon_subjugated_soul(m_soul, member_pos)
			if m_node:
				if captain_node and m_node.has_method("set_commander_master"):
					m_node.set_commander_master(captain_node)
				spawned_nodes.append(m_node)
	
	return spawned_nodes

## Invoca ou reanima o Primeiro Guardião: O Carrasco do Limbo
func summon_carrasco() -> bool:
	if is_instance_valid(active_guardian):
		active_guardian.global_position = global_position + Vector2(-60, -20)
		return true
	
	var summon_cost: float = 20.0
	if codex:
		codex.consume_energy(minf(summon_cost, codex.current_spectral_energy))
	
	if not carrasco_scene:
		return false
	
	var carrasco: Node2D = carrasco_scene.instantiate()
	carrasco.global_position = global_position + Vector2(-70, 0)
	
	var parent_tree: Node = get_tree().current_scene if get_tree() else null
	var target_parent: Node = parent_tree if parent_tree else get_parent()
	if target_parent:
		target_parent.add_child.call_deferred(carrasco)
	
	if carrasco.has_method("set_commander_master"):
		carrasco.set_commander_master(get_parent())
	
	active_guardian = carrasco
	carrasco.tree_exited.connect(_on_guardian_tree_exited)
	emit_signal("guardian_state_changed", true)
	EventBus.servant_summoned.emit(carrasco, summon_cost)
	EventBus.squad_alert_changed.emit(carrasco, GameEnums.AlertLevel.COMBATE_ATIVO, carrasco.global_position)
	return true

## Materializa uma Alma Subjulgada no campo de batalha
func summon_subjugated_soul(soul: SubjugatedSoulData, spawn_pos: Vector2 = Vector2.ZERO) -> Node2D:
	_clean_dead_servants()
	
	if active_servants.size() >= max_field_servants:
		AudioManager.play_sfx(AudioManager.stream_hit, 0.5)
		return null
	
	if not generic_servant_scene:
		return null
	
	var parent_node: Node2D = get_parent() as Node2D
	var necroth_body: Necroth = parent_node as Necroth
	
	if necroth_body and necroth_body.current_ether < soul.summon_ether_cost:
		AudioManager.play_sfx(AudioManager.stream_hit, 0.6)
		return null
	
	if necroth_body:
		necroth_body.current_ether -= soul.summon_ether_cost
		necroth_body.emit_signal("ether_changed", necroth_body.current_ether, necroth_body.max_ether)
	
	var soldier: GenericServantSoldier = generic_servant_scene.instantiate()
	if spawn_pos == Vector2.ZERO:
		spawn_pos = global_position + Vector2(randf_range(-80, 80), randf_range(-80, 80))
	soldier.global_position = spawn_pos
	
	# Define mestre (Carrasco se atribuído à escolta, ou o próprio Necroth)
	var master: Node2D = active_guardian if (soul.assigned_to_guardian and is_instance_valid(active_guardian)) else parent_node
	soldier.setup_from_soul(soul, master)
	
	var cur_scene: Node = get_tree().current_scene
	if cur_scene:
		cur_scene.add_child(soldier)
	else:
		get_parent().add_child(soldier)
	
	soul.is_summoned = true
	active_servants.append(soldier)
	soldier.tree_exited.connect(func(): _on_servant_tree_exited(soldier, soul))
	
	AudioManager.play_sfx(AudioManager.stream_summon, 2.0)
	emit_signal("servant_count_changed", active_servants.size(), max_field_servants)
	emit_signal("subjugated_souls_updated")
	return soldier

## Sacrifica a alma para conceder um bônus temporário poderoso
func sacrifice_subjugated_soul(soul: SubjugatedSoulData) -> bool:
	if not soul:
		return false
	
	# Se a alma estava invocada em campo, desintegra o corpo espectral
	for s in active_servants:
		if is_instance_valid(s) and s is GenericServantSoldier and (s as GenericServantSoldier).soul_data == soul:
			s.queue_free()
			break
	
	# Aplica o buff no GameManager
	GameManager.apply_sacrifice_buff(soul.sacrifice_buff, soul.soldier_name)
	
	# Remove a alma consumida do inventário e de qualquer grupo
	subjugated_souls.erase(soul)
	remove_soul_from_group(soul)
	
	# Se for o buff de Ascensão Fúnebre, executa cura e onda de choque imediata
	var necroth_body: Necroth = get_parent() as Necroth
	if necroth_body:
		if soul.sacrifice_buff == SubjugatedSoulData.SacrificeBuffType.ASCENSAO_FUNEBRE:
			necroth_body.heal(necroth_body.max_health)
			necroth_body.current_ether = necroth_body.max_ether
			necroth_body.emit_signal("ether_changed", necroth_body.current_ether, necroth_body.max_ether)
			_trigger_sacred_shockwave()
	
	emit_signal("subjugated_souls_updated")
	return true

func _trigger_sacred_shockwave() -> void:
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if e is BaseCharacter and not e.is_dead:
			var d: float = global_position.distance_to(e.global_position)
			if d <= 550.0:
				e.take_damage(45.0, get_parent())
				var dir: Vector2 = (e.global_position - global_position).normalized()
				e.velocity += dir * 400.0

## Alterna se a alma deve escoltar o Carrasco ou Necroth
func toggle_guardian_escort(soul: SubjugatedSoulData) -> void:
	if soul:
		soul.assigned_to_guardian = not soul.assigned_to_guardian
		# Atualiza soldado em campo se já estiver instanciado
		for s in active_servants:
			if is_instance_valid(s) and s is GenericServantSoldier and (s as GenericServantSoldier).soul_data == soul:
				var master: Node2D = active_guardian if (soul.assigned_to_guardian and is_instance_valid(active_guardian)) else get_parent()
				s.set_commander_master(master)
		emit_signal("subjugated_souls_updated")

## Registra uma nova alma capturada de inimigos derrotados
func capture_enemy_soul(enemy_name: String, faction: GameEnums.Faction) -> SubjugatedSoulData:
	var new_soul: SubjugatedSoulData = SubjugatedSoulData.new()
	new_soul.id = "soul_%s_%d" % [enemy_name.to_lower().replace(" ", "_"), Time.get_ticks_msec()]
	new_soul.soldier_name = "Espectro de %s" % enemy_name
	new_soul.faction = faction
	
	var rand_val: float = randf()
	if rand_val < 0.4:
		new_soul.soul_class = SubjugatedSoulData.SoulClass.TROPA_CHOQUE
		new_soul.sacrifice_buff = SubjugatedSoulData.SacrificeBuffType.COURAÇA_FERRO
		new_soul.max_health = 170.0
		new_soul.attack_damage = 22.0
	elif rand_val < 0.75:
		new_soul.soul_class = SubjugatedSoulData.SoulClass.FLANQUEADOR
		new_soul.sacrifice_buff = SubjugatedSoulData.SacrificeBuffType.PASSO_FANTASMA
		new_soul.max_health = 125.0
		new_soul.attack_damage = 30.0
	else:
		new_soul.soul_class = SubjugatedSoulData.SoulClass.SUPORTE_DISTANCIA
		new_soul.sacrifice_buff = SubjugatedSoulData.SacrificeBuffType.MANANCIAL_VAZIO
		new_soul.max_health = 105.0
		new_soul.attack_damage = 28.0
	
	new_soul.lore_description = "Espírito arrancado dos campos de batalha sob o julgamento fúnebre de Necroth."
	subjugated_souls.append(new_soul)
	emit_signal("subjugated_souls_updated")
	return new_soul

func issue_squad_order(target_pos: Vector2, order_type: String = "ATTACK_FOCUS") -> void:
	if is_instance_valid(active_guardian) and active_guardian.has_method("receive_tactical_order"):
		active_guardian.receive_tactical_order(target_pos, order_type)
	
	for servant in active_servants:
		if is_instance_valid(servant) and servant.has_method("receive_tactical_order"):
			servant.receive_tactical_order(target_pos, order_type)

func _clean_dead_servants() -> void:
	active_servants = active_servants.filter(func(s): return is_instance_valid(s) and not (s is BaseCharacter and s.is_dead))

func _on_servant_tree_exited(_servant: Node2D, soul: SubjugatedSoulData) -> void:
	if soul:
		soul.is_summoned = false
	_clean_dead_servants()
	emit_signal("servant_count_changed", active_servants.size(), max_field_servants)
	emit_signal("subjugated_souls_updated")

func _on_guardian_tree_exited() -> void:
	active_guardian = null
	emit_signal("guardian_state_changed", false)
