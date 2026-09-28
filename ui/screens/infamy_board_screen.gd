class_name InfamyBoardScreen
extends Control

## Tela da Tábua da Infâmia (Ascensão de Sangue)
## Apresenta os capitães de facção, traços de combate, status e cicatrizes.

const MAIN_MENU_SCENE: String = "res://ui/screens/main_menu.tscn"

@onready var warlords_container: VBoxContainer = %WarlordsContainer
@onready var btn_back: Button = %BtnBack

func _ready() -> void:
	if btn_back:
		btn_back.pressed.connect(_on_back_pressed)
	_render_warlord_cards()

func _render_warlord_cards() -> void:
	if not warlords_container:
		return
	
	# Limpa instâncias anteriores
	for child in warlords_container.get_children():
		child.queue_free()
	
	var warlords: Array[WarlordData] = InfamyManager.warlords
	
	for w in warlords:
		var panel: PanelContainer = PanelContainer.new()
		var margin: MarginContainer = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 16)
		margin.add_theme_constant_override("margin_right", 16)
		margin.add_theme_constant_override("margin_top", 12)
		margin.add_theme_constant_override("margin_bottom", 12)
		
		var vbox: VBoxContainer = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 6)
		
		var header_hbox: HBoxContainer = HBoxContainer.new()
		
		var title_label: Label = Label.new()
		title_label.text = "[Tier %d] %s" % [w.tier, w.get_full_title()]
		title_label.add_theme_font_size_override("font_size", 18)
		if w.tier == 3:
			title_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.25))
		elif w.tier == 2:
			title_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.4))
		else:
			title_label.add_theme_color_override("font_color", Color(0.75, 0.82, 0.85))
		title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header_hbox.add_child(title_label)
		
		var status_label: Label = Label.new()
		if w.is_alive:
			status_label.text = "[ VIVO • AMEAÇA ATIVA ]"
			status_label.add_theme_color_override("font_color", Color(0.145, 0.886, 0.596))
		else:
			status_label.text = "[ TOMBADO PELO PACTO ]"
			status_label.add_theme_color_override("font_color", Color(0.65, 0.25, 0.25))
		header_hbox.add_child(status_label)
		
		vbox.add_child(header_hbox)
		
		var details_label: Label = Label.new()
		var str_strengths: String = ", ".join(w.strengths) if w.strengths.size() > 0 else "Nenhuma conhecida"
		var str_weaknesses: String = ", ".join(w.weaknesses) if w.weaknesses.size() > 0 else "Nenhuma conhecida"
		details_label.text = "Poder: %d | Forças: %s | Fraquezas: %s" % [w.power_level, str_strengths, str_weaknesses]
		details_label.add_theme_color_override("font_color", Color(0.65, 0.72, 0.75))
		details_label.add_theme_font_size_override("font_size", 13)
		vbox.add_child(details_label)
		
		if w.scars.size() > 0:
			var scar_label: Label = Label.new()
			scar_label.text = "Histórico: %s" % "; ".join(w.scars)
			scar_label.add_theme_color_override("font_color", Color(0.85, 0.6, 0.4))
			scar_label.add_theme_font_size_override("font_size", 12)
			vbox.add_child(scar_label)
		
		margin.add_child(vbox)
		panel.add_child(margin)
		warlords_container.add_child(panel)

func _on_back_pressed() -> void:
	EventBus.scene_transition_requested.emit(MAIN_MENU_SCENE)
