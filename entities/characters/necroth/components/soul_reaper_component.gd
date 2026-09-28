class_name SoulReaperComponent
extends Area2D

## Componente de Ceifa e Coleta Magnética de Almas de Necroth

@export var attraction_radius: float = 220.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	_update_shape()

func _update_shape() -> void:
	if not collision_shape:
		return
	var circle: CircleShape2D = collision_shape.shape as CircleShape2D
	if not circle:
		circle = CircleShape2D.new()
		collision_shape.shape = circle
	circle.radius = attraction_radius

func _on_area_entered(area: Area2D) -> void:
	if area is SoulDrop2D:
		var parent_node: Node2D = get_parent() as Node2D
		area.attract_to(parent_node)
