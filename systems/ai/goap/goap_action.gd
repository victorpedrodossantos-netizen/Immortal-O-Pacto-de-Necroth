class_name GOAPAction
extends Resource

## Ação atômica para o planejador GOAP (Goal-Oriented Action Planning)

@export var action_name: String = "Ação Genérica"
@export var cost: float = 1.0
@export var preconditions: Dictionary = {} # Ex: {"target_in_range": true, "has_attack_token": true}
@export var effects: Dictionary = {}       # Ex: {"target_damaged": true}

## Verifica se as pré-condições da ação são satisfeitas pelo estado atual do mundo
func is_valid_for(state: Dictionary) -> bool:
	for key in preconditions:
		if not state.has(key) or state[key] != preconditions[key]:
			return false
	return true

## Aplica os efeitos desta ação em um estado hipotético durante o planejamento A*
func apply_effects(state: Dictionary) -> Dictionary:
	var new_state: Dictionary = state.duplicate(true)
	for key in effects:
		new_state[key] = effects[key]
	return new_state
