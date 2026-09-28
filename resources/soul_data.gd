class_name SoulData
extends Resource

## Recurso Customizado: Especificação de uma Alma/Centelha Espectral

@export var id: String = "alma_comum"
@export var soul_name: String = "Centelha de Cinzas"
@export var origin_faction: GameEnums.Faction = GameEnums.Faction.FENDIDOS_DE_FERRO
@export var energy_value: float = 15.0
@export var summon_cost: float = 25.0
@export var servant_scene: PackedScene
@export_multiline var lore_description: String = "Uma alma inquieta recolhida pelo Tecedor do Vazio."
