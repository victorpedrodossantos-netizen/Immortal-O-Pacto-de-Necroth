class_name DayNightCycle2D
extends CanvasModulate

## Gestor do Ciclo Solar/Lunar e Iluminação Ambiental 2D

signal time_of_day_changed(is_night: bool)
signal hour_updated(hour: float)

@export var day_length_seconds: float = 600.0 # Duração de um ciclo completo (10 minutos)
@export var current_hour: float = 12.0 # 0.0 a 24.0 (12 = Meio-dia)
@export var is_paused: bool = false

# Cores de transição
const COLOR_DAY: Color = Color(1.0, 0.98, 0.94, 1.0)
const COLOR_DUSK: Color = Color(0.85, 0.45, 0.35, 1.0)
const COLOR_NIGHT: Color = Color(0.18, 0.22, 0.34, 1.0)
const COLOR_DAWN: Color = Color(0.55, 0.62, 0.78, 1.0)

var is_currently_night: bool = false

func _ready() -> void:
	_update_lighting()

func _physics_process(delta: float) -> void:
	if is_paused:
		return
	
	# Avanço do tempo
	var hour_increment: float = (24.0 / day_length_seconds) * delta
	current_hour = fposmod(current_hour + hour_increment, 24.0)
	
	_update_lighting()
	emit_signal("hour_updated", current_hour)

func _update_lighting() -> void:
	var target_color: Color
	var night_state: bool = false
	
	if current_hour >= 6.0 and current_hour < 9.0:
		# Alvorecer (06h às 09h)
		var t: float = (current_hour - 6.0) / 3.0
		target_color = COLOR_DAWN.lerp(COLOR_DAY, t)
	elif current_hour >= 9.0 and current_hour < 17.0:
		# Dia Pleno (09h às 17h)
		target_color = COLOR_DAY
	elif current_hour >= 17.0 and current_hour < 20.0:
		# Crepúsculo (17h às 20h)
		var t: float = (current_hour - 17.0) / 3.0
		target_color = COLOR_DAY.lerp(COLOR_DUSK, t)
	elif current_hour >= 20.0 and current_hour < 22.0:
		# Transição para a Noite (20h às 22h)
		var t: float = (current_hour - 20.0) / 2.0
		target_color = COLOR_DUSK.lerp(COLOR_NIGHT, t)
		night_state = true
	else:
		# Noite Profunda (22h às 06h)
		target_color = COLOR_NIGHT
		night_state = true
	
	color = target_color
	
	if night_state != is_currently_night:
		is_currently_night = night_state
		emit_signal("time_of_day_changed", is_currently_night)

## Alterna instantaneamente entre Dia e Noite para testes
func toggle_day_night() -> void:
	if is_currently_night:
		current_hour = 12.0 # Meio-dia
	else:
		current_hour = 23.0 # Noite profunda
	_update_lighting()
	emit_signal("hour_updated", current_hour)
