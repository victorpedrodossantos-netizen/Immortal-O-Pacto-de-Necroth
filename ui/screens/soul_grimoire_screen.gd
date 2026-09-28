class_name SoulGrimoireScreen
extends CanvasLayer

const SubjugatedSoulData = preload("res://resources/subjugated_soul_data.gd")
const SummonerComponent = preload("res://entities/characters/necroth/components/summoner_component.gd")

const PORTRAIT_ORC = preload("res://assets/portraits/orcs/portrait.jpg")
const PORTRAIT_OLOG = preload("res://assets/portraits/ologs/portrait.jpg")
const PORTRAIT_GHUL = preload("res://assets/portraits/ghuls/portrait.jpg")
const PORTRAIT_CAVALEIRO = preload("res://assets/portraits/cavaleiro_da_morte/portrait.jpg")
const PORTRAIT_DRAGAO = preload("res://assets/portraits/dragoes/portrait.jpg")

## Grimório dos Condenados: Tabuleiro de Almas Subjulgadas
## Interface inspirada no tabuleiro de capitães de Shadow of Mordor adaptada para necromancia original.

signal grimoire_closed

var summoner_ref: SummonerComponent = null
var selected_soul: SubjugatedSoulData = null

@onready var soul_container: VBoxContainer = %SoulContainer
@onready var army_status_label: Label = %ArmyStatusLabel
@onready var detail_portrait: TextureRect = %DetailPortrait
@onready var detail_name_label: Label = %DetailNameLabel
@onready var detail_class_label: Label = %DetailClassLabel
@onready var detail_stats_label: Label = %DetailStatsLabel
@onready var detail_lore_label: Label = %DetailLoreLabel
@onready var detail_sacrifice_label: Label = %DetailSacrificeLabel

@onready var btn_summon: Button = %BtnSummon
@onready var btn_sacrifice: Button = %BtnSacrifice
@onready var btn_escort: Button = %BtnEscort
@onready var btn_quick_slot1: Button = %BtnQuickSlot1
@onready var btn_quick_slot2: Button = %BtnQuickSlot2
@onready var btn_close: Button = %BtnClose

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	if btn_close:
		btn_close.pressed.connect(close_grimoire)
	if btn_summon:
		btn_summon.pressed.connect(_on_summon_pressed)
	if btn_sacrifice:
		btn_sacrifice.pressed.connect(_on_sacrifice_pressed)
	if btn_escort:
		btn_escort.pressed.connect(_on_escort_pressed)
	if btn_quick_slot1:
		btn_quick_slot1.pressed.connect(func(): _assign_quick_slot(1))
	if btn_quick_slot2:
		btn_quick_slot2.pressed.connect(func(): _assign_quick_slot(2))

func open_grimoire(summoner: SummonerComponent) -> void:
	summoner_ref = summoner
	if summoner_ref and not summoner_ref.subjugated_souls_updated.is_connected(_refresh_ui):
		summoner_ref.subjugated_souls_updated.connect(_refresh_ui)
	
	visible = true
	get_tree().paused = true
	_refresh_ui()

func close_grimoire() -> void:
	visible = false
	get_tree().paused = false
	emit_signal("grimoire_closed")

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and (event.keycode == KEY_TAB or event.keycode == KEY_ESCAPE or event.keycode == KEY_7):
		get_viewport().set_input_as_handled()
		close_grimoire()

func _refresh_ui() -> void:
	if not summoner_ref:
		return
	
	# Atualiza status do exército
	var active_count: int = summoner_ref.active_servants.size()
	var max_count: int = summoner_ref.max_field_servants
	if army_status_label:
		army_status_label.text = "⚔️ TROPAS EM CAMPO: %d / %d  |  GUARDIÃO: %s" % [
			active_count,
			max_count,
			"ATIVO (Carrasco do Limbo)" if is_instance_valid(summoner_ref.active_guardian) else "NO VÉU (Pressione B)"
		]
	
	# Limpar lista anterior de cartões
	if soul_container:
		for child in soul_container.get_children():
			child.queue_free()
		
		for soul in summoner_ref.subjugated_souls:
			var card_btn: Button = Button.new()
			card_btn.custom_minimum_size = Vector2(360, 48)
			
			var status_str: String = "[LIVRE]"
			if soul.is_summoned:
				status_str = "[EM COMBATE]"
			elif soul.assigned_to_guardian:
				status_str = "[ESCOLTA CARRASCO]"
			
			var slot_str: String = ""
			if summoner_ref.quick_slot_1 == soul: slot_str = " (SLOT 4)"
			elif summoner_ref.quick_slot_2 == soul: slot_str = " (SLOT 5)"
			
			card_btn.text = "%s  %s\n%s • %s%s" % [
				status_str,
				soul.soldier_name,
				soul.get_class_name_string(),
				soul.lore_description.substr(0, 32) + "...",
				slot_str
			]
			
			card_btn.pressed.connect(func(): _select_soul(soul))
			soul_container.add_child(card_btn)
	
	if selected_soul and summoner_ref.subjugated_souls.has(selected_soul):
		_select_soul(selected_soul)
	elif not summoner_ref.subjugated_souls.is_empty():
		_select_soul(summoner_ref.subjugated_souls[0])
	else:
		_clear_details()

