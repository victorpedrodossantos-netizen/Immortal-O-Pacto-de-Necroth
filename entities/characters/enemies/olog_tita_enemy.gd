class_name OlogTitaEnemy
extends BaseCharacter

## Olog das Profundezas: Bruto Colossal de Pedra
## Inspirado nos Olog-hai de Shadow of War e Trolls de Pedra de God of War.
## Sistema de Percepção Sensorial e Guarda de Habitat estilo Alien: Isolation.

signal ground_slam_performed

const SOUL_DROP_SCENE: PackedScene = preload("res://entities/items/soul_drop_2d.tscn")

@export var slam_damage: float = 38.0
@export var slam_range: float = 110.0
@export var slam_cooldown: float = 2.8

var slam_timer: float = 0.0
var is_slamming: bool = false
var spawn_home_position: Vector2 = Vector2.ZERO
var patrol_look_timer: float = 0.0
var step_bobbing_timer: float = 0.0

@onready var visual_root: Node2D = $Visual
@onready var club_visual: Node2D = $Visual/ClubPivot
@onready var shockwave_area: Area2D = $ShockwaveArea
@onready var sensor: PerceptionSensor2D = $PerceptionSensor2D
@onready var indicator: AlertIndicator2D = $AlertIndicator2D

func _ready() -> void:
	character_name = "Olog das Profundezas"
	faction = GameEnums.Faction.FENDIDOS_DE_FERRO
	max_health = 360.0
	move_speed = 120.0
	defense = 8.0 # Armadura de pedra e ferro
	attack_power = slam_damage
	spawn_home_position = global_position
	super._ready()
	
	if sensor:
		sensor.alert_level_changed.connect(_on_alert_level_changed)
		sensor.target_spotted.connect(_on_target_spotted)
		sensor.target_lost.connect(_on_target_lost)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	if slam_timer > 0.0:
		slam_timer -= delta
	
	_process_olog_tactics(delta)
	move_and_slide()

func _process_olog_tactics(delta: float) -> void:
	if is_slamming:
		velocity = Vector2.ZERO
		return
	
	var alert: GameEnums.AlertLevel = sensor.current_alert if sensor else GameEnums.AlertLevel.CALMO
	
	match alert:
		GameEnums.AlertLevel.CALMO:
			_process_calm_guard(delta)
		GameEnums.AlertLevel.SUSPEITO, GameEnums.AlertLevel.INVESTIGANDO:
			_process_investigating(delta)
		GameEnums.AlertLevel.BUSCA_CAUTELOSA:
			_process_cautious_search(delta)
		GameEnums.AlertLevel.COMBATE_ATIVO:
			_process_active_combat(delta)

## Estado Calmo: Permanece em guarda territorial nos Pilares de Pedra do Norte
func _process_calm_guard(delta: float) -> void:
	var dist_home: float = global_position.distance_to(spawn_home_position)
	if dist_home > 120.0:
		# Retorna calmamente à sua posição inicial de guarda
		var to_home: Vector2 = (spawn_home_position - global_position).normalized()
		velocity = to_home * (move_speed * 0.45)
		_orient_visual(to_home)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, move_speed * 0.1)
		# Vigia alternando a direção a cada poucos segundos
		patrol_look_timer += delta
		if patrol_look_timer >= 4.0:
			patrol_look_timer = 0.0
			var random_dir: Vector2 = Vector2.RIGHT.rotated(randf_range(-PI, PI))
			_orient_visual(random_dir)

## Estado Suspeito/Investigando: Anda lentamente para a origem do ruído ou faro
func _process_investigating(_delta: float) -> void:
	if not sensor:
		return
	
	var investigate_pos: Vector2 = sensor.last_known_position
	var dist: float = global_position.distance_to(investigate_pos)
	
	if dist > 40.0:
		var to_pos: Vector2 = (investigate_pos - global_position).normalized()
		velocity = to_pos * (move_speed * 0.55)
		_orient_visual(to_pos)
	else:
		velocity = Vector2.ZERO

## Estado Busca Cautelosa: Inspeciona a última posição onde viu o alvo antes de desistir
func _process_cautious_search(_delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, move_speed * 0.15)

## Estado Combate Ativo: Alvo confirmado dentro do raio de percepção sensorial
func _process_active_combat(_delta: float) -> void:
	var target: Node2D = sensor.current_target if sensor else null
	if not target or not is_instance_valid(target):
		return
	
	var dist: float = global_position.distance_to(target.global_position)
	var to_target: Vector2 = (target.global_position - global_position).normalized()
	_orient_visual(to_target)
	
	if dist > slam_range:
		velocity = to_target * move_speed
	else:
		velocity = Vector2.ZERO
		if slam_timer <= 0.0:
			_execute_ground_slam()

