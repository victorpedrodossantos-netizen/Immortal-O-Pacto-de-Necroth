class_name GOAPAgent
extends Node

## Componente de Agente GOAP acoplado a entidades inteligentes

signal plan_generated(actions: Array[GOAPAction])
signal plan_failed(goal: GOAPGoal)

@export var available_actions: Array[GOAPAction] = []
@export var goals: Array[GOAPGoal] = []

var world_state: Dictionary = {}
var current_plan: Array[GOAPAction] = []
var active_goal: GOAPGoal = null
var current_action: GOAPAction = null

## Atualiza uma variável do estado de mundo do agente
func set_state(key: String, value: Variant) -> void:
	world_state[key] = value

## Consulta uma variável do estado de mundo
func get_state(key: String, default_val: Variant = null) -> Variant:
	return world_state.get(key, default_val)

## Reavalia as metas e recalcula o plano de ação
func evaluate_plan() -> void:
	if goals.is_empty():
		return
	
	# Ordena metas por prioridade decrescente
	var sorted_goals: Array[GOAPGoal] = goals.duplicate()
	sorted_goals.sort_custom(func(a: GOAPGoal, b: GOAPGoal) -> bool: return a.priority > b.priority)
	
	for goal in sorted_goals:
		if goal.is_satisfied(world_state):
			continue
		
		var new_plan: Array[GOAPAction] = GOAPPlanner.plan(world_state, goal, available_actions)
		if new_plan.size() > 0:
			active_goal = goal
			current_plan = new_plan
			current_action = current_plan[0]
			emit_signal("plan_generated", current_plan)
			return
	
	emit_signal("plan_failed", active_goal)

## Conclui a ação atual e avança para a próxima ação do plano
func complete_current_action() -> void:
	if current_action:
		# Aplica os efeitos da ação ao mundo real do agente
		for effect_key in current_action.effects:
			world_state[effect_key] = current_action.effects[effect_key]
	
	if current_plan.size() > 0:
		current_plan.remove_at(0)
	
	if current_plan.size() > 0:
		current_action = current_plan[0]
	else:
		current_action = null
		evaluate_plan()

## Interrompe o plano atual imediatamente (ex: ao sofrer dano ou perder alvo)
func abort_plan() -> void:
	current_plan.clear()
	current_action = null
	active_goal = null
