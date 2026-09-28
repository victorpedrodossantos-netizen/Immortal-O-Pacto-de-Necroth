class_name TacticalFendidoEnemy
extends BaseCharacter

## Guerreiro Fendido Tático com IA GOAP e Coordenação de Esquadrão

const SOUL_DROP_SCENE: PackedScene = preload("res://entities/items/soul_drop_2d.tscn")

@export_group("Equipamento Fendido")
@export var sword_damage: float = 16.0
@export var attack_range: float = 55.0
@export var attack_cooldown: float = 1.2

var is_shield_raised: bool = false
var has_attack_token: bool = false
var attack_timer: float = 0.0

@onready var sensor: PerceptionSensor2D = $PerceptionSensor2D
@onready var indicator: AlertIndicator2D = $AlertIndicator2D
@onready var goap_agent: GOAPAgent = $GOAPAgent
@onready var visual_root: Node2D = $Visual
@onready var shield_visual: CanvasItem = $Visual/Shield
@onready var sword_pivot: Node2D = $Visual/SwordPivot

var tactical_director: TacticalDirector2D = null
var spawn_home_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	character_name = "Guerreiro Fendido de Choque"
	faction = GameEnums.Faction.FENDIDOS_DE_FERRO
	max_health = 110.0
	move_speed = 185.0
	defense = 3.0
	spawn_home_position = global_position
	super._ready()
	add_to_group("enemies")
	
	_setup_director()
	_setup_sensors()
	_setup_goap()

func _setup_director() -> void:
	var tree: SceneTree = get_tree()
	if tree:
		var directors: Array[Node] = tree.get_nodes_in_group("tactical_directors")
		if directors.size() > 0:
			tactical_director = directors[0] as TacticalDirector2D
			tactical_director.register_unit(self)

func _setup_sensors() -> void:
	if sensor:
		sensor.alert_level_changed.connect(_on_alert_level_changed)
		sensor.target_spotted.connect(_on_target_spotted)

func _setup_goap() -> void:
	if not goap_agent:
		return
	
	# Metas
	var goal_strike: GOAPGoal = GOAPGoal.new()
	goal_strike.goal_name = "EliminarAlvo"
	goal_strike.priority = 10.0
	goal_strike.desired_state = {"target_struck": true}
	
	var goal_shield: GOAPGoal = GOAPGoal.new()
	goal_shield.goal_name = "BloquearDisparos"
	goal_shield.priority = 15.0
	goal_shield.desired_state = {"is_blocking": true}
	
	goap_agent.goals = [goal_strike, goal_shield]
	
	# Ações
	var act_flank: GOAPAction = GOAPAction.new()
	act_flank.action_name = "PosicionarNoFlanco"
	act_flank.cost = 1.0
	act_flank.preconditions = {"in_position": false}
	act_flank.effects = {"in_position": true}
	
	var act_token: GOAPAction = GOAPAction.new()
	act_token.action_name = "SolicitarTokenAtaque"
	act_token.cost = 1.5
	act_token.preconditions = {"in_position": true, "has_token": false}
	act_token.effects = {"has_token": true}
	
	var act_slash: GOAPAction = GOAPAction.new()
	act_slash.action_name = "DesferirGolpeEspada"
	act_slash.cost = 1.0
	act_slash.preconditions = {"in_position": true, "has_token": true}
	act_slash.effects = {"target_struck": true}
	
	goap_agent.available_actions = [act_flank, act_token, act_slash]
	goap_agent.world_state = {
		"in_position": false,
		"has_token": false,
		"target_struck": false,
		"is_blocking": false
	}
	goap_agent.evaluate_plan()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	if attack_timer > 0.0:
		attack_timer -= delta
	
	_execute_tactical_behavior(delta)
	move_and_slide()

func _execute_tactical_behavior(delta: float) -> void:
	var alert: GameEnums.AlertLevel = sensor.current_alert if sensor else GameEnums.AlertLevel.CALMO
	
	match alert:
		GameEnums.AlertLevel.CALMO:
			_process_calm_patrol(delta)
		GameEnums.AlertLevel.SUSPEITO, GameEnums.AlertLevel.INVESTIGANDO:
			_process_investigating(delta)
		GameEnums.AlertLevel.BUSCA_CAUTELOSA:
			_process_cautious_search(delta)
		GameEnums.AlertLevel.COMBATE_ATIVO:
			_process_active_combat(delta)

