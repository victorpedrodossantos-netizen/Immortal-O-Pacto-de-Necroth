class_name DimensionSelector
extends PanelContainer

## Componente de Seleção de Dimensão de Renderização
## Exibe os seletores de 2D (Ativo), 2.5D (Em Manutenção) e 3D (Em Manutenção).

@onready var check_2d: CheckBox = %Check2D
@onready var check_25d: CheckBox = %Check25D
@onready var check_3d: CheckBox = %Check3D
@onready var status_label: Label = %StatusLabel

func _ready() -> void:
	_setup_options()
	_update_visuals()

func _setup_options() -> void:
	check_2d.toggled.connect(_on_2d_toggled)
	check_25d.toggled.connect(_on_maintenance_toggled.bind("Modo 2.5D", check_25d))
	check_3d.toggled.connect(_on_maintenance_toggled.bind("Modo 3D", check_3d))

func _update_visuals() -> void:
	# Modo 2D: Ativo e selecionado
	check_2d.button_pressed = true
	check_2d.text = "Modo 2D (Ativo)"
	check_2d.disabled = false
	
	# Modos 2.5D e 3D: Bloqueados por projeto
	check_25d.button_pressed = false
	check_25d.text = "Modo 2.5D (Em Manutenção)"
	check_25d.disabled = true
	check_25d.tooltip_text = "O véu 2.5D está selado em manutenção mística pelos arquitetos."
	
	check_3d.button_pressed = false
	check_3d.text = "Modo 3D (Em Manutenção)"
	check_3d.disabled = true
	check_3d.tooltip_text = "O vórtice dimensional 3D requer liberação das etapas posteriores."
	
	if status_label:
		status_label.text = "Dimensão Atual: 2D (Fidelidade Plena)"

func _on_2d_toggled(pressed: bool) -> void:
	if not pressed:
		# Não permite desmarcar a única dimensão ativa
		check_2d.set_pressed_no_signal(true)
		return
	GameManager.set_dimension(GameEnums.DimensionMode.MODE_2D)
	if status_label:
		status_label.text = "Dimensão Atual: 2D (Fidelidade Plena)"

func _on_maintenance_toggled(pressed: bool, mode_name: String, checkbox: CheckBox) -> void:
	# Reverte imediatamente caso receba clique forçado
	checkbox.set_pressed_no_signal(false)
	if status_label:
		status_label.text = "%s está em manutenção e inacessível no momento." % mode_name
