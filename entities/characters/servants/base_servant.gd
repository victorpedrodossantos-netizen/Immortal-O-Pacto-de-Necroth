class_name BaseServant
extends BaseCharacter

## Classe base para todos os asseclas e guardiões do exército de Necroth

signal servant_leveled_up(new_level: int)

@export_group("Comando & Vínculo")
@export var follow_distance: float = 90.0
@export var tether_max_distance: float = 650.0

@export_group("Evolução Espectral")
@export var level: int = 1
@export var experience: float = 0.0
@export var exp_to_next_level: float = 100.0

var master_node: Node2D = null
var current_order_type: String = "FOLLOW"
var target_order_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	faction = GameEnums.Faction.PACTO_NECROTH
	super._ready()

func set_commander_master(new_master: Node2D) -> void:
	master_node = new_master

func receive_tactical_order(target_pos: Vector2, order_type: String) -> void:
	target_order_position = target_pos
	current_order_type = order_type

## Absorve experiência ou essência secundária de inimigos derrotados
func gain_experience(amount: float) -> void:
	experience += amount
	if experience >= exp_to_next_level:
		experience -= exp_to_next_level
		level += 1
		exp_to_next_level *= 1.35
		max_health += 25.0
		attack_power += 5.0
		current_health = max_health
		emit_signal("servant_leveled_up", level)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_process_servant_tactics(delta)
	move_and_slide()

## Sobrescrito para lógica de combate e movimentação específica de cada servo
func _process_servant_tactics(_delta: float) -> void:
	if current_order_type == "FOLLOW" and is_instance_valid(master_node):
		var dist: float = global_position.distance_to(master_node.global_position)
		if dist > follow_distance:
			var dir: Vector2 = (master_node.global_position - global_position).normalized()
			velocity = dir * move_speed
		else:
			velocity = velocity.move_toward(Vector2.ZERO, move_speed * 0.15)
