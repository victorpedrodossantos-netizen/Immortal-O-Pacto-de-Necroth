class_name CodexScreen
extends Control

## Tela do Códice das Cinzas (Grimório de Almas e Invocações de Necroth)

const MAIN_MENU_SCENE: String = "res://ui/screens/main_menu.tscn"

@onready var btn_back: Button = %BtnBack

func _ready() -> void:
	if btn_back:
		btn_back.pressed.connect(_on_back_pressed)

func _on_back_pressed() -> void:
	EventBus.scene_transition_requested.emit(MAIN_MENU_SCENE)