func _orient_visual(dir: Vector2) -> void:
	if visual_root and dir.x != 0.0:
		visual_root.scale.x = -1.0 if dir.x < 0 else 1.0
	if sensor and dir != Vector2.ZERO:
		sensor.global_rotation = dir.angle()

func _execute_ground_slam() -> void:
	is_slamming = true
	slam_timer = slam_cooldown
	
	# Telegrafia do golpe: levanta a clava
	if club_visual:
		var tween: Tween = create_tween()
		tween.tween_property(club_visual, "rotation", -PI * 0.6, 0.45)
		tween.tween_callback(_impact_ground_slam)

func _impact_ground_slam() -> void:
	if is_dead:
		return
	
	AudioManager.play_sfx(AudioManager.stream_hit, 3.0)
	_spawn_crack_visual()
	
	var targets: Array[Node] = get_tree().get_nodes_in_group("player")
	targets.append_array(get_tree().get_nodes_in_group("servants"))
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy != self and is_instance_valid(enemy) and enemy is BaseCharacter and (enemy as BaseCharacter).faction != faction:
			targets.append(enemy)
	
	for body in targets:
		if body is BaseCharacter and not body.is_dead and body.faction != faction:
			var d: float = global_position.distance_to(body.global_position)
			if d <= 180.0:
				body.take_damage(slam_damage, self)
				var dir: Vector2 = (body.global_position - global_position).normalized()
				body.velocity += dir * 350.0
	
	if club_visual:
		var ret_tween: Tween = create_tween()
		ret_tween.tween_property(club_visual, "rotation", 0.0, 0.25)
	
	emit_signal("ground_slam_performed")
	is_slamming = false

func _spawn_crack_visual() -> void:
	var crack: Polygon2D = Polygon2D.new()
	crack.color = Color(0.9, 0.5, 0.1, 0.6)
	crack.polygon = PackedVector2Array([
		Vector2(0, -25), Vector2(30, -15), Vector2(45, 10),
		Vector2(15, 30), Vector2(-20, 25), Vector2(-40, 5), Vector2(-25, -20)
	])
	crack.global_position = global_position + Vector2(0, 15)
	get_parent().add_child(crack)
	
	var tween: Tween = create_tween()
	tween.tween_property(crack, "scale", Vector2(2.5, 2.5), 0.35)
	tween.parallel().tween_property(crack, "modulate:a", 0.0, 0.35)
	tween.tween_callback(crack.queue_free)

func _on_alert_level_changed(new_level: GameEnums.AlertLevel) -> void:
	if indicator:
		indicator.update_alert(new_level)

func _on_target_spotted(target: Node2D) -> void:
	AudioManager.play_sfx(AudioManager.stream_hit, 0.8)

func _on_target_lost(_last_pos: Vector2) -> void:
	pass

func take_damage(amount: float, source: Node = null) -> float:
	var dmg: float = super.take_damage(amount, source)
	velocity = Vector2.ZERO # Resiste a empurrões
	if sensor and is_instance_valid(source) and source is Node2D:
		sensor.hear_noise((source as Node2D).global_position, 2.5)
	return dmg

var is_captain: bool = false
var warlord_data: WarlordData = null

func promote_to_captain(data: WarlordData) -> void:
	is_captain = true
	warlord_data = data
	character_name = data.get_full_title()
	max_health = 600.0
	current_health = max_health
	slam_damage = 44.0
	defense = 14.0
	move_speed = 135.0
	add_to_group("captains")
	
	if visual_root:
		visual_root.scale = Vector2(1.25, 1.25)
	
	var banner: Label = Label.new()
	banner.text = "★ SENHOR DA GUERRA %s ★\n[%s]" % [data.commander_name.to_upper(), data.title]
	banner.position = Vector2(-180, -115)
	banner.custom_minimum_size = Vector2(360, 40)
	banner.add_theme_color_override("font_color", Color(1.0, 0.45, 0.2, 1.0))
	banner.add_theme_font_size_override("font_size", 11)
	add_child(banner)

func die(killer: Node = null) -> void:
	if is_captain and warlord_data:
		InfamyManager.record_warlord_defeat(warlord_data.id)
		EventBus.tactical_pressure_updated.emit("SENHOR_DA_GUERRA_DERROTADO: " + warlord_data.get_full_title(), 0.0)
	
	var drop: SoulDrop2D = SOUL_DROP_SCENE.instantiate()
	drop.global_position = global_position
	drop.source_enemy_name = character_name
	drop.source_faction = faction
	drop.is_captain = is_captain
	drop.captain_warlord_data = warlord_data
	if drop.soul_data:
		drop.soul_data.id = "alma_olog_colosso"
		drop.soul_data.soul_name = "Centelha de " + character_name
		drop.soul_data.energy_value = 50.0
	
	var cur_scene: Node = get_tree().current_scene
	if cur_scene:
		cur_scene.call_deferred("add_child", drop)
	
	super.die(killer)
	queue_free()
