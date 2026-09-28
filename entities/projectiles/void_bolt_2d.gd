class_name VoidBolt2D
extends Area2D

## Projétil de Éter Vazio disparado por Necroth

@export var speed: float = 650.0
@export var damage: float = 24.0
@export var lifetime: float = 1.8

var direction: Vector2 = Vector2.RIGHT
var shooter: Node2D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var timer: SceneTreeTimer = get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)

func setup(dir: Vector2, owner_node: Node2D) -> void:
	direction = dir.normalized()
	rotation = direction.angle()
	shooter = owner_node

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body == shooter:
		return
	
	if body is BaseCharacter and body.faction != GameEnums.Faction.PACTO_NECROTH:
		body.take_damage(damage, shooter)
		queue_free()
	elif not body is BaseCharacter and not body is Area2D:
		# Colisão com obstáculos estáticos do cenário
		queue_free()
