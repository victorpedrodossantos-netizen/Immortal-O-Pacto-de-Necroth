class_name TacticalDirector2D
extends Node2D

## Diretor Tático de Batalha (Inspirado no Posicionamento Tático de PES/FIFA e F.E.A.R.)
## Gerencia linhas de flanqueamento, slots orbitais de ataque e distribuição de tokens de ação.

signal tactical_bark_issued(speaker_name: String, bark_text: String)

enum SlotType {
	CHOQUE_FRONTAL,
	FLANCO_ESQUERDO,
	FLANCO_DIREITO,
	CERCO_RETAGUARDA,
	ANEL_CONTENCAO
}

@export var max_attack_tokens: int = 2
@export var target_node: Node2D = null

var available_tokens: int = 2
var registered_squad: Array[Node2D] = []
var slot_assignments: Dictionary = {} # { unit: SlotType }
var token_holders: Array[Node2D] = []
var bark_cooldown: float = 0.0

func _ready() -> void:
	available_tokens = max_attack_tokens

func _physics_process(delta: float) -> void:
	if bark_cooldown > 0.0:
		bark_cooldown -= delta
	
	if not target_node or not is_instance_valid(target_node):
		_find_primary_target()
	
	_clean_dead_units()
	_update_slot_assignments()

func _find_primary_target() -> void:
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target_node = players[0] as Node2D

func register_unit(unit: Variant) -> void:
	if not is_instance_valid(unit):
		return
	if not registered_squad.has(unit):
		registered_squad.append(unit)
		_assign_best_slot(unit)

func unregister_unit(unit: Variant) -> void:
	registered_squad.erase(unit)
	slot_assignments.erase(unit)
	token_holders.erase(unit)

func _clean_dead_units() -> void:
	for i in range(registered_squad.size() - 1, -1, -1):
		var unit: Variant = registered_squad[i]
		if not is_instance_valid(unit):
			registered_squad.remove_at(i)
		elif unit.has_method("is_dead") and unit.is_dead:
			unregister_unit(unit)
	
	for i in range(token_holders.size() - 1, -1, -1):
		if not is_instance_valid(token_holders[i]):
			token_holders.remove_at(i)
	
	for key in slot_assignments.keys():
		if not is_instance_valid(key):
			slot_assignments.erase(key)

## Distribuição de papéis e posições orbitais ao redor do alvo principal
func _assign_best_slot(unit: Variant) -> void:
	if not is_instance_valid(unit):
		return
	var used_slots: Array = slot_assignments.values()
	
	if not used_slots.has(SlotType.CHOQUE_FRONTAL):
		slot_assignments[unit] = SlotType.CHOQUE_FRONTAL
	elif not used_slots.has(SlotType.FLANCO_ESQUERDO):
		slot_assignments[unit] = SlotType.FLANCO_ESQUERDO
		trigger_bark("Incursor Fendido", "Fechando o flanco esquerdo! Não o deixem conjurar!")
	elif not used_slots.has(SlotType.FLANCO_DIREITO):
		slot_assignments[unit] = SlotType.FLANCO_DIREITO
		trigger_bark("Incursor Fendido", "Contornando pela direita! Cortem a fuga dele!")
	elif not used_slots.has(SlotType.CERCO_RETAGUARDA):
		slot_assignments[unit] = SlotType.CERCO_RETAGUARDA
	else:
		slot_assignments[unit] = SlotType.ANEL_CONTENCAO

func _update_slot_assignments() -> void:
	# Reavalia alocação se unidades tombarem
	for unit in registered_squad:
		if is_instance_valid(unit) and not slot_assignments.has(unit):
			_assign_best_slot(unit)

func is_squad_in_combat() -> bool:
	for unit in registered_squad:
		if is_instance_valid(unit) and unit.has_node("PerceptionSensor2D"):
			var sensor = unit.get_node("PerceptionSensor2D")
			if sensor.current_alert == GameEnums.AlertLevel.COMBATE_ATIVO:
				return true
	return false

func alert_squad(target: Node2D, caller: Node2D) -> void:
	if not is_instance_valid(target):
		return
	var target_pos: Vector2 = target.global_position
	for unit in registered_squad:
		if is_instance_valid(unit) and unit != caller and unit.has_node("PerceptionSensor2D"):
			var sensor = unit.get_node("PerceptionSensor2D")
			if sensor.current_alert != GameEnums.AlertLevel.COMBATE_ATIVO:
				sensor.hear_noise(target_pos, 2.5)

## Retorna a coordenada tática no mundo para onde a unidade deve se mover
func get_slot_position(unit: Variant) -> Vector2:
	if not is_instance_valid(unit):
		return global_position
	
	# Se nenhum membro do esquadrão confirmou o alvo, mantém a posição de guarda/patrulha
	if not is_squad_in_combat():
		if "spawn_home_position" in unit and unit.spawn_home_position != Vector2.ZERO:
			return unit.spawn_home_position
		return (unit as Node2D).global_position
	
	if not target_node or not is_instance_valid(target_node):
		return (unit as Node2D).global_position
	
	var target_pos: Vector2 = target_node.global_position
	var base_angle: float = 0.0
	
	# Se a unidade tem um vetor de referência ou o alvo está se movendo
	if target_node is CharacterBody2D and target_node.velocity != Vector2.ZERO:
		base_angle = target_node.velocity.angle()
	
	var slot: SlotType = slot_assignments.get(unit, SlotType.ANEL_CONTENCAO)
	var radius: float = 120.0
	var angle_offset: float = 0.0
	
	match slot:
		SlotType.CHOQUE_FRONTAL:
			radius = 95.0
			angle_offset = 0.0
		SlotType.FLANCO_ESQUERDO:
			radius = 135.0
			angle_offset = 1.25 # ~72 graus
		SlotType.FLANCO_DIREITO:
			radius = 135.0
			angle_offset = -1.25
		SlotType.CERCO_RETAGUARDA:
			radius = 150.0
			angle_offset = PI
		SlotType.ANEL_CONTENCAO:
			radius = 210.0
			angle_offset = registered_squad.find(unit) * 1.1
	
	var final_angle: float = base_angle + angle_offset
	return target_pos + Vector2(cos(final_angle), sin(final_angle)) * radius

## Sistema de Tokens de Ataque: Unidades solicitam permissão para golpear
func request_attack_token(unit: Variant) -> bool:
	if not is_instance_valid(unit):
		return false
	if token_holders.has(unit):
		return true
	
	if token_holders.size() < max_attack_tokens:
		token_holders.append(unit)
		return true
	return false

func release_attack_token(unit: Variant) -> void:
	token_holders.erase(unit)

## Emite gritos de batalha contextuais diegéticos
func trigger_bark(speaker: String, text: String) -> void:
	if bark_cooldown <= 0.0:
		bark_cooldown = 4.0
		emit_signal("tactical_bark_issued", speaker, text)
