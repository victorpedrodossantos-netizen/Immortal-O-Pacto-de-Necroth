class_name MainMenu
extends Control

## Controlador da Tela Principal de "Immortal: O Pacto de Necroth"

const TEST_CHAMBER_SCENE: String = "res://scenes/test_chamber_2d.tscn"
const INFAMY_SCENE: String = "res://ui/screens/infamy_board_screen.tscn"
const CODEX_SCENE: String = "res://ui/screens/codex_screen.tscn"
const SETTINGS_SCENE: String = "res://ui/screens/settings_screen.tscn"

@onready var btn_play: Button = %BtnPlay
@onready var btn_codex: Button = %BtnCodex
@onready var btn_infamy: Button = %BtnInfamy
@onready var btn_settings: Button = %BtnSettings
@onready var btn_quit: Button = %BtnQuit
@onready var info_dialog: AcceptDialog = %InfoDialog

func _ready() -> void:
	_connect_buttons()
	btn_play.grab_focus()

func _connect_buttons() -> void:
	btn_play.pressed.connect(_on_play_pressed)
	btn_codex.pressed.connect(_on_codex_pressed)
	btn_infamy.pressed.connect(_on_infamy_pressed)
	btn_settings.pressed.connect(_on_settings_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)

func _on_play_pressed() -> void:
	if GameManager.current_dimension == GameEnums.DimensionMode.MODE_2D:
		EventBus.scene_transition_requested.emit(TEST_CHAMBER_SCENE)
	else:
		_show_info("Plano Interditado", "Apenas o plano 2D está aberto para os ritos de Necroth no momento.")

func _on_codex_pressed() -> void:
	EventBus.scene_transition_requested.emit(CODEX_SCENE)

func _on_infamy_pressed() -> void:
	EventBus.scene_transition_requested.emit(INFAMY_SCENE)

func _on_settings_pressed() -> void:
	EventBus.scene_transition_requested.emit(SETTINGS_SCENE)

func _on_quit_pressed() -> void:
	get_tree().quit()

func _show_info(title: String, text: String) -> void:
	if info_dialog:
		info_dialog.title = title
		info_dialog.dialog_text = text
		info_dialog.popup_centered()
