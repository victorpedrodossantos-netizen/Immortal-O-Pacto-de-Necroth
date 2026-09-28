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
@onready var btn_make_captain: Button = %BtnMakeCaptain
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
		btn_quick_slot1.pressed.connect(func(): _toggle_group(1))
	if btn_quick_slot2:
		btn_quick_slot2.pressed.connect(func(): _toggle_group(2))
	if btn_make_captain:
		btn_make_captain.pressed.connect(_on_make_captain_pressed)

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
	
	# Atualiza status do exército e dos grupos
	var active_count: int = summoner_ref.active_servants.size()
	var max_count: int = summoner_ref.max_field_servants
	var g1_cap_name: String = summoner_ref.group_1_captain.soldier_name if summoner_ref.group_1_captain else "Nenhum"
	var g2_cap_name: String = summoner_ref.group_2_captain.soldier_name if summoner_ref.group_2_captain else "Nenhum"
	
	if army_status_label:
		army_status_label.text = "⚔️ TROPAS ATIVAS: %d/%d   |   🛡️ GRUPO 1: [👑 Capitão: %s | %d/5 tropas]   |   🛡️ GRUPO 2: [👑 Capitão: %s | %d/5 tropas]" % [
			active_count,
			max_count,
			g1_cap_name,
			summoner_ref.group_1_members.size(),
			g2_cap_name,
			summoner_ref.group_2_members.size()
		]
	
	# Limpar lista anterior de cartões
	if soul_container:
		for child in soul_container.get_children():
			child.queue_free()
		
		for soul in summoner_ref.subjugated_souls:
			var card_btn: Button = _create_soul_card_button(soul)
			soul_container.add_child(card_btn)
	
	if selected_soul and summoner_ref.subjugated_souls.has(selected_soul):
		_select_soul(selected_soul)
	elif not summoner_ref.subjugated_souls.is_empty():
		_select_soul(summoner_ref.subjugated_souls[0])
	else:
		_clear_details()

func _create_soul_card_button(soul: SubjugatedSoulData) -> Button:
	var card_btn: Button = Button.new()
	card_btn.custom_minimum_size = Vector2(0, 64)
	card_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_btn.clip_contents = true
	
	var is_selected: bool = (soul == selected_soul)
	var is_cap: bool = soul.is_group_captain
	
	card_btn.set_meta("soul", soul)
	_update_card_style(card_btn, soul, is_selected)
	
	# Conteúdo interno da carta (HBox)
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 10)
	card_btn.add_child(hbox)
	
	# Mini retrato da carta
	var portrait_thumb: TextureRect = TextureRect.new()
	portrait_thumb.custom_minimum_size = Vector2(46, 46)
	portrait_thumb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	portrait_thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait_thumb.texture = _get_soul_portrait(soul)
	portrait_thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(portrait_thumb)
	
	# Textos centrais
	var text_vbox: VBoxContainer = VBoxContainer.new()
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text_vbox.add_theme_constant_override("separation", 3)
	text_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(text_vbox)
	
	# Linha 1: Nome + Badge de Grupo
	var top_row: HBoxContainer = HBoxContainer.new()
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_vbox.add_child(top_row)
	
	var name_lbl: Label = Label.new()
	name_lbl.text = soul.soldier_name
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if is_cap:
		name_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	elif soul.assigned_group != 0:
		name_lbl.add_theme_color_override("font_color", Color(0.45, 0.9, 1.0))
	else:
		name_lbl.add_theme_color_override("font_color", Color(0.9, 0.92, 0.95))
	top_row.add_child(name_lbl)
	
	var badge_lbl: Label = Label.new()
	badge_lbl.add_theme_font_size_override("font_size", 11)
	if soul.is_summoned:
		badge_lbl.text = "[ EM CAMPO ]"
		badge_lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5))
	elif soul.assigned_group == 1:
		badge_lbl.text = "[👑 CAPITÃO G1]" if is_cap else "[⚔️ GRUPO 1]"
		badge_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2) if is_cap else Color(0.3, 0.85, 1.0))
	elif soul.assigned_group == 2:
		badge_lbl.text = "[👑 CAPITÃO G2]" if is_cap else "[⚔️ GRUPO 2]"
		badge_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2) if is_cap else Color(0.7, 0.5, 1.0))
	elif soul.assigned_to_guardian:
		badge_lbl.text = "[ESCOLTA]"
		badge_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	else:
		badge_lbl.text = "[ LIVRE ]"
		badge_lbl.add_theme_color_override("font_color", Color(0.5, 0.6, 0.65))
	top_row.add_child(badge_lbl)
	
	# Linha 2: Classe e Atributos rápidos
	var bot_row: HBoxContainer = HBoxContainer.new()
	bot_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_vbox.add_child(bot_row)
	
	var class_lbl: Label = Label.new()
	class_lbl.text = soul.get_class_name_string()
	class_lbl.add_theme_font_size_override("font_size", 11)
	class_lbl.add_theme_color_override("font_color", Color(0.65, 0.72, 0.78))
	class_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bot_row.add_child(class_lbl)
	
	var stats_lbl: Label = Label.new()
	stats_lbl.text = "❤️ %d  ⚔️ %d" % [int(soul.max_health), int(soul.attack_damage)]
	stats_lbl.add_theme_font_size_override("font_size", 11)
	stats_lbl.add_theme_color_override("font_color", Color(1.0, 0.75, 0.45))
	bot_row.add_child(stats_lbl)
	
	card_btn.pressed.connect(func(): _select_soul(soul))
	return card_btn

