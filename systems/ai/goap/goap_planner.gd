class_name GOAPPlanner
extends RefCounted

## Planejador A* no espaço de estados para geração de planos de ação (F.E.A.R. style)

## Gera uma lista de ações ordenadas que transformam o estado inicial no estado da meta
static func plan(current_state: Dictionary, goal: GOAPGoal, available_actions: Array[GOAPAction]) -> Array[GOAPAction]:
	if goal.is_satisfied(current_state):
		return []
	
	# Nó de busca: {"state": Dictionary, "cost": float, "action": GOAPAction, "parent": Node}
	var open_set: Array[Dictionary] = []
	var closed_hashes: Dictionary = {}
	
	var start_node: Dictionary = {
		"state": current_state.duplicate(true),
		"cost": 0.0,
		"action": null,
		"parent": null
	}
	open_set.append(start_node)
	
	var max_iterations: int = 250
	var iterations: int = 0
	
	while open_set.size() > 0 and iterations < max_iterations:
		iterations += 1
		
		# Seleciona o nó de menor custo estimado
		var best_idx: int = 0
		var best_f: float = open_set[0]["cost"] + _heuristic(open_set[0]["state"], goal.desired_state)
		for i in range(1, open_set.size()):
			var f: float = open_set[i]["cost"] + _heuristic(open_set[i]["state"], goal.desired_state)
			if f < best_f:
				best_f = f
				best_idx = i
		
		var current_node: Dictionary = open_set[best_idx]
		open_set.remove_at(best_idx)
		
		# Verifica se a meta foi alcançada
		if goal.is_satisfied(current_node["state"]):
			return _reconstruct_plan(current_node)
		
		var state_hash: int = _hash_state(current_node["state"])
		closed_hashes[state_hash] = true
		
		# Expande ações possíveis a partir do estado atual
		for action in available_actions:
			if action.is_valid_for(current_node["state"]):
				var next_state: Dictionary = action.apply_effects(current_node["state"])
				var next_hash: int = _hash_state(next_state)
				
				if closed_hashes.has(next_hash):
					continue
				
				var tentative_cost: float = current_node["cost"] + action.cost
				
				var neighbor_node: Dictionary = {
					"state": next_state,
					"cost": tentative_cost,
					"action": action,
					"parent": current_node
				}
				open_set.append(neighbor_node)
	
	return []

## Heurística: conta quantas condições da meta ainda faltam ser satisfeitas
static func _heuristic(state: Dictionary, desired_state: Dictionary) -> float:
	var missing: float = 0.0
	for key in desired_state:
		if not state.has(key) or state[key] != desired_state[key]:
			missing += 1.0
	return missing

static func _hash_state(state: Dictionary) -> int:
	var keys: Array = state.keys()
	keys.sort()
	var s: String = ""
	for k in keys:
		s += "%s:%s;" % [str(k), str(state[k])]
	return s.hash()

static func _reconstruct_plan(final_node: Dictionary) -> Array[GOAPAction]:
	var plan_list: Array[GOAPAction] = []
	var curr: Variant = final_node
	while curr != null and curr.has("action") and curr["action"] != null:
		plan_list.insert(0, curr["action"])
		curr = curr.get("parent", null)
	return plan_list
