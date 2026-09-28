class_name BaseCharacter
extends CharacterBody2D

## Classe base para todas as entidades vivas e espectrais em Immortal: O Pacto de Necroth

signal health_changed(current_hp: float, max_hp: float)
signal died(killer: Node)

@export_group("Atributos Básicos")
@export var character_name: String = "Entidade"
@export var faction: GameEnums.Faction = GameEnums.Faction.PACTO_NECROTH
@export var max_health: float = 100.0
@export var move_speed: float = 220.0

@export_group("Combate")
@export var attack_power: float = 15.0
@export var defense: float = 2.0

var current_health: float = 100.0
var is_dead: bool = false

func _ready() -> void:
	current_health = max_health
	emit_signal("health_changed", current_health, max_health)

## Aplica dano à entidade com mitigação de defesa
func take_damage(amount: float, source: Node = null) -> float:
	if is_dead:
		return 0.0
	
	var actual_damage: float = maxf(1.0, amount - defense)
	current_health = maxf(0.0, current_health - actual_damage)
	emit_signal("health_changed", current_health, max_health)
	
	_on_damaged(actual_damage, source)
	
	if current_health <= 0.0:
		die(source)
	
	return actual_damage

## Cura pontos de vida
func heal(amount: float) -> void:
	if is_dead:
		return
	current_health = minf(max_health, current_health + amount)
	emit_signal("health_changed", current_health, max_health)

## Rotina de morte da entidade
func die(killer: Node = null) -> void:
	if is_dead:
		return
	is_dead = true
	emit_signal("died", killer)
	_on_death(killer)

## Sobrescrito por classes filhas para efeitos visuais/áudio de dano
func _on_damaged(_dmg: float, _source: Node) -> void:
	pass

## Sobrescrito por classes filhas para descarte, spawn de almas ou animações
func _on_death(_killer: Node) -> void:
	queue_free()
