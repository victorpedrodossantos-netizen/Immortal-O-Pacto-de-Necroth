class_name BattleDialogueSystem
extends Node

## Motor de Diálogos e Clamor de Guerra Procedural
## Escuta o histórico de combate e emite falas contextuais diegéticas.

signal dialogue_triggered(speaker: String, text: String, color: Color)

const BARKS_ON_SUMMON: Array[String] = [
	"A Foice do Limbo... o ceifador espectral nos alcançou!",
	"Necroth ergueu o Carrasco! Mantenham distância da lâmina!",
	"Pelos deuses de ferro... a Morte de capuz cinzento está aqui!"
]

const BARKS_ON_LOW_HP: Array[String] = [
	"Necroth está ferido! Apertem o cerco, fechem as rotas!",
	"O Tecedor sangra! Um último golpe romperá o pacto dele!"
]

const BARKS_ON_NIGHT_FALL: Array[String] = [
	"A lua escureceu! Os Pútridos rastejam das fendas!",
	"Cuidado com os tetos e covas! O enxame sente o cheiro de sangue!"
]

func _ready() -> void:
	EventBus.servant_summoned.connect(_on_servant_summoned)
	EventBus.warlord_defeated.connect(_on_warlord_defeated)
	EventBus.enemy_promoted.connect(_on_enemy_promoted)

func _on_servant_summoned(_servant: Node2D, _cost: float) -> void:
	var bark: String = BARKS_ON_SUMMON.pick_random()
	emit_signal("dialogue_triggered", "Incursor Aterrorizado", bark, Color(0.9, 0.4, 0.4))

func _on_warlord_defeated(warlord_data: Dictionary, _slayer: Node) -> void:
	var c_name: String = warlord_data.get("name", "O Capitão")
	emit_signal("dialogue_triggered", "Hoste Fendida", "%s tombou perante a foice... recuem e reorganizem as linhas!" % c_name, Color(1.0, 0.6, 0.3))

func _on_enemy_promoted(_enemy_id: String, full_title: String, _tier: int) -> void:
	emit_signal("dialogue_triggered", "Tábua da Infâmia", "Ascensão de Sangue: %s assume o comando!" % full_title, Color(1.0, 0.85, 0.3))