## Estado Calmo: Mantém formação de guarda em sua rota militar
func _process_calm_patrol(_delta: float) -> void:
	var dist_home: float = global_position.distance_to(spawn_home_position)
	if dist_home > 70.0:
		var to_home: Vector2 = (spawn_home_position - global_position).normalized()
		velocity = to_home * (move_speed * 0.45)
		_orient_visual(to_home)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, move_speed * 0.2)

## Estado Investigando: Marcha cautelosa com escudo erguido em direção ao ruído
func _process_investigating(_delta: float) -> void:
	if not sensor:
		return
	var investigate_pos: Vector2 = sensor.last_known_position
	var dist: float = global_position.distance_to(investigate_pos)
	if dist > 35.0:
		var to_pos: Vector2 = (investigate_pos - global_position).normalized()
		velocity = to_pos * (move_speed * 0.6)
		_orient_visual(to_pos)
	else:
		velocity = Vector2.ZERO

## Estado Busca Cautelosa: Mantém guarda na última posição avistada
func _process_cautious_search(_delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, move_speed * 0.2)

## Estado Combate Ativo: Manobra em esquadrão, requisição de token de ataque e flanqueamento
func _process_active_combat(_delta: float) -> void:
	var target: Node2D = sensor.current_target if sensor else null
	if not target or not is_instance_valid(target):
		velocity = velocity.move_toward(Vector2.ZERO, move_speed * 0.1)
		return
	
	var to_target: Vector2 = target.global_position - global_position
	_orient_visual(to_target)
	
	var desired_pos: Vector2 = target.global_position
	if tactical_director:
		desired_pos = tactical_director.get_slot_position(self)
	
	var dist_to_slot: float = global_position.distance_to(desired_pos)
	var dist_to_target: float = global_position.distance_to(target.global_position)
	
	if dist_to_slot < 60.0 and not has_attack_token and tactical_director:
		has_attack_token = tactical_director.request_attack_token(self)
	
	if has_attack_token:
		if dist_to_target > attack_range:
			velocity = (target.global_position - global_position).normalized() * move_speed
		else:
			velocity = Vector2.ZERO
			if attack_timer <= 0.0:
				_perform_sword_strike(target)
	else:
		if dist_to_slot > 20.0:
			velocity = (desired_pos - global_position).normalized() * move_speed
		else:
			velocity = velocity.move_toward(Vector2.ZERO, move_speed * 0.2)

func _orient_visual(dir: Vector2) -> void:
	if visual_root and dir.x != 0.0:
		visual_root.scale.x = -1.0 if dir.x < 0 else 1.0
	if sensor and dir != Vector2.ZERO:
		sensor.global_rotation = dir.angle()

func _perform_sword_strike(target: Node2D) -> void:
	attack_timer = attack_cooldown
	
	# Animação da espada
	if sword_pivot:
		var tween: Tween = create_tween()
		tween.tween_property(sword_pivot, "rotation", sword_pivot.rotation + PI * 0.8, 0.15)
		tween.tween_property(sword_pivot, "rotation", 0.0, 0.15)
	
	# Aplica dano se ainda estiver em alcance
	if global_position.distance_to(target.global_position) <= (attack_range + 20.0):
		if target is BaseCharacter:
			target.take_damage(sword_damage, self)
	
	# Libera o token de ataque para outro aliado golpear
	has_attack_token = false
	if tactical_director:
		tactical_director.release_attack_token(self)

func _on_alert_level_changed(new_level: GameEnums.AlertLevel) -> void:
	if indicator:
		indicator.update_alert(new_level)

func _on_target_spotted(target: Node2D) -> void:
	if not is_instance_valid(target):
		return
	if tactical_director:
		tactical_director.trigger_bark("Guerreiro Fendido", "Necroth avistado! Fechem a formação!")
		tactical_director.alert_squad(target, self)

func _on_damaged(dmg: float, source: Node) -> void:
	# Ergue o escudo temporariamente ao sofrer dano à distância
	if shield_visual:
		shield_visual.modulate = Color(1.0, 0.8, 0.3, 1.0)
	
	# Alerta instantâneo
	if sensor and is_instance_valid(source) and source is Node2D:
		sensor.hear_noise((source as Node2D).global_position, 2.0)

func _on_death(_killer: Node) -> void:
	if tactical_director:
		tactical_director.release_attack_token(self)
		tactical_director.unregister_unit(self)
		tactical_director.trigger_bark("Incursor Fendido", "Caído! Vinguem o irmão de ferro!")
	
	# Spawna orbe de alma
	var drop: SoulDrop2D = SOUL_DROP_SCENE.instantiate()
	drop.global_position = global_position
	var cur_scene: Node = get_tree().current_scene
	if cur_scene:
		cur_scene.call_deferred("add_child", drop)
	
	queue_free()