func _update_card_style(card_btn: Button, soul: SubjugatedSoulData, is_selected: bool) -> void:
	var is_cap: bool = soul.is_group_captain
	var sb_normal: StyleBoxFlat = StyleBoxFlat.new()
	sb_normal.corner_radius_top_left = 6
	sb_normal.corner_radius_top_right = 6
	sb_normal.corner_radius_bottom_right = 6
	sb_normal.corner_radius_bottom_left = 6
	sb_normal.content_margin_left = 8
	sb_normal.content_margin_right = 8
	sb_normal.content_margin_top = 6
	sb_normal.content_margin_bottom = 6
	
	if is_selected:
		sb_normal.bg_color = Color(0.08, 0.13, 0.17, 0.98)
		sb_normal.border_color = Color(1.0, 0.88, 0.35, 1.0) if is_cap else Color(0.145, 0.886, 0.596, 1.0)
		sb_normal.border_width_left = 2
		sb_normal.border_width_top = 2
		sb_normal.border_width_right = 2
		sb_normal.border_width_bottom = 2
	elif is_cap:
		sb_normal.bg_color = Color(0.065, 0.055, 0.04, 0.95)
		sb_normal.border_color = Color(0.9, 0.75, 0.25, 0.75)
		sb_normal.border_width_left = 1
		sb_normal.border_width_top = 1
		sb_normal.border_width_right = 1
		sb_normal.border_width_bottom = 1
	elif soul.assigned_group != 0:
		sb_normal.bg_color = Color(0.04, 0.06, 0.085, 0.95)
		sb_normal.border_color = Color(0.2, 0.45, 0.6, 0.6)
		sb_normal.border_width_left = 1
		sb_normal.border_width_top = 1
		sb_normal.border_width_right = 1
		sb_normal.border_width_bottom = 1
	else:
		sb_normal.bg_color = Color(0.035, 0.045, 0.06, 0.9)
		sb_normal.border_color = Color(0.12, 0.16, 0.22, 0.7)
		sb_normal.border_width_left = 1
		sb_normal.border_width_top = 1
		sb_normal.border_width_right = 1
		sb_normal.border_width_bottom = 1
	
	var sb_hover: StyleBoxFlat = sb_normal.duplicate()
	sb_hover.bg_color = Color(0.09, 0.12, 0.16, 1.0)
	sb_hover.border_color = Color(0.145, 0.886, 0.596, 0.9)
	
	card_btn.add_theme_stylebox_override("normal", sb_normal)
	card_btn.add_theme_stylebox_override("hover", sb_hover)
	card_btn.add_theme_stylebox_override("pressed", sb_hover)

func _get_soul_portrait(soul: SubjugatedSoulData) -> Texture2D:
	if not soul:
		return PORTRAIT_OLOG
	match soul.soul_class:
		SubjugatedSoulData.SoulClass.TROPA_CHOQUE:
			return PORTRAIT_ORC
		SubjugatedSoulData.SoulClass.FLANQUEADOR:
			return PORTRAIT_CAVALEIRO
		SubjugatedSoulData.SoulClass.SUPORTE_DISTANCIA:
			return PORTRAIT_GHUL
		SubjugatedSoulData.SoulClass.COMANDANTE:
			return PORTRAIT_OLOG
		_:
			return PORTRAIT_OLOG

