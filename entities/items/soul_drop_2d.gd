class_name SoulDrop2D
extends Area2D

## Orbe de Alma colhível no campo de batalha
## Ao ser absorvida por Necroth, a alma é transferida para o Grimório de Invocações.

@export var soul_data: SoulData
@export var attraction_speed: float = 380.0
@export var magnetic_radius: float = 180.0

var source_enemy_name: String = "Guerreiro"
var source_faction: GameEnums.Faction = GameEnums.Faction.FENDIDOS_DE_FERRO
var is_captain: bool = false
var captain_warlord_data: WarlordData = null

var target_reaper: Node2D = null
var is_harvested: bool = false
var float_time: float = 0.0

@onready var sprite: CanvasItem = $Visual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if not soul_data:
		soul_data = SoulData.new()
		soul_data.id = "alma_%s_%d" % [source_enemy_name.to_lower().replace(" ", "_"), Time.get_ticks_msec()]
		soul_data.soul_name = source_enemy_name
		soul_data.energy_value = 50.0 if is_captain else 18.0
	
	if is_captain and sprite:
		# Orbes de Capitães brilham com chama dourada-carmesim imponente
		sprite.modulate = Color(2.0, 1.4, 0.3, 1.0)
		scale = Vector2(1.5, 1.5)

func _physics_process(delta: float) -> void:
	if is_harvested:
		return
	
	float_time += delta * 4.0
	if sprite:
		sprite.position.y = sin(float_time) * 4.0
	
	if target_reaper and is_instance_valid(target_reaper):
		var dir: Vector2 = (target_reaper.global_position - global_position).normalized()
		global_position += dir * attraction_speed * delta
		attraction_speed += delta * 200.0 # Aceleração progressiva

func attract_to(reaper: Node2D) -> void:
	target_reaper = reaper

func _on_body_entered(body: Node2D) -> void:
	if is_harvested:
		return
	
	if body.has_method("harvest_soul_orb"):
		is_harvested = true
		body.harvest_soul_orb(self)
		queue_free()
	elif body.has_method("harvest_soul"):
		is_harvested = true
		body.harvest_soul(soul_data)
		EventBus.soul_harvested.emit(soul_data.id, soul_data.energy_value, global_position)
		queue_free()
