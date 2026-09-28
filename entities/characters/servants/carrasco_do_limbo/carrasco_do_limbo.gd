class_name CarrascoDoLimbo
extends BaseServant

## O Carrasco do Limbo: Primeiro Guardião Espectral e Comandante de Campo
## Silhueta aterrorizante com foice espectral e autoridade sobre os asseclas de Necroth.

signal cleave_attack_executed

@export_group("Combate do Carrasco")
@export var cleave_range: float = 85.0
@export var cleave_damage: float = 35.0
@export var cleave_cooldown: float = 1.4

var attack_timer: float = 0.0
var is_attacking: bool = false
var hover_time: float = 0.0

@onready var visual_scythe: Node2D = $Visual/ScythePivot
@onready var cleave_area: Area2D = $CleaveArea
@onready var aura_visual: CanvasItem = $Visual/Aura
@onready var visual_node: Node2D = $Visual

func _ready() -> void:
	character_name = "O Carrasco do Limbo"
	max_health = 280.0
	move_speed = 190.0
	attack_power = cleave_damage
	defense = 6.0
	super._ready()

func _process_servant_tactics(delta: float) -> void:
	hover_time += delta * 3.5
	if visual_node:
		visual_node.position.y = sin(hover_time) * 5.0
		if velocity.x != 0.0:
			visual_node.scale.x = 1.0 if velocity.x > 0.0 else -1.0
	
	if attack_timer > 0.0:
		attack_timer -= delta
	
	# Procurar alvos inimigos próximos
	var target_enemy: BaseCharacter = _find_nearest_enemy()
	
	if current_order_type == "ATTACK_FOCUS":
		var dist_to_target: float = global_position.distance_to(target_order_position)
		if dist_to_target > 40.0:
			var dir: Vector2 = (target_order_position - global_position).normalized()
			velocity = dir * (move_speed * 1.3) # Investida rápida
			_rotate_scythe_towards(target_order_position)
		else:
			velocity = Vector2.ZERO
			if attack_timer <= 0.0:
				execute_scythe_cleave()
			current_order_type = "FOLLOW"
	elif target_enemy:
		var dist: float = global_position.distance_to(target_enemy.global_position)
		_rotate_scythe_towards(target_enemy.global_position)
		
		if dist > cleave_range:
			var dir: Vector2 = (target_enemy.global_position - global_position).normalized()
			velocity = dir * move_speed
		else:
			velocity = Vector2.ZERO
			if attack_timer <= 0.0:
				execute_scythe_cleave()
	else:
		# Modo escolta ao redor de Necroth
		if is_instance_valid(master_node):
			var desired_pos: Vector2 = master_node.global_position + Vector2(-60, -25)
			var dist_to_master: float = global_position.distance_to(desired_pos)
			if dist_to_master > 25.0:
				var dir: Vector2 = (desired_pos - global_position).normalized()
				velocity = dir * move_speed
			else:
				velocity = velocity.move_toward(Vector2.ZERO, move_speed * 0.2)
		else:
			velocity = Vector2.ZERO

## Executa o golpe em arco da Foice de Luto
func execute_scythe_cleave() -> void:
	attack_timer = cleave_cooldown
	is_attacking = true
	emit_signal("cleave_attack_executed")
	
	# Animação de rotação da foice
	if visual_scythe:
		var tween: Tween = create_tween()
		tween.tween_property(visual_scythe, "rotation", visual_scythe.rotation + PI * 1.2, 0.25).set_trans(Tween.TRANS_BACK)
		tween.tween_property(visual_scythe, "rotation", 0.0, 0.2)
	
	# Aplica dano aos inimigos na área
	if cleave_area:
		var bodies: Array[Node2D] = cleave_area.get_overlapping_bodies()
		for body in bodies:
			if body is BaseCharacter and body != self and body.faction != faction:
				body.take_damage(attack_power, self)
				gain_experience(20.0)

func _rotate_scythe_towards(target_pos: Vector2) -> void:
	if visual_scythe:
		var angle: float = (target_pos - global_position).angle()
		visual_scythe.rotation = lerp_angle(visual_scythe.rotation, angle, 0.2)

func _find_nearest_enemy() -> BaseCharacter:
	var tree: SceneTree = get_tree()
	if not tree:
		return null
	var nodes: Array[Node] = tree.get_nodes_in_group("enemies")
	var nearest: BaseCharacter = null
	var min_dist: float = 380.0 # Raio de percepção do Carrasco
	for node in nodes:
		if node is BaseCharacter and not node.is_dead and node.faction != faction:
			var d: float = global_position.distance_to(node.global_position)
			if d < min_dist:
				min_dist = d
				nearest = node
	return nearest
