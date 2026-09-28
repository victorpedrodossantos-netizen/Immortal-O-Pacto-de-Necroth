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
@export var max_field_servants: int = 3

var active_guardian: Node2D = null
var active_servants: Array[Node2D] = []
var subjugated_souls: Array[SubjugatedSoulData] = []

var quick_slot_1: SubjugatedSoulData = null
var quick_slot_2: SubjugatedSoulData = null

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
	
	# Alma 1: Guerreiro de Choque
	var s1: SubjugatedSoulData = SubjugatedSoulData.new()
	s1.id = "gareth_choque"
	s1.soldier_name = "Gareth, O Rompe-Escudos"
	s1.soul_class = SubjugatedSoulData.SoulClass.TROPA_CHOQUE
	s1.faction = GameEnums.Faction.FENDIDOS_DE_FERRO
	s1.max_health = 180.0
	s1.attack_damage = 24.0
	s1.move_speed = 175.0
	s1.sacrifice_buff = SubjugatedSoulData.SacrificeBuffType.COURAÇA_FERRO
	s1.lore_description = "Guardião veterano que protege seu mestre com barreiras de ferro e cinzas."
	subjugated_souls.append(s1)
	quick_slot_1 = s1
	
	# Alma 2: Flanqueador Ágil
	var s2: SubjugatedSoulData = SubjugatedSoulData.new()
	s2.id = "kael_flanqueador"
	s2.soldier_name = "Kael, Lâmina Espectral"
	s2.soul_class = SubjugatedSoulData.SoulClass.FLANQUEADOR
	s2.faction = GameEnums.Faction.PACTO_NECROTH
	s2.max_health = 120.0
	s2.attack_damage = 32.0
	s2.move_speed = 230.0
	s2.sacrifice_buff = SubjugatedSoulData.SacrificeBuffType.PASSO_FANTASMA
	s2.lore_description = "Assassino das fendas umbrais veloz como o próprio sopro do Limbo."
	subjugated_souls.append(s2)
	quick_slot_2 = s2
	
	# Alma 3: Taumaturgo de Suporte
	var s3: SubjugatedSoulData = SubjugatedSoulData.new()
	s3.id = "mulgath_mago"
	s3.soldier_name = "Mulgath, Piromante do Limbo"
	s3.soul_class = SubjugatedSoulData.SoulClass.SUPORTE_DISTANCIA
	s3.faction = GameEnums.Faction.PUTRIDOS_DO_LIMO
	s3.max_health = 100.0
	s3.attack_damage = 26.0
	s3.move_speed = 185.0
	s3.sacrifice_buff = SubjugatedSoulData.SacrificeBuffType.MANANCIAL_VAZIO
	s3.lore_description = "Canalizador de fogo fátuo e vapores corrosivos à longa distância."
	subjugated_souls.append(s3)
	
	emit_signal("subjugated_souls_updated")

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
	
	# Remove a alma consumida do inventário
	subjugated_souls.erase(soul)
	if quick_slot_1 == soul: quick_slot_1 = null
	if quick_slot_2 == soul: quick_slot_2 = null
	
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
