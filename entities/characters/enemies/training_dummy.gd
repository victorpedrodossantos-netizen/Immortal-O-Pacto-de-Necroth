class_name TrainingDummy
extends BaseCharacter

## Boneco de Treino / Guerreiro Fendido para testes de combate e colheita de almas

const SOUL_DROP_SCENE: PackedScene = preload("res://entities/items/soul_drop_2d.tscn")

@onready var visual: Node2D = $Visual

func _ready() -> void:
	character_name = "Incursor Fendido de Treino"
	faction = GameEnums.Faction.FENDIDOS_DE_FERRO
	max_health = 75.0
	defense = 2.0
	super._ready()
	add_to_group("enemies")

func _on_damaged(_dmg: float, _source: Node) -> void:
	if visual:
		var tween: Tween = create_tween()
		tween.tween_property(visual, "modulate", Color(1.0, 0.2, 0.2, 1.0), 0.08)
		tween.tween_property(visual, "modulate", Color(1, 1, 1, 1), 0.12)

func _on_death(_killer: Node) -> void:
	# Spawna orbe de alma ao tombar
	var drop: SoulDrop2D = SOUL_DROP_SCENE.instantiate()
	drop.global_position = global_position
	
	var parent_scene: Node = get_tree().current_scene
	if parent_scene:
		parent_scene.call_deferred("add_child", drop)
	
	queue_free()
