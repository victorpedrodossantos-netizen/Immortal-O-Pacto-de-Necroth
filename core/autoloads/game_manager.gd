extends Node

const SubjugatedSoulData = preload("res://resources/subjugated_soul_data.gd")

## Gerenciador Central de Estados e Dimensão
## Controla o ciclo de vida da aplicação e a validação do modo dimensional selecionado.

var current_dimension: GameEnums.DimensionMode = GameEnums.DimensionMode.MODE_2D
var dimension_statuses: Dictionary = {
	GameEnums.DimensionMode.MODE_2D: GameEnums.DimensionStatus.ACTIVE,
	GameEnums.DimensionMode.MODE_25D: GameEnums.DimensionStatus.UNDER_MAINTENANCE,
	GameEnums.DimensionMode.MODE_3D: GameEnums.DimensionStatus.UNDER_MAINTENANCE
}

var is_transitioning: bool = false

# Sistema de Buffs Temporários de Sacrifício
signal buff_started(buff_id: String, buff_name: String, duration: float)
signal buff_expired(buff_id: String)

var active_buffs: Dictionary = {} # { buff_id: { "name": String, "timer": float, "duration": float, "type": int } }

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.scene_transition_requested.connect(change_scene)

func _process(delta: float) -> void:
	if active_buffs.is_empty():
		return
	
	var expired_ids: Array[String] = []
	for id in active_buffs:
		active_buffs[id]["timer"] -= delta
		if active_buffs[id]["timer"] <= 0.0:
			expired_ids.append(id)
	
	for id in expired_ids:
		active_buffs.erase(id)
		emit_signal("buff_expired", id)

## Aplica um bônus temporário decorrente do Sacrifício das Cinzas
func apply_sacrifice_buff(buff_type: SubjugatedSoulData.SacrificeBuffType, source_name: String) -> void:
	var b_id: String = ""
	var b_name: String = ""
	var b_dur: float = 30.0
	
	match buff_type:
		SubjugatedSoulData.SacrificeBuffType.COURAÇA_FERRO:
			b_id = "buff_armadura"
			b_name = "Couraça de Ferro Fúnebre"
			b_dur = 30.0
		SubjugatedSoulData.SacrificeBuffType.PASSO_FANTASMA:
			b_id = "buff_velocidade"
			b_name = "Passo Fantasmagórico"
			b_dur = 25.0
		SubjugatedSoulData.SacrificeBuffType.MANANCIAL_VAZIO:
			b_id = "buff_eter"
			b_name = "Manancial do Vazio"
			b_dur = 30.0
		SubjugatedSoulData.SacrificeBuffType.ASCENSAO_FUNEBRE:
			b_id = "buff_ascensao"
			b_name = "Ascensão Fúnebre"
			b_dur = 15.0
	
	active_buffs[b_id] = {
		"name": b_name,
		"timer": b_dur,
		"duration": b_dur,
		"type": buff_type,
		"source": source_name
	}
	
	AudioManager.play_sfx(AudioManager.stream_summon, 2.5)
	emit_signal("buff_started", b_id, b_name, b_dur)

func has_buff(buff_id: String) -> bool:
	return active_buffs.has(buff_id)

func get_defense_multiplier() -> float:
	return 1.5 if has_buff("buff_armadura") else 1.0

func get_speed_multiplier() -> float:
	return 1.4 if has_buff("buff_velocidade") else 1.0

func get_ether_regen_multiplier() -> float:
	return 3.0 if has_buff("buff_eter") else 1.0

## Retorna se uma dada dimensão está liberada para jogo
func is_dimension_available(mode: GameEnums.DimensionMode) -> bool:
	return dimension_statuses.get(mode, GameEnums.DimensionStatus.UNDER_MAINTENANCE) == GameEnums.DimensionStatus.ACTIVE

## Tenta alterar a dimensão ativa
func set_dimension(mode: GameEnums.DimensionMode) -> bool:
	if not is_dimension_available(mode):
		push_warning("[GameManager] Modo dimensional bloqueado ou em manutenção: %s" % mode)
		return false
	
	if current_dimension != mode:
		current_dimension = mode
		EventBus.dimension_changed.emit(current_dimension)
	return true

## Transição de cenas com validação de existência
func change_scene(target_scene_path: String) -> void:
	if is_transitioning:
		return
	
	if not ResourceLoader.exists(target_scene_path):
		push_error("[GameManager] Cena não encontrada no caminho: %s" % target_scene_path)
		return
	
	is_transitioning = true
	var err: Error = get_tree().change_scene_to_file(target_scene_path)
	if err != OK:
		push_error("[GameManager] Falha ao transicionar para a cena %s: Erro %d" % [target_scene_path, err])
	is_transitioning = false
