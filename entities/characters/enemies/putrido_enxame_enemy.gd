class_name PutridoEnxameEnemy
extends BaseCharacter

## Pútridos do Limo (Ghûls Noturnos)
## Criaturas rastejantes necróticas do Pântano do Limo.
## Sistema de Percepção Sensorial e Faro estilo Alien: Isolation.

const SOUL_DROP_SCENE: PackedScene = preload("res://entities/items/soul_drop_2d.tscn")

@export var leap_damage: float = 18.0
@export var leap_range: float = 160.0
@export var leap_cooldown: float = 2.0

var leap_timer: float = 0.0
var is_leaping: bool = false
var leap_target_pos: Vector2 = Vector2.ZERO
var spawn_home_position: Vector2 = Vector2.ZERO
var swamp_wander_timer: float = 0.0
var wander_direction: Vector2 = Vector2.ZERO

@onready var visual_root: Node2D = $Visual
@onready var eyes_visual: Polygon2D = $Visual/EyesGlow
@onready var sensor: PerceptionSensor2D = $PerceptionSensor2D
@onready var indicator: AlertIndicator2D = $AlertIndicator2D

func _ready() -> void:
	character_name = "Pútrido do Limo"
	faction = GameEnums.Faction.PUTRIDOS_DO_LIMO
	max_health = 55.0
	move_speed = 265.0
	defense = 1.0
	spawn_home_position = global_position
	super._ready()
	
	if sensor:
		sensor.alert_level_changed.connect(_on_alert_level_changed)
		sensor.target_spotted.connect(_on_target_spotted)
		sensor.target_lost.connect(_on_target_lost)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	if leap_timer > 0.0:
		leap_timer -= delta
	
	_process_ghul_tactics(delta)
	move_and_slide()

func _process_ghul_tactics(delta: float) -> void:
	var alert: GameEnums.AlertLevel = sensor.current_alert if sensor else GameEnums.AlertLevel.CALMO
	
	match alert:
		GameEnums.AlertLevel.CALMO:
			_process_calm_swamp_wander(delta)
		GameEnums.AlertLevel.SUSPEITO, GameEnums.AlertLevel.INVESTIGANDO:
			_process_investigating(delta)
		GameEnums.AlertLevel.BUSCA_CAUTELOSA:
			_process_cautious_search(delta)
		GameEnums.AlertLevel.COMBATE_ATIVO:
			_process_active_combat(delta)

## Estado Calmo: Rasteja sinuosamente pelas águas do Pântano do Limo
func _process_calm_swamp_wander(delta: float) -> void:
	swamp_wander_timer -= delta
	if swamp_wander_timer <= 0.0:
		swamp_wander_timer = randf_range(2.5, 4.5)
		var dist_home: float = global_position.distance_to(spawn_home_position)
		if dist_home > 200.0:
			wander_direction = (spawn_home_position - global_position).normalized()
		else:
			wander_direction = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	
	var crawl_speed: float = move_speed * 0.35
	var wave: Vector2 = Vector2(-wander_direction.y, wander_direction.x) * sin(Time.get_ticks_msec() * 0.005) * 20.0
	velocity = (wander_direction * crawl_speed) + wave
	_orient_visual(wander_direction)

## Estado Suspeito/Investigando: Fareja e rasteja cautelosamente em direção ao som/passos
func _process_investigating(_delta: float) -> void:
	if not sensor:
		return
	
	var investigate_pos: Vector2 = sensor.last_known_position
	var dist: float = global_position.distance_to(investigate_pos)
	
	if dist > 35.0:
		var to_pos: Vector2 = (investigate_pos - global_position).normalized()
		var stalk_speed: float = move_speed * 0.55
		var wave: Vector2 = Vector2(-to_pos.y, to_pos.x) * sin(Time.get_ticks_msec() * 0.007) * 25.0
		velocity = (to_pos * stalk_speed) + wave
		_orient_visual(to_pos)
	else:
		velocity = Vector2.ZERO

