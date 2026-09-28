class_name AbilityHotbar
extends PanelContainer

## Barra de Habilidades (Hotbar) estilo Diablo para Necroth
## Contém os 7 slots com artes de demonstração, teclas no centro e nomes inferiores.

const HotbarSlot = preload("res://ui/components/hotbar_slot.gd")

@onready var slot_ceifa: HotbarSlot = %SlotCeifa
@onready var slot_garras: HotbarSlot = %SlotGarras
@onready var slot_sifao: HotbarSlot = %SlotSifao
@onready var slot_dash: HotbarSlot = %SlotDash
@onready var slot_carrasco: HotbarSlot = %SlotCarrasco
@onready var slot_focus: HotbarSlot = %SlotFocus
@onready var slot_grimoire: HotbarSlot = %SlotGrimoire

var necroth_ref: Node2D = null

func _ready() -> void:
	# Configurações de custos de Éter
	if slot_garras: slot_garras.ether_cost = 25.0
	if slot_sifao: slot_sifao.ether_cost = 12.0
	if slot_carrasco: slot_carrasco.ether_cost = 40.0

func setup_necroth(player_node: Node2D) -> void:
	necroth_ref = player_node
	if necroth_ref and necroth_ref.has_signal("ether_changed"):
		necroth_ref.ether_changed.connect(_on_necroth_ether_changed)
		_on_necroth_ether_changed(necroth_ref.current_ether, necroth_ref.max_ether)

func _on_necroth_ether_changed(current_ether: float, _max_ether: float) -> void:
	if slot_garras: slot_garras.update_ether_availability(current_ether)
	if slot_sifao: slot_sifao.update_ether_availability(current_ether)
	if slot_carrasco: slot_carrasco.update_ether_availability(current_ether)

## Reage às teclas acionadas para dar feedback de flash visual idêntico ao Diablo
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if slot_ceifa: slot_ceifa.flash_activation()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if slot_focus: slot_focus.flash_activation()
	
	elif event is InputEventKey and event.pressed and not event.is_echo():
		match event.keycode:
			KEY_1:
				if slot_ceifa:
					slot_ceifa.flash_activation()
			KEY_2:
				if slot_garras:
					slot_garras.flash_activation()
					slot_garras.start_cooldown(1.2)
			KEY_3:
				if slot_sifao:
					slot_sifao.flash_activation()
			KEY_4, KEY_SPACE:
				if slot_dash:
					slot_dash.flash_activation()
					slot_dash.start_cooldown(0.8) # Cooldown padrão do Passo Umbral
			KEY_5:
				if slot_carrasco:
					slot_carrasco.flash_activation()
			KEY_6:
				if slot_focus:
					slot_focus.flash_activation()
			KEY_7, KEY_TAB:
				if slot_grimoire:
					slot_grimoire.flash_activation()
