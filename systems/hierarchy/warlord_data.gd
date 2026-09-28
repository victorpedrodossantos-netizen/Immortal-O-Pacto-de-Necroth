class_name WarlordData
extends Resource

## Recurso de Dados de Comandante para a Tábua da Infâmia (Ascensão de Sangue)

@export var id: String = ""
@export var commander_name: String = "Guerreiro"
@export var title: String = "O Indômito"
@export var faction: GameEnums.Faction = GameEnums.Faction.FENDIDOS_DE_FERRO
@export var tier: int = 1 # 1: Capitão, 2: Senhor da Guerra, 3: Avatar Supremo
@export var power_level: int = 10
@export var is_alive: bool = true
@export var kill_count: int = 0

@export_group("Traços & Vulnerabilidades")
@export var strengths: Array[String] = []
@export var weaknesses: Array[String] = []
@export var scars: Array[String] = []

func get_full_title() -> String:
	return "%s, %s" % [commander_name, title]
