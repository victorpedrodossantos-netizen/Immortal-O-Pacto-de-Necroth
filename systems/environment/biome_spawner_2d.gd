class_name BiomeSpawner2D
extends Node2D

## Gerenciador Autônomo de Ecologia e Habitats de Bioma
## Cada espécie habita e se regenera organicamente em seu ecossistema adequado:
## - Pútridos do Limo (Ghûls): Pântano pantanoso a Sudoeste (Vector2(-950, 400))
## - Olog-Titã (Colosso Destruidor): Pilares de Pedra do Norte (Vector2(-550, -450))
## - Fendidos de Ferro (Orcs Táticos): Desfiladeiros e Rotas Militares a Leste (Vector2(500, 0))

const FENDIDO_SCENE: PackedScene = preload("res://entities/characters/enemies/tactical_fendido_enemy.tscn")
const PUTRIDO_SCENE: PackedScene = preload("res://entities/characters/enemies/putrido_enxame_enemy.tscn")
const OLOG_SCENE: PackedScene = preload("res://entities/characters/enemies/olog_tita_enemy.tscn")

@export var enemy_container: Node2D
@export var tactical_director: TacticalDirector2D

# Configurações de Habitats
const SWAMP_MIN: Vector2 = Vector2(-1150, 220)
const SWAMP_MAX: Vector2 = Vector2(-750, 580)
const OLOG_TERRITORY_CENTER: Vector2 = Vector2(-550, -450)
const ORC_PATROL_POSITIONS: Array[Vector2] = [
	Vector2(450, -220),
	Vector2(600, 0),
	Vector2(450, 220)
]

var is_night: bool = false
var ecology_timer: float = 0.0
const ECOLOGY_CHECK_INTERVAL: float = 12.0

func _ready() -> void:
	# Inicialização autônoma se os containers já estiverem atribuídos
	if enemy_container:
		populate_initial_ecosystem()

func _physics_process(delta: float) -> void:
	if not enemy_container:
		return
	
	ecology_timer += delta
	if ecology_timer >= ECOLOGY_CHECK_INTERVAL:
		ecology_timer = 0.0
		_check_and_replenish_habitats()

func setup_cycle(day_night: DayNightCycle2D) -> void:
	if day_night:
		day_night.time_of_day_changed.connect(_on_time_of_day_changed)

func _on_time_of_day_changed(night_active: bool) -> void:
	is_night = night_active
	if is_night:
		_trigger_night_swarming()
	else:
		_trigger_day_patrols()

## Popula todo o ecossistema com todos os monstros em seus respectivos habitats naturais
func populate_initial_ecosystem() -> void:
	if not enemy_container:
		return
	
	for child in enemy_container.get_children():
		child.queue_free()
	
	# 1. Pântano do Limo: Ghûls Pútridos emergindo da lama
	var ghul_count: int = 5 if is_night else 3
	for i in range(ghul_count):
		_spawn_putrido_in_swamp()
	
	# 2. Pilares de Pedra do Norte: Olog-Titã
	_spawn_olog_guardian()
	
	# 3. Rotas Militares do Leste: Fendidos de Ferro Táticos
	for pos in ORC_PATROL_POSITIONS:
		_spawn_fendido_soldier(pos)
	
	EventBus.tactical_pressure_updated.emit("ECOSSISTEMA_ESTABELECIDO", 60.0)

## Verifica as populações de cada habitat e realiza o repovoamento orgânico autônomo
func _check_and_replenish_habitats() -> void:
	if not enemy_container:
		return
	
	var putrido_count: int = 0
	var olog_count: int = 0
	var fendido_count: int = 0
	
	for child in enemy_container.get_children():
		if not is_instance_valid(child):
			continue
		if child is PutridoEnxameEnemy or child.is_in_group("putridos"):
			putrido_count += 1
		elif child is OlogTitaEnemy or child.is_in_group("ologs"):
			olog_count += 1
		elif child is TacticalFendidoEnemy or child.is_in_group("fendidos"):
			fendido_count += 1
	
	# Manutenção do Pântano
	var target_ghuls: int = 6 if is_night else 3
	if putrido_count < target_ghuls:
		var needed: int = target_ghuls - putrido_count
		for i in range(mini(needed, 2)):
			_spawn_putrido_in_swamp()
	
	# Manutenção do Titã do Norte
	if olog_count < 1:
		_spawn_olog_guardian()
	
	# Manutenção das Rotas Militares dos Orcs
	var target_orcs: int = 2 if is_night else 3
	if fendido_count < target_orcs:
		var free_pos = ORC_PATROL_POSITIONS.pick_random()
		_spawn_fendido_soldier(free_pos)

func _spawn_putrido_in_swamp() -> void:
	var putrido: Node2D = PUTRIDO_SCENE.instantiate()
	var random_x: float = randf_range(SWAMP_MIN.x, SWAMP_MAX.x)
	var random_y: float = randf_range(SWAMP_MIN.y, SWAMP_MAX.y)
	putrido.global_position = Vector2(random_x, random_y)
	putrido.add_to_group("putridos")
	enemy_container.add_child(putrido)

func _spawn_olog_guardian() -> void:
	var olog: Node2D = OLOG_SCENE.instantiate()
	olog.global_position = OLOG_TERRITORY_CENTER + Vector2(randf_range(-60, 60), randf_range(-40, 40))
	olog.add_to_group("ologs")
	enemy_container.add_child(olog)

func _spawn_fendido_soldier(pos: Vector2) -> void:
	var fendido: Node2D = FENDIDO_SCENE.instantiate()
	fendido.global_position = pos + Vector2(randf_range(-30, 30), randf_range(-30, 30))
	fendido.add_to_group("fendidos")
	enemy_container.add_child(fendido)
	if tactical_director and fendido.has_method("register_unit"):
		tactical_director.register_unit(fendido)

func _trigger_night_swarming() -> void:
	# Ao cair da noite, o pântano entra em fúria e novos ghûls saem da lama
	for i in range(3):
		_spawn_putrido_in_swamp()
	EventBus.tactical_pressure_updated.emit("ENXAME_NOTURNO_ATIVO", 85.0)

func _trigger_day_patrols() -> void:
	# Ao amanhecer, a guarnição orc reforça a patrulha das rotas
	EventBus.tactical_pressure_updated.emit("PATRULHA_DIURNA_REFORCADA", 50.0)