## Estado Busca Cautelosa: Fareja a área onde o alvo foi visto por último
func _process_cautious_search(_delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, move_speed * 0.2)

## Estado Combate Ativo: Alvo confirmado dentro do raio de percepção sensorial
func _process_active_combat(_delta: float) -> void:
	var target: Node2D = sensor.current_target if sensor else null
	if not target or not is_instance_valid(target):
		return
	
	var dist: float = global_position.distance_to(target.global_position)
	var to_target: Vector2 = (target.global_position - global_position).normalized()
	_orient_visual(to_target)
	
	if is_leaping:
		velocity = (leap_target_pos - global_position).normalized() * (move_speed * 2.2)
		if global_position.distance_to(leap_target_pos) < 30.0:
			is_leaping = false
			velocity = Vector2.ZERO
			_apply_leap_damage()
	else:
		if dist <= leap_range and leap_timer <= 0.0:
			_start_leap(target.global_position)
		else:
			# Movimentação sinuosa agressiva de matilha
			var wave: Vector2 = Vector2(-to_target.y, to_target.x) * sin(Time.get_ticks_msec() * 0.008) * 40.0
			velocity = (to_target * move_speed) + wave

func _orient_visual(dir: Vector2) -> void:
	if visual_root and dir.x != 0.0:
		visual_root.scale.x = -1.0 if dir.x < 0 else 1.0
	if sensor and dir != Vector2.ZERO:
		sensor.global_rotation = dir.angle()

func _start_leap(target_pos: Vector2) -> void:
	is_leaping = true
	leap_target_pos = target_pos
	leap_timer = leap_cooldown
	AudioManager.play_sfx(AudioManager.stream_hit, 1.4)
	
	if visual_root:
		var tween: Tween = create_tween()
		tween.tween_property(visual_root, "scale", Vector2(1.3, 0.7), 0.1)
		tween.tween_property(visual_root, "scale", Vector2.ONE, 0.15)

func _apply_leap_damage() -> void:
	var target: Node2D = sensor.current_target if sensor else null
	if is_instance_valid(target) and target is BaseCharacter:
		var d: float = global_position.distance_to(target.global_position)
		if d <= 70.0:
			target.take_damage(leap_damage, self)

func _on_alert_level_changed(new_level: GameEnums.AlertLevel) -> void:
	if indicator:
		indicator.update_alert(new_level)
	if eyes_visual:
		match new_level:
			GameEnums.AlertLevel.COMBATE_ATIVO:
				eyes_visual.color = Color(1.0, 0.2, 0.1, 1.0) # Olhos vermelhos famintos
			GameEnums.AlertLevel.INVESTIGANDO, GameEnums.AlertLevel.SUSPEITO:
				eyes_visual.color = Color(1.0, 0.8, 0.2, 1.0) # Olhos amarelados em alerta
			_:
				eyes_visual.color = Color(0.4, 0.9, 0.5, 0.6) # Olhos verde-lodo opacos

func _on_target_spotted(target: Node2D) -> void:
	AudioManager.play_sfx(AudioManager.stream_hit, 1.2)

func _on_target_lost(_last_pos: Vector2) -> void:
	pass

func take_damage(amount: float, source: Node = null) -> float:
	var dmg: float = super.take_damage(amount, source)
	if sensor and is_instance_valid(source) and source is Node2D:
		sensor.hear_noise((source as Node2D).global_position, 2.5)
	return dmg

func die(killer: Node = null) -> void:
	var drop: SoulDrop2D = SOUL_DROP_SCENE.instantiate()
	drop.global_position = global_position
	drop.source_enemy_name = "Pútrido do Enxame"
	drop.source_faction = faction
	var cur_scene: Node = get_tree().current_scene
	if cur_scene:
		cur_scene.call_deferred("add_child", drop)
	
	super.die(killer)
	queue_free()
