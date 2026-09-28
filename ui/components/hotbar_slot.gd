class_name HotbarSlot
extends VBoxContainer

## Slot Individual de Habilidade no estilo Diablo
## Exibe a imagem de demonstração da habilidade, a tecla de atalho centralizada e o nome inferior.

@export var ability_name: String = "Habilidade":
	set(val):
		ability_name = val
		if name_label: name_label.text = ability_name

@export var shortcut_key: String = "1":
	set(val):
		shortcut_key = val
		if key_label: key_label.text = shortcut_key

@export var skill_icon: Texture2D:
	set(val):
		skill_icon = val
		if icon_rect: icon_rect.texture = skill_icon

@export var ether_cost: float = 0.0

@onready var icon_rect: TextureRect = %IconRect
@onready var key_label: Label = %KeyLabel
@onready var name_label: Label = %NameLabel
@onready var cooldown_overlay: ColorRect = %CooldownOverlay
@onready var cooldown_label: Label = %CooldownLabel
@onready var frame_panel: PanelContainer = %FramePanel

var current_cooldown: float = 0.0
var max_cooldown: float = 0.0

func _ready() -> void:
	if name_label: name_label.text = ability_name
	if key_label: key_label.text = shortcut_key
	if icon_rect and skill_icon: icon_rect.texture = skill_icon
	if cooldown_overlay: cooldown_overlay.visible = false
	if cooldown_label: cooldown_label.text = ""

func _process(delta: float) -> void:
	if current_cooldown > 0.0:
		current_cooldown -= delta
		if current_cooldown <= 0.0:
			current_cooldown = 0.0
			if cooldown_overlay: cooldown_overlay.visible = false
			if cooldown_label: cooldown_label.text = ""
		else:
			if cooldown_overlay: cooldown_overlay.visible = true
			if cooldown_label: cooldown_label.text = "%.1fs" % current_cooldown

func start_cooldown(duration: float) -> void:
	if duration <= 0.0:
		return
	max_cooldown = duration
	current_cooldown = duration
	if cooldown_overlay: cooldown_overlay.visible = true
	if cooldown_label: cooldown_label.text = "%.1fs" % current_cooldown

func flash_activation() -> void:
	if frame_panel:
		var tween: Tween = create_tween()
		tween.tween_property(frame_panel, "modulate", Color(1.8, 1.8, 1.4, 1.0), 0.08)
		tween.tween_property(frame_panel, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)

func update_ether_availability(available_ether: float) -> void:
	if ether_cost > 0.0 and available_ether < ether_cost:
		modulate = Color(0.65, 0.65, 0.7, 0.8) # Esmaecido por falta de éter
	else:
		modulate = Color(1.0, 1.0, 1.0, 1.0)
