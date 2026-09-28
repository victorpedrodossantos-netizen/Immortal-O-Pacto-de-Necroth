class_name SifaoDaMorte2D
extends Node2D

## Magia Negra Canalizada: Sifão da Morte
## Cria um tentáculo espectral entre Necroth e o alvo, drenando vida e arrancando a alma.

@export var dps: float = 38.0
@export var ether_cost_per_sec: float = 12.0
@export var drain_heal_ratio: float = 0.45
@export var max_range: float = 420.0

var caster: Node2D = null
var target: BaseCharacter = null
var is_active: bool = false
var time_alive: float = 0.0

@onready var beam_line: Line2D = $BeamLine
@onready var particles: CPUParticles2D = $CPUParticles2D

func setup(caster_node: Node2D, target_node: BaseCharacter) -> void:
	caster = caster_node
	target = target_node
	is_active = true
	global_position = caster.global_position
	AudioManager.play_sfx(AudioManager.stream_cast, 1.2)

func _process(delta: float) -> void:
	if not is_active:
		return
	
	if not is_instance_valid(caster) or caster.is_dead:
		stop_drain()
		return
	
	if not is_instance_valid(target) or target.is_dead:
		# Se o alvo morreu durante o canal, ceifa a alma imediatamente
		if is_instance_valid(caster) and is_instance_valid(target):
			_instant_soul_harvest()
		stop_drain()
		return
	
	# Verifica alcance
	var dist: float = caster.global_position.distance_to(target.global_position)
	if dist > max_range:
		stop_drain()
		return
	
	# Consome Éter do conjurador
	if caster.current_ether < (ether_cost_per_sec * delta):
		stop_drain()
		return
	
	caster.current_ether -= ether_cost_per_sec * delta
	caster.emit_signal("ether_changed", caster.current_ether, caster.max_ether)
	
	# Aplica dano contínuo ao alvo
	var damage_amount: float = dps * delta
	target.take_damage(damage_amount, caster)
	
	# Drena vida e transfere para Necroth
	var heal_amount: float = damage_amount * drain_heal_ratio
	caster.heal(heal_amount)
	
	# Atualiza o feixe visual ondulante
	time_alive += delta * 12.0
	_update_beam_visual()

func _update_beam_visual() -> void:
	if not beam_line:
		return
	
	var start_pos: Vector2 = caster.global_position
	var end_pos: Vector2 = target.global_position
	global_position = start_pos
	
	var points: PackedVector2Array = PackedVector2Array()
	var segments: int = 14
	var to_target: Vector2 = end_pos - start_pos
	var normal: Vector2 = Vector2(-to_target.y, to_target.x).normalized()
	
	for i in range(segments + 1):
		var t: float = float(i) / float(segments)
		var p: Vector2 = to_target * t
		# Ondulação senoidal de tentáculo sombrio
		if i > 0 and i < segments:
			var wave: float = sin(time_alive + (t * 6.0)) * 12.0 * sin(t * PI)
			p += normal * wave
		points.append(p)
	
	beam_line.points = points
	if particles:
		particles.global_position = end_pos

func _instant_soul_harvest() -> void:
	if caster:
		var bonus_soul: SoulData = SoulData.new()
		bonus_soul.id = "alma_drenada"
		bonus_soul.soul_name = "Alma Extorquida pelo Sifão"
		bonus_soul.energy_value = 25.0
		caster.harvest_soul(bonus_soul)
		AudioManager.play_sfx(AudioManager.stream_hit, 2.5)

func stop_drain() -> void:
	is_active = false
	if beam_line:
		var tween: Tween = create_tween()
		tween.tween_property(beam_line, "modulate:a", 0.0, 0.15)
		tween.tween_callback(queue_free)
	else:
		queue_free()
