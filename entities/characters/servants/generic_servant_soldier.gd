class_name GenericServantSoldier
extends BaseServant

const SubjugatedSoulData = preload("res://resources/subjugated_soul_data.gd")

## Soldado Espectral Subjulgado
## Entidade invocada do Grimório dos Condenados para lutar pelo Pacto de Necroth.

signal attack_performed

var soul_data: SubjugatedSoulData = null
var attack_timer: float = 0.0
var attack_cooldown: float = 1.2
var attack_range: float = 75.0

@onready var visual_root: Node2D = $Visual
@onready var weapon_visual: Node2D = $Visual/Weapon
@onready var aura_visual: CanvasItem = $Visual/Aura
@onready var hp_label: Label = $Visual/NameLabel

func setup_from_soul(data: SubjugatedSoulData, master: Node2D) -> void:
	soul_data = data
	character_name = data.soldier_name
	max_health = data.max_health
	current_health = max_health
	attack_power = data.attack_damage
	move_speed = data.move_speed
	defense = 5.0 if data.soul_class == SubjugatedSoulData.SoulClass.TROPA_CHOQUE else 2.0
	
	if data.soul_class == SubjugatedSoulData.SoulClass.SUPORTE_DISTANCIA:
		attack_range = 320.0
		attack_cooldown = 1.8
	elif data.soul_class == SubjugatedSoulData.SoulClass.FLANQUEADOR:
		attack_range = 65.0
		attack_cooldown = 0.8
		move_speed *= 1.25
	
	if data.is_group_captain or data.soul_class == SubjugatedSoulData.SoulClass.COMANDANTE:
		max_health *= 1.4
		current_health = max_health
		attack_power *= 1.3
		defense += 5.0
	
	set_commander_master(master)
	_update_appearance()

func _ready() -> void:
	super._ready()
	_update_appearance()

func _update_appearance() -> void:
	if not visual_root or not soul_data:
		return
	
	var is_cap: bool = soul_data.is_group_captain or soul_data.soul_class == SubjugatedSoulData.SoulClass.COMANDANTE
	if is_cap:
		visual_root.scale = Vector2(1.3, 1.3)
	else:
		visual_root.scale = Vector2(1.0, 1.0)
	
	if hp_label:
		if is_cap:
			hp_label.text = "👑 %s" % soul_data.soldier_name
		else:
			hp_label.text = soul_data.soldier_name
	
	if aura_visual:
		if is_cap:
			aura_visual.modulate = Color(1.0, 0.84, 0.2, 0.95) # Dourado régio de Capitão
		else:
			match soul_data.soul_class:
				SubjugatedSoulData.SoulClass.TROPA_CHOQUE:
					aura_visual.modulate = Color(0.2, 0.7, 1.0, 0.7) # Azul blindado
				SubjugatedSoulData.SoulClass.FLANQUEADOR:
					aura_visual.modulate = Color(0.8, 0.2, 0.9, 0.7) # Roxo furtivo
				SubjugatedSoulData.SoulClass.SUPORTE_DISTANCIA:
					aura_visual.modulate = Color(0.145, 0.886, 0.596, 0.7) # Verde éter
				_:
					aura_visual.modulate = Color(0.9, 0.9, 0.9, 0.6)

func _process_servant_tactics(delta: float) -> void:
	if attack_timer > 0.0:
		attack_timer -= delta
	
	var nearest_enemy: BaseCharacter = _find_nearest_enemy()
	
	# Ordem Tática de Foco
	if current_order_type == "ATTACK_FOCUS":
		var dist_to_target: float = global_position.distance_to(target_order_position)
		if dist_to_target > 40.0:
			velocity = (target_order_position - global_position).normalized() * (move_speed * 1.2)
		else:
			velocity = Vector2.ZERO
			current_order_type = "FOLLOW"
		return
	
	# Se há inimigo no campo de batalha
	if nearest_enemy:
		var dist_to_enemy: float = global_position.distance_to(nearest_enemy.global_position)
		var to_enemy: Vector2 = (nearest_enemy.global_position - global_position).normalized()
		
		# Suporte à distância mantém distância de segurança
		if soul_data and soul_data.soul_class == SubjugatedSoulData.SoulClass.SUPORTE_DISTANCIA:
			if dist_to_enemy < 180.0:
				velocity = -to_enemy * (move_speed * 0.8) # Recua
			elif dist_to_enemy > attack_range:
				velocity = to_enemy * move_speed
			else:
				velocity = Vector2.ZERO
				if attack_timer <= 0.0:
					_execute_ranged_strike(nearest_enemy)
		else:
			# Melee: Choque ou Flanqueador
			if dist_to_enemy > attack_range:
				velocity = to_enemy * move_speed
			else:
				velocity = Vector2.ZERO
				if attack_timer <= 0.0:
					_execute_melee_strike(nearest_enemy)
		
		if visual_root:
			visual_root.scale.x = -1.0 if to_enemy.x < 0 else 1.0
	else:
		# Sem inimigos próximos: escolta o mestre (Necroth ou Carrasco)
		super._process_servant_tactics(delta)

func _execute_melee_strike(target: BaseCharacter) -> void:
	attack_timer = attack_cooldown
	if weapon_visual:
		var tween: Tween = create_tween()
		tween.tween_property(weapon_visual, "rotation", weapon_visual.rotation + 1.2, 0.12)
		tween.tween_property(weapon_visual, "rotation", 0.0, 0.12)
	
	AudioManager.play_sfx(AudioManager.stream_hit, 1.2)
	target.take_damage(attack_power, self)
	emit_signal("attack_performed")

func _execute_ranged_strike(target: BaseCharacter) -> void:
	attack_timer = attack_cooldown
	AudioManager.play_sfx(AudioManager.stream_cast, 1.4)
	# Dispara feitiço de fogo fátuo direto no inimigo
	var to_target: Vector2 = (target.global_position - global_position).normalized()
	var flash_tween: Tween = create_tween()
	flash_tween.tween_property(visual_root, "modulate", Color(0.2, 1.8, 0.8, 1.0), 0.1)
	flash_tween.tween_property(visual_root, "modulate", Color(1, 1, 1, 1), 0.15)
	target.take_damage(attack_power * 1.2, self)
	emit_signal("attack_performed")

func _find_nearest_enemy() -> BaseCharacter:
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	var nearest: BaseCharacter = null
	var min_dist: float = 600.0
	
	for e in enemies:
		if e is BaseCharacter and not e.is_dead and e.faction != faction:
			var d: float = global_position.distance_to(e.global_position)
			if d < min_dist:
				min_dist = d
				nearest = e
	return nearest

func die(killer: Node = null) -> void:
	if soul_data:
		soul_data.is_summoned = false
	EventBus.servant_fallen.emit(self)
	super.die(killer)
	queue_free()
