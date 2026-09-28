class_name AvatarPredador
extends BaseCharacter

## Avatar Predador: Chefe de Guerra com IA de Dois Cérebros (Macro/Micro)

const SOUL_DROP_SCENE: PackedScene = preload("res://entities/items/soul_drop_2d.tscn")

@export var warlord_id: String = "balgor_avatar"
@export var boss_title: String = "Balgor, Avatar do Rancor Ancestral"

@onready var micro_brain: MicroPredatorBrain = $MicroPredatorBrain
@onready var sensor: PerceptionSensor2D = $PerceptionSensor2D
@onready var visual_root: Node2D = $Visual
@onready var rage_aura: CanvasItem = $Visual/RageAura
@onready var slam_area: Area2D = $GroundSlamArea

var macro_director: MacroPredatorDirector = null

func _ready() -> void:
	character_name = boss_title
	faction = GameEnums.Faction.FENDIDOS_DE_FERRO
	max_health = 360.0
	move_speed = 175.0
	attack_power = 28.0
	defense = 6.0
	super._ready()
	add_to_group("enemies")
	add_to_group("bosses")
	
	if micro_brain:
		micro_brain.setup(self)
		micro_brain.phase_changed.connect(_on_phase_changed)
		micro_brain.ground_slam_executed.connect(_on_ground_slam)
	
	_find_macro_director()

func _find_macro_director() -> void:
	var tree: SceneTree = get_tree()
	if tree:
		var directors: Array[Node] = tree.get_nodes_in_group("macro_directors")
		if directors.size() > 0:
			macro_director = directors[0] as MacroPredatorDirector
			macro_director.current_boss = self
			macro_director.pressure_target_assigned.connect(_on_macro_pressure)

func _on_macro_pressure(pos: Vector2) -> void:
	if micro_brain:
		micro_brain.set_macro_hint(pos)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	var target: Node2D = sensor.current_target if sensor else null
	if micro_brain:
		velocity = micro_brain.update_micro_combat(delta, target)
	
	if velocity.x != 0.0 and visual_root:
		visual_root.scale.x = -1.0 if velocity.x < 0 else 1.0
	
	move_and_slide()

func _on_phase_changed(new_phase: int) -> void:
	if rage_aura:
		rage_aura.visible = true
	# Alerta global de fúria
	EventBus.squad_alert_changed.emit(self, GameEnums.AlertLevel.COMBATE_ATIVO, global_position)

func _on_ground_slam(origin: Vector2, radius: float, damage: float) -> void:
	# Efeito visual de tremor
	var tween: Tween = create_tween()
	if visual_root:
		tween.tween_property(visual_root, "position", Vector2(0, 12), 0.08)
		tween.tween_property(visual_root, "position", Vector2.ZERO, 0.12)
	
	# Aplica dano na área de impacto
	var bodies: Array[Node2D] = slam_area.get_overlapping_bodies()
	for body in bodies:
		if body is BaseCharacter and body != self and body.faction != faction:
			body.take_damage(damage, self)

func _on_death(_killer: Node) -> void:
	# Registra derrota na Tábua da Infâmia
	InfamyManager.record_warlord_defeat(warlord_id)
	
	# Dropa alma de alta magnitude
	var drop: SoulDrop2D = SOUL_DROP_SCENE.instantiate()
	drop.global_position = global_position
	var soul: SoulData = SoulData.new()
	soul.id = "alma_avatar_supremo"
	soul.soul_name = "Centelha Primordial do Rancor"
	soul.energy_value = 50.0
	drop.soul_data = soul
	
	var cur_scene: Node = get_tree().current_scene
	if cur_scene:
		cur_scene.call_deferred("add_child", drop)
	
	queue_free()
