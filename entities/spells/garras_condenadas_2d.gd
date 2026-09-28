class_name GarrasCondenadas2D
extends Area2D

## Magia Negra de Área: Garras dos Condenados
## Irrompe mãos esqueléticas e lodo profano do solo, causando dano por tick e lentidão severa.

@export var duration: float = 2.8
@export var damage_per_tick: float = 14.0
@export var tick_interval: float = 0.35
@export var slow_factor: float = 0.4 # Reduz a velocidade em 60%

var caster: Node2D = null
var elapsed_time: float = 0.0
var tick_timer: float = 0.0
var trapped_enemies: Array[BaseCharacter] = []

@onready var visual_root: Node2D = $Visual
@onready var particles: CPUParticles2D = $CPUParticles2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Animação inicial de surgimento das garras
	if visual_root:
		visual_root.scale = Vector2.ZERO
		var tween: Tween = create_tween()
		tween.tween_property(visual_root, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	AudioManager.play_sfx(AudioManager.stream_cast, 1.5)

func setup(caster_node: Node2D) -> void:
	caster = caster_node

func _physics_process(delta: float) -> void:
	elapsed_time += delta
	tick_timer += delta
	
	# Aplica dano contínuo e renova lentidão
	if tick_timer >= tick_interval:
		tick_timer = 0.0
		_apply_tick_damage()
	
	# Desvanecimento no final da duração
	if elapsed_time >= (duration - 0.4) and visual_root:
		var alpha: float = maxf(0.0, (duration - elapsed_time) / 0.4)
		visual_root.modulate.a = alpha
	
	if elapsed_time >= duration:
		_cleanup_and_finish()

func _apply_tick_damage() -> void:
	# Limpar referências mortas
	trapped_enemies = trapped_enemies.filter(func(e): return is_instance_valid(e) and not e.is_dead)
	
	for enemy in trapped_enemies:
		enemy.take_damage(damage_per_tick, caster)
		# Efeito de tremor/sangue espectral
		var tween: Tween = enemy.create_tween()
		tween.tween_property(enemy, "modulate", Color(0.2, 0.9, 0.4, 1.0), 0.08)
		tween.tween_property(enemy, "modulate", Color(1, 1, 1, 1), 0.1)

func _on_body_entered(body: Node2D) -> void:
	if body == caster:
		return
	if body is BaseCharacter and body.faction != GameEnums.Faction.PACTO_NECROTH and not body.is_dead:
		if not trapped_enemies.has(body):
			trapped_enemies.append(body)
			# Aplica lentidão
			body.move_speed *= slow_factor

func _on_body_exited(body: Node2D) -> void:
	if body is BaseCharacter and trapped_enemies.has(body):
		trapped_enemies.erase(body)
		# Restaura velocidade original
		if is_instance_valid(body) and not body.is_dead:
			body.move_speed /= slow_factor

func _cleanup_and_finish() -> void:
	# Restaurar velocidade de todos que ainda estavam dentro
	for enemy in trapped_enemies:
		if is_instance_valid(enemy) and not enemy.is_dead:
			enemy.move_speed /= slow_factor
	trapped_enemies.clear()
	queue_free()
