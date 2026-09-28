class_name TerrainZone2D
extends Area2D

## Zona de Modificadores Ambientais (Pântanos de Lodo e Ruínas Rúnicas)

enum ZoneType {
	PANTANO_LODO,
	RUINAS_RUNICAS
}

@export var zone_type: ZoneType = ZoneType.PANTANO_LODO
@export var zone_name: String = "Bioma"

var affected_entities: Array[BaseCharacter] = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body is BaseCharacter:
		var character: BaseCharacter = body as BaseCharacter
		affected_entities.append(character)
		_apply_effect(character, true)

func _on_body_exited(body: Node2D) -> void:
	if body is BaseCharacter:
		var character: BaseCharacter = body as BaseCharacter
		affected_entities.erase(character)
		_apply_effect(character, false)

func _apply_effect(character: BaseCharacter, enter: bool) -> void:
	match zone_type:
		ZoneType.PANTANO_LODO:
			# Redução de 40% na velocidade ao pisar no lodo
			if enter:
				character.move_speed *= 0.6
				character.modulate = Color(0.65, 0.75, 0.55, 1.0)
			else:
				character.move_speed /= 0.6
				character.modulate = Color(1.0, 1.0, 1.0, 1.0)
		
		ZoneType.RUINAS_RUNICAS:
			# Amplificação de Éter e Ceifa de Necroth
			if character is Necroth:
				var necroth: Necroth = character as Necroth
				if enter:
					necroth.ether_recovery_rate += 10.0
					if necroth.soul_reaper:
						necroth.soul_reaper.attraction_radius += 100.0
				else:
					necroth.ether_recovery_rate -= 10.0
					if necroth.soul_reaper:
						necroth.soul_reaper.attraction_radius -= 100.0
