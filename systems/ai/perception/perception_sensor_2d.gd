class_name PerceptionSensor2D
extends Area2D

## Sensor de Percepção Sensorial (Visão Cônica + Audição MGS V / F.E.A.R.)

signal alert_level_changed(new_level: GameEnums.AlertLevel)
signal target_spotted(target: Node2D)
signal target_lost(last_known_pos: Vector2)

@export_group("Visão")
@export var vision_range: float = 460.0
@export var field_of_view_deg: float = 95.0
@export var detection_speed: float = 90.0 # Pontos de suspeita por segundo
@export var immediate_proximity_radius: float = 75.0 # Sentido imediato de 360° (toque/presença pelas costas)
@export var leash_distance: float = 650.0 # Distância máxima de perseguição antes de desistir

@export_group("Audição")
@export var hearing_range: float = 320.0

var current_alert: GameEnums.AlertLevel = GameEnums.AlertLevel.CALMO
var suspicion_meter: float = 0.0 # 0 a 100
var current_target: Node2D = null
var last_known_position: Vector2 = Vector2.ZERO
var search_timer: float = 0.0

@onready var raycast: RayCast2D = $RayCast2D

func _ready() -> void:
	if not raycast:
		raycast = RayCast2D.new()
		add_child(raycast)
	raycast.enabled = true
	raycast.collision_mask = 1 | 2 # Colide com cenário e personagens

func _physics_process(delta: float) -> void:
	_scan_for_targets(delta)
	_handle_alert_decay(delta)

## Escaneia alvos potenciais (criaturas de outra facção, jogador ou servos de Necroth)
func _scan_for_targets(delta: float) -> void:
	var my_char: BaseCharacter = get_parent() as BaseCharacter
	var my_faction: GameEnums.Faction = my_char.faction if my_char else GameEnums.Faction.FENDIDOS_DE_FERRO
	var is_servant: bool = (my_char != null and my_char.is_in_group("servants")) or my_faction == GameEnums.Faction.PACTO_NECROTH
	
	var potential_targets: Array[Node] = []
	if is_servant:
		# Servos no exército de Necroth atacam unicamente inimigos selvagens (não atacam outros servos nem o jogador)
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if enemy != my_char and is_instance_valid(enemy) and not enemy.is_in_group("servants"):
				potential_targets.append(enemy)
	else:
		# Criaturas selvagens atacam o jogador e seus asseclas
		potential_targets.append_array(get_tree().get_nodes_in_group("player"))
		potential_targets.append_array(get_tree().get_nodes_in_group("servants"))
		
		# Hostilidade entre espécies selvagens: Orcs vs Ghûls vs Ologs/Trolls
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if enemy != my_char and is_instance_valid(enemy) and enemy is BaseCharacter:
				if not enemy.is_dead and enemy.faction != my_faction:
					potential_targets.append(enemy)
	
	var target_visible: bool = false
	
	for target in potential_targets:
		var node_2d: Node2D = target as Node2D
		if not node_2d or not is_instance_valid(node_2d):
			continue
		if node_2d is BaseCharacter and node_2d.is_dead:
			continue
		
		var dist: float = global_position.distance_to(node_2d.global_position)
		if current_alert == GameEnums.AlertLevel.COMBATE_ATIVO and dist > leash_distance:
			continue
		
		var in_vision_cone: bool = false
		if dist <= vision_range:
			var facing_dir: Vector2 = Vector2.RIGHT.rotated(global_rotation)
			var to_target: Vector2 = (node_2d.global_position - global_position).normalized()
			var angle_deg: float = rad_to_deg(facing_dir.angle_to(to_target))
			if absf(angle_deg) <= (field_of_view_deg * 0.5):
				in_vision_cone = true
		
		var in_immediate_proximity: bool = (dist <= immediate_proximity_radius)
		
		if in_vision_cone or in_immediate_proximity:
			# Checa oclusão de visão com RayCast
			raycast.global_position = global_position
			raycast.target_position = raycast.to_local(node_2d.global_position)
			raycast.force_raycast_update()
			
			var collider: Object = raycast.get_collider()
			if collider == node_2d or collider == null or (collider is BaseCharacter and (collider as BaseCharacter).faction != my_faction):
				target_visible = true
				current_target = node_2d
				last_known_position = node_2d.global_position
				var suspicion_factor: float = 2.5 if in_immediate_proximity else (1.0 + (1.0 - dist / vision_range))
				_increase_suspicion(delta * suspicion_factor)
				break
	
	if not target_visible and current_alert == GameEnums.AlertLevel.COMBATE_ATIVO:
		# Perdeu a linha direta de visão
		_transition_to_cautious_search()

func _increase_suspicion(amount: float) -> void:
	suspicion_meter = minf(100.0, suspicion_meter + amount * detection_speed)
	
	if suspicion_meter >= 100.0 and current_alert != GameEnums.AlertLevel.COMBATE_ATIVO:
		if is_instance_valid(current_target):
			_set_alert(GameEnums.AlertLevel.COMBATE_ATIVO)
			emit_signal("target_spotted", current_target)
		else:
			suspicion_meter = 95.0
			_set_alert(GameEnums.AlertLevel.INVESTIGANDO)
	elif suspicion_meter >= 70.0 and current_alert != GameEnums.AlertLevel.INVESTIGANDO:
		_set_alert(GameEnums.AlertLevel.INVESTIGANDO)
	elif suspicion_meter >= 40.0 and current_alert == GameEnums.AlertLevel.CALMO:
		_set_alert(GameEnums.AlertLevel.SUSPEITO)

func _transition_to_cautious_search() -> void:
	_set_alert(GameEnums.AlertLevel.BUSCA_CAUTELOSA)
	search_timer = 5.0 # Procura por 5 segundos antes de acalmar
	emit_signal("target_lost", last_known_position)

func _handle_alert_decay(delta: float) -> void:
	if current_alert == GameEnums.AlertLevel.BUSCA_CAUTELOSA:
		search_timer -= delta
		if search_timer <= 0.0:
			suspicion_meter = 0.0
			current_target = null
			_set_alert(GameEnums.AlertLevel.CALMO)
	elif current_alert != GameEnums.AlertLevel.COMBATE_ATIVO and suspicion_meter > 0.0:
		suspicion_meter = maxf(0.0, suspicion_meter - delta * 25.0)
		if suspicion_meter < 30.0 and current_alert != GameEnums.AlertLevel.CALMO:
			_set_alert(GameEnums.AlertLevel.CALMO)

func _set_alert(new_level: GameEnums.AlertLevel) -> void:
	if current_alert != new_level:
		current_alert = new_level
		emit_signal("alert_level_changed", current_alert)

## Reage a ruídos produzidos pelo jogador ou magias
func hear_noise(noise_position: Vector2, intensity: float = 1.0) -> void:
	var dist: float = global_position.distance_to(noise_position)
	if dist <= (hearing_range * intensity):
		last_known_position = noise_position
		if current_alert != GameEnums.AlertLevel.COMBATE_ATIVO:
			if suspicion_meter < 75.0:
				suspicion_meter = 75.0
			_set_alert(GameEnums.AlertLevel.INVESTIGANDO)