func _select_soul(soul: SubjugatedSoulData) -> void:
	selected_soul = soul
	if not selected_soul:
		_clear_details()
		return
	
	if detail_name_label:
		detail_name_label.text = selected_soul.soldier_name
	if detail_class_label:
		detail_class_label.text = "Classe: %s  |  Facção: %s" % [selected_soul.get_class_name_string(), GameEnums.Faction.keys()[selected_soul.faction]]
	if detail_stats_label:
		detail_stats_label.text = "Vida: %.0f  |  Ataque: %.0f  |  Velocidade: %.0f  |  Custo Éter: %.0f" % [
			selected_soul.max_health,
			selected_soul.attack_damage,
			selected_soul.move_speed,
			selected_soul.summon_ether_cost
		]
	if detail_lore_label:
		detail_lore_label.text = selected_soul.lore_description
	if detail_sacrifice_label:
		detail_sacrifice_label.text = "🔥 SACRIFÍCIO DAS CINZAS (BOOST TEMPORÁRIO):\n%s" % selected_soul.get_sacrifice_description()
	
	if detail_portrait:
		match selected_soul.soul_class:
			SubjugatedSoulData.SoulClass.TROPA_CHOQUE:
				detail_portrait.texture = PORTRAIT_ORC
			SubjugatedSoulData.SoulClass.FLANQUEADOR:
				detail_portrait.texture = PORTRAIT_CAVALEIRO
			SubjugatedSoulData.SoulClass.SUPORTE_DISTANCIA:
				detail_portrait.texture = PORTRAIT_GHUL
			SubjugatedSoulData.SoulClass.COMANDANTE:
				detail_portrait.texture = PORTRAIT_OLOG
			_:
				detail_portrait.texture = PORTRAIT_OLOG

	# Habilitar botões
	if btn_summon:
		btn_summon.disabled = selected_soul.is_summoned or (summoner_ref and summoner_ref.active_servants.size() >= summoner_ref.max_field_servants)
		btn_summon.text = "💀 JÁ INVOCADO EM CAMPO" if selected_soul.is_summoned else "💀 ERGUER EM BATALHA (Invocação)"
	
	if btn_sacrifice:
		btn_sacrifice.disabled = false
	
	if btn_escort:
		btn_escort.text = "🛡️ ESCOLTAR CARRASCO: [ ATIVO ]" if selected_soul.assigned_to_guardian else "🛡️ ESCOLTAR CARRASCO: [ DESATIVADO ]"

func _clear_details() -> void:
	selected_soul = null
	if detail_portrait: detail_portrait.texture = null
	if detail_name_label: detail_name_label.text = "Nenhuma alma selecionada"
	if detail_class_label: detail_class_label.text = ""
	if detail_stats_label: detail_stats_label.text = ""
	if detail_lore_label: detail_lore_label.text = "Capture guerreiros derrotando capitães e soldados nos campos fúnebres."
	if detail_sacrifice_label: detail_sacrifice_label.text = ""
	if btn_summon: btn_summon.disabled = true
	if btn_sacrifice: btn_sacrifice.disabled = true
	if btn_escort: btn_escort.disabled = true

func _on_summon_pressed() -> void:
	if summoner_ref and selected_soul:
		summoner_ref.summon_subjugated_soul(selected_soul)
		_refresh_ui()

func _on_sacrifice_pressed() -> void:
	if summoner_ref and selected_soul:
		summoner_ref.sacrifice_subjugated_soul(selected_soul)
		_refresh_ui()

func _on_escort_pressed() -> void:
	if summoner_ref and selected_soul:
		summoner_ref.toggle_guardian_escort(selected_soul)
		_refresh_ui()

func _assign_quick_slot(slot_num: int) -> void:
	if summoner_ref and selected_soul:
		if slot_num == 1:
			summoner_ref.quick_slot_1 = selected_soul
		elif slot_num == 2:
			summoner_ref.quick_slot_2 = selected_soul
		_refresh_ui()
