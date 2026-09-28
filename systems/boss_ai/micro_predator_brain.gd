class_name MicroPredatorBrain
extends Node

## Micro-Cérebro de Combate para Chefes e Avatares
## Executa instintos locais de visão, audição, investida pesada e golpe de choque em área.

signal phase_changed(new_phase: int)
signal ground_slam_executed(origin: Vector2, radius: float, damage: float)

enum BossPhase {
	FASE_1_CERCO,
	FASE_2_FURIA_SANGUINARIA
}

@export var current_phase: BossPhase = BossPhase.FASE_1_CERCO
@export var charge_speed: float = 380.0
@export var ground_slam_damage: float = 30.0

var boss_body: BaseCharacter = null
var macro_hint_pos: Vector2 = Vector2.ZERO
var is_charging: bool = false
var charge_direction: Vector2 = Vector2.ZERO
var charge_timer: float = 0.0
var slam_cooldown: float = 0.0

func setup(body: BaseCharacter) -> void:
	boss_body = body

func set_macro_hint(pos: Vector2) -> void:
	macro_hint_pos = pos

func update_micro_combat(delta: float, target_entity: Node2D) -> Vector2:
	if not boss_body or boss_body.is_dead:
		return Vector2.ZERO
	
	if slam_cooldown > 0.0:
		slam_cooldown -= delta
	
	# Checa transição de fase quando HP < 50%
	if current_phase == BossPhase.FASE_1_CERCO and boss_body.current_health <= (boss_body.max_health * 0.5):
		current_phase = BossPhase.FASE_2_FURIA_SANGUINARIA
		charge_speed *= 1.25
		emit_signal("phase_changed", int(current_phase))
	
	# Processamento de Investida
	if is_charging:
		charge_timer -= delta
		if charge_timer <= 0.0:
			is_charging = false
			_execute_ground_slam()
		return charge_direction * charge_speed
	
	if target_entity and is_instance_valid(target_entity):
		var dist_to_target: float = boss_body.global_position.distance_to(target_entity.global_position)
		
		# Se estiver em alcance médio e o cooldown permitir, inicia investida de ruptura
		if dist_to_target > 120.0 and dist_to_target < 400.0 and slam_cooldown <= 0.0:
			_start_charge(target_entity.global_position)
			return charge_direction * charge_speed
		
		# Perseguição direta
		var dir: Vector2 = (target_entity.global_position - boss_body.global_position).normalized()
		return dir * boss_body.move_speed
	
	# Se não vê o alvo diretamente, segue o vetor de pressão do Macro-Diretor
	if macro_hint_pos != Vector2.ZERO:
		var dist_to_hint: float = boss_body.global_position.distance_to(macro_hint_pos)
		if dist_to_hint > 40.0:
			return (macro_hint_pos - boss_body.global_position).normalized() * (boss_body.move_speed * 0.75)
	
	return Vector2.ZERO

func _start_charge(target_pos: Vector2) -> void:
	is_charging = true
	charge_direction = (target_pos - boss_body.global_position).normalized()
	charge_timer = 0.55
	slam_cooldown = 4.0 if current_phase == BossPhase.FASE_1_CERCO else 2.5

func _execute_ground_slam() -> void:
	var slam_radius: float = 140.0
	emit_signal("ground_slam_executed", boss_body.global_position, slam_radius, ground_slam_damage)
