class_name GOAPGoal
extends Resource

## Meta do agente GOAP com prioridade dinâmica e estado desejado

@export var goal_name: String = "Meta Genérica"
@export var priority: float = 10.0
@export var desired_state: Dictionary = {} # Ex: {"target_eliminated": true}

## Avalia se o estado do mundo já satisfaz a meta
func is_satisfied(state: Dictionary) -> bool:
	for key in desired_state:
		if not state.has(key) or state[key] != desired_state[key]:
			return false
	return true
