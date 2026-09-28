class_name MacroPredatorDirector
extends Node

## Macro-Diretor Predatório (Inspirado no Diretor de Alien: Isolation)
## Conhece a posição geral de Necroth e direciona a pressão de caça sem trapacear a física.

signal pressure_target_assigned(target_area_pos: Vector2)

@export var evaluation_interval: float = 3.0
@export var stalking_proximity_offset: float = 240.0

var target_player: Node2D = null
var current_boss: Node2D = null
var eval_timer: float = 0.0

func _ready() -> void:
	eval_timer = evaluation_interval

func _physics_process(delta: float) -> void:
	eval_timer -= delta
	if eval_timer <= 0.0:
		eval_timer = evaluation_interval
		_evaluate_hunt_pressure()

func setup_hunt(boss: Node2D, player: Variant = null) -> void:
	current_boss = boss
	if is_instance_valid(player) and player is Node2D:
		target_player = player as Node2D
	else:
		target_player = null
		_evaluate_hunt_pressure()

func _evaluate_hunt_pressure() -> void:
	if not target_player or not is_instance_valid(target_player):
		var players: Array[Node] = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target_player = players[0] as Node2D
		else:
			return
	
	if not current_boss or not is_instance_valid(current_boss):
		return
	
	# Calcula uma posição de cerco/pressão próxima de Necroth, antecipando sua movimentação
	var player_pos: Vector2 = target_player.global_position
	var lead_offset: Vector2 = Vector2.ZERO
	if target_player is CharacterBody2D:
		lead_offset = target_player.velocity.normalized() * stalking_proximity_offset
	
	var pressure_pos: Vector2 = player_pos + lead_offset
	emit_signal("pressure_target_assigned", pressure_pos)