func _select_soul(soul: SubjugatedSoulData) -> void:
	selected_soul = soul
	if not selected_soul:
		_clear_details()
		return
	
	# Atualiza o realce visual das cartas na lista
	if soul_container:
		for card in soul_container.get_children():
			if card is Button and card.has_meta("soul"):
				var c_soul: SubjugatedSoulData = card.get_meta("soul")
				_update_card_style(card, c_soul, c_soul == selected_soul)
	
	if detail_name_label:
		if selected_soul.is_group_captain:
			detail_name_label.text = "👑 %s" % selected_soul.soldier_name
			detail_name_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
		else:
			detail_name_label.text = selected_soul.soldier_name
			detail_name_label.add_theme_color_override("font_color", Color(0.145, 0.886, 0.596))
	
	if detail_class_label:
		var grp_txt: String = ("👑 Grupo %d (Capitão)" % selected_soul.assigned_group) if selected_soul.is_group_captain else (("⚔️ Grupo %d (Membro)" % selected_soul.assigned_group) if selected_soul.assigned_group != 0 else "⚪ Não Alocado (Livre)")
		detail_class_label.text = "⚔️ %s   •   🏛️ %s   •   🛡️ %s" % [selected_soul.get_class_name_string(), GameEnums.Faction.keys()[selected_soul.faction], grp_txt]
	
	if detail_stats_label:
		detail_stats_label.text = "❤️ VIDA: %d    ⚔️ ATAQUE: %d    ⚡ VELOCIDADE: %d    🔮 ÉTER: %d" % [
			int(selected_soul.max_health),
			int(selected_soul.attack_damage),
			int(selected_soul.move_speed),
			int(selected_soul.summon_ether_cost)
		]
	
	if has_node("%StatHpLabel"): %StatHpLabel.text = "%d" % int(selected_soul.max_health)
	if has_node("%StatAtkLabel"): %StatAtkLabel.text = "%d" % int(selected_soul.attack_damage)
	if has_node("%StatSpdLabel"): %StatSpdLabel.text = "%d" % int(selected_soul.move_speed)
	if has_node("%StatEtherLabel"): %StatEtherLabel.text = "%d" % int(selected_soul.summon_ether_cost)
	
	if detail_lore_label:
		detail_lore_label.text = '"%s"' % selected_soul.lore_description
	
	if detail_sacrifice_label:
		detail_sacrifice_label.text = "🔥 SACRIFÍCIO DAS CINZAS (PODER FÚNEBRE IMEDIATO):\n%s" % selected_soul.get_sacrifice_description()
	
	if detail_portrait:
		detail_portrait.texture = _get_soul_portrait(selected_soul)

	# Habilitar botões de invocação e sacrifício
	if btn_summon:
		btn_summon.disabled = selected_soul.is_summoned or (summoner_ref and summoner_ref.active_servants.size() >= summoner_ref.max_field_servants)
		btn_summon.text = "💀 JÁ INVOCADO EM CAMPO" if selected_soul.is_summoned else "💀 ERGUER EM BATALHA"
	
	if btn_sacrifice:
		btn_sacrifice.disabled = false
	
	if btn_escort:
		btn_escort.text = "🛡️ ESCOLTAR CARRASCO: [ ATIVO ]" if selected_soul.assigned_to_guardian else "🛡️ ESCOLTAR CARRASCO: [ DESATIVADO ]"

	# Atualizar textos e estados dos botões de Grupo
	if btn_quick_slot1:
		btn_quick_slot1.disabled = false
		if selected_soul.assigned_group == 1:
			btn_quick_slot1.text = "✖️ REMOVER DO GRUPO 1"
		else:
			btn_quick_slot1.text = "⚔️ INSERIR NO GRUPO 1"
	
	if btn_quick_slot2:
		btn_quick_slot2.disabled = false
		if selected_soul.assigned_group == 2:
			btn_quick_slot2.text = "✖️ REMOVER DO GRUPO 2"
		else:
			btn_quick_slot2.text = "⚔️ INSERIR NO GRUPO 2"
	
	if btn_make_captain:
		btn_make_captain.disabled = false
		if selected_soul.is_group_captain:
			btn_make_captain.text = "👑 JÁ É O CAPITÃO DO GRUPO %d" % selected_soul.assigned_group
			btn_make_captain.disabled = true
		elif selected_soul.assigned_group != 0:
			btn_make_captain.text = "👑 PROMOVER A CAPITÃO DO GRUPO %d" % selected_soul.assigned_group
		else:
			btn_make_captain.text = "👑 TORNAR CAPITÃO DO GRUPO 1"

func _clear_details() -> void:
	selected_soul = null
	if detail_portrait: detail_portrait.texture = null
	if detail_name_label: detail_name_label.text = "Nenhuma alma selecionada"
	if detail_class_label: detail_class_label.text = ""
	if detail_stats_label: detail_stats_label.text = ""
	if has_node("%StatHpLabel"): %StatHpLabel.text = "-"
	if has_node("%StatAtkLabel"): %StatAtkLabel.text = "-"
	if has_node("%StatSpdLabel"): %StatSpdLabel.text = "-"
	if has_node("%StatEtherLabel"): %StatEtherLabel.text = "-"
	if detail_lore_label: detail_lore_label.text = "Capture guerreiros derrotando capitães e soldados nos campos fúnebres."
	if detail_sacrifice_label: detail_sacrifice_label.text = ""
	if btn_summon: btn_summon.disabled = true
	if btn_sacrifice: btn_sacrifice.disabled = true
	if btn_escort: btn_escort.disabled = true
	if btn_quick_slot1: btn_quick_slot1.disabled = true
	if btn_quick_slot2: btn_quick_slot2.disabled = true
	if btn_make_captain: btn_make_captain.disabled = true

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

func _toggle_group(group_num: int) -> void:
	if summoner_ref and selected_soul:
		summoner_ref.assign_soul_to_group(selected_soul, group_num)
		_refresh_ui()

func _on_make_captain_pressed() -> void:
	if summoner_ref and selected_soul:
		summoner_ref.promote_to_group_captain(selected_soul)
		_refresh_ui()
