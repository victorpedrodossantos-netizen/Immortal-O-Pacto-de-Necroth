class_name SettingsScreen
extends Control

## Tela de Configurações dos Sentidos (Áudio e Display)

const MAIN_MENU_SCENE: String = "res://ui/screens/main_menu.tscn"

@onready var slider_master: HSlider = %SliderMaster
@onready var slider_sfx: HSlider = %SliderSFX
@onready var slider_music: HSlider = %SliderMusic
@onready var check_fullscreen: CheckBox = %CheckFullscreen
@onready var btn_back: Button = %BtnBack

func _ready() -> void:
	if btn_back:
		btn_back.pressed.connect(_on_back_pressed)
	
	if slider_master:
		slider_master.value_changed.connect(_on_master_changed)
	if slider_sfx:
		slider_sfx.value_changed.connect(_on_sfx_changed)
	if slider_music:
		slider_music.value_changed.connect(_on_music_changed)
	if check_fullscreen:
		check_fullscreen.toggled.connect(_on_fullscreen_toggled)
		var mode: DisplayServer.WindowMode = DisplayServer.window_get_mode()
		check_fullscreen.button_pressed = (mode == DisplayServer.WINDOW_MODE_FULLSCREEN)

func _on_master_changed(val: float) -> void:
	AudioManager.set_master_volume(val)

func _on_sfx_changed(val: float) -> void:
	AudioManager.set_sfx_volume(val)

func _on_music_changed(val: float) -> void:
	AudioManager.set_music_volume(val)

func _on_fullscreen_toggled(pressed: bool) -> void:
	if pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_back_pressed() -> void:
	EventBus.scene_transition_requested.emit(MAIN_MENU_SCENE)
