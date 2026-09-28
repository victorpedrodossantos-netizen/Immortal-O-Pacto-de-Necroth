class_name SoulDrop2D
extends Area2D

## Orbe de Alma colhível no campo de batalha
## Atrai-se na direção de Necroth ao entrar no raio magnético do Ceifador.

@export var soul_data: SoulData
@export var attraction_speed: float = 380.0
@export var magnetic_radius: float = 180.0

var target_reaper: Node2D = null
var is_harvested: bool = false
var float_time: float = 0.0

@onready var sprite: CanvasItem = $Visual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if not soul_data:
		soul_data = SoulData.new()
		soul_data.id = "alma_fugaz"
		soul_data.soul_name = "Alma Fugaz do Limbo"
		soul_data.energy_value = 15.0

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
	
	if body.has_method("harvest_soul"):
		is_harvested = true
		body.harvest_soul(soul_data)
		EventBus.soul_harvested.emit(soul_data.id, soul_data.energy_value, global_position)
		queue_free()
