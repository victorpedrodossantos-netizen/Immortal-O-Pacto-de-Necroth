class_name AlertIndicator2D
extends Node2D

## Indicador visual do estado de alerta (estilo MGS)

@onready var label: Label = $Label

func _ready() -> void:
	if not label:
		label = Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.position = Vector2(-20, -50)
		label.size = Vector2(40, 24)
		add_child(label)
	visible = false

func update_alert(level: GameEnums.AlertLevel) -> void:
	match level:
		GameEnums.AlertLevel.CALMO:
			visible = false
		GameEnums.AlertLevel.SUSPEITO:
			visible = true
			label.text = "?"
			label.modulate = Color(1.0, 0.85, 0.2) # Amarelo
		GameEnums.AlertLevel.INVESTIGANDO:
			visible = true
			label.text = "?!"
			label.modulate = Color(1.0, 0.55, 0.1) # Laranja
		GameEnums.AlertLevel.COMBATE_ATIVO:
			visible = true
			label.text = "!"
			label.modulate = Color(1.0, 0.15, 0.15) # Vermelho
			_bounce_effect()
		GameEnums.AlertLevel.BUSCA_CAUTELOSA:
			visible = true
			label.text = "..."
			label.modulate = Color(0.4, 0.7, 1.0) # Azul

func _bounce_effect() -> void:
	var tween: Tween = create_tween()
	scale = Vector2(1.5, 1.5)
	tween.tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BOUNCE)
