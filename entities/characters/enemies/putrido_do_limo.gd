class_name PutridoDoLimo
extends BaseCharacter

## Pútrido do Limo: Rastejante necrótico noturno de emboscada rápida (equivalente a Ghûl)

const SOUL_DROP_SCENE: PackedScene = preload("res://entities/items/soul_drop_2d.tscn")

@export var leap_damage: float = 22.0
@export var leap_range: float = 160.0
@export var leap_cooldown: float = 2.0

var is_night_buffed: bool = false
var is_leaping: bool = false
var leap_timer: float = 0.0
var leap_direction: Vector2 = Vector2.ZERO
var attack_cooldown_timer: float = 0.0

@onready var visual_root: Node2D = $Visual
@onready var sensor: PerceptionSensor2D = $PerceptionSensor2D
@onready var indicator: AlertIndicator2D = $AlertIndicator2D

func _ready() -> void:
	character_name = "Pútrido do Limo"
	faction = GameEnums.Faction.PUTRIDOS_DO_LIMO
	max_health = 65.0
	move_speed = 210.0
	attack_power = leap_damage
	defense = 1.0
	super._ready()
	add_to_group("enemies")
	
	if sensor:
		sensor.alert_level_changed.connect(_on_alert_changed)

## Aplica bônus de agressividade e velocidade na ausência de luz
func set_night_buff(active: bool) -> void:
	if is_night_buffed == active:
		return
	is_night_buffed = active
	if is_night_buffed:
		move_speed = 285.0
		attack_power = leap_damage * 1.3
		if visual_root:
			visual_root.modulate = Color(0.3, 1.2, 0.6) # Brilho bioluminescente aumentado
	else:
		move_speed = 210.0
		attack_power = leap_damage
		if visual_root:
			visual_root.modulate = Color(1.0, 1.0, 1.0)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= delta
	
	if is_leaping:
		leap_timer -= delta
		velocity = leap_direction * (move_speed * 2.2)
		if leap_timer <= 0.0:
			is_leaping = false
			_check_leap_impact()
	else:
		_process_chase(delta)
	
	move_and_slide()

func _process_chase(_delta: float) -> void:
	var target: Node2D = sensor.current_target if sensor else null
	if not target or not is_instance_valid(target):
		velocity = velocity.move_toward(Vector2.ZERO, move_speed * 0.1)
		return
	
	var dist: float = global_position.distance_to(target.global_position)
	var dir: Vector2 = (target.global_position - global_position).normalized()
	
	if visual_root:
		visual_root.scale.x = -1.0 if dir.x < 0 else 1.0
	
	# Bote de Lodo
	if dist <= leap_range and dist > 40.0 and attack_cooldown_timer <= 0.0:
		_start_leap(dir)
	elif dist > 35.0:
		velocity = dir * move_speed
	else:
		velocity = Vector2.ZERO
		if attack_cooldown_timer <= 0.0:
			_perform_claw_bite(target)

func _start_leap(dir: Vector2) -> void:
	is_leaping = true
	leap_direction = dir
	leap_timer = 0.28
	attack_cooldown_timer = leap_cooldown

func _check_leap_impact() -> void:
	var targets: Array[Node] = get_tree().get_nodes_in_group("player") + get_tree().get_nodes_in_group("servants")
	for t in targets:
		if t is BaseCharacter and not t.is_dead and t.faction != faction:
			if global_position.distance_to(t.global_position) <= 50.0:
				t.take_damage(attack_power, self)

func _perform_claw_bite(target: Node2D) -> void:
	attack_cooldown_timer = 1.0
	if target is BaseCharacter:
		target.take_damage(attack_power * 0.7, self)

func _on_alert_changed(lvl: GameEnums.AlertLevel) -> void:
	if indicator:
		indicator.update_alert(lvl)

func _on_death(_killer: Node) -> void:
	var drop: SoulDrop2D = SOUL_DROP_SCENE.instantiate()
	drop.global_position = global_position
	var soul: SoulData = SoulData.new()
	soul.id = "alma_putrido_menor"
	soul.soul_name = "Centelha de Pútrido"
	soul.origin_faction = GameEnums.Faction.PUTRIDOS_DO_LIMO
	soul.energy_value = 18.0
	drop.soul_data = soul
	
	var cur_scene: Node = get_tree().current_scene
	if cur_scene:
		cur_scene.call_deferred("add_child", drop)
	
	queue_free()
