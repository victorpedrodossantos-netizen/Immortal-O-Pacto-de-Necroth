class_name BiomeSpawner2D
extends Node2D

## Gerenciador Autônomo de Ecologia, Territórios e Capitães Nêmesis
## Cada espécie habita e domina seu próprio território no mapa expandido (7600x5600):
## - Pútridos do Limo (Ghûls): Pântano Sombrio a Sudoeste (-2200, 1400)
## - Ologs & Trolls (Titãs Colossais): Cume dos Titãs a Noroeste (-2200, -1400)
## - Fendidos de Ferro (Orcs Táticos): Bastião de Guerra a Leste (2200, 0)
## - Centro (0, 0): Santuário Ritual de Necroth

const FENDIDO_SCENE: PackedScene = preload("res://entities/characters/enemies/tactical_fendido_enemy.tscn")
const PUTRIDO_ENXAME_SCENE: PackedScene = preload("res://entities/characters/enemies/putrido_enxame_enemy.tscn")
const PUTRIDO_LIMO_SCENE: PackedScene = preload("res://entities/characters/enemies/putrido_do_limo.tscn")
const OLOG_SCENE: PackedScene = preload("res://entities/characters/enemies/olog_tita_enemy.tscn")

@export var enemy_container: Node2D
@export var tactical_director: TacticalDirector2D

# Configurações de Territórios Expandidos
const SWAMP_BOUNDS_MIN: Vector2 = Vector2(-3100, 700)
const SWAMP_BOUNDS_MAX: Vector2 = Vector2(-1300, 2100)

const OLOG_TERRITORY_CENTER: Vector2 = Vector2(-2200, -1400)
const OLOG_BOUNDS_MIN: Vector2 = Vector2(-3100, -2100)
const OLOG_BOUNDS_MAX: Vector2 = Vector2(-1300, -700)

const ORC_CAMP_CENTER: Vector2 = Vector2(2200, 0)
const ORC_PATROL_POSITIONS: Array[Vector2] = [
	Vector2(1600, -700),
	Vector2(2000, -400),
	Vector2(2400, -150),
	Vector2(2600, 200),
	Vector2(2100, 600),
	Vector2(1700, 300),
	Vector2(2800, -500),
	Vector2(2500, 700)
]

var is_night: bool = false
var ecology_timer: float = 0.0
const ECOLOGY_CHECK_INTERVAL: float = 10.0

func _ready() -> void:
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

## Popula todo o ecossistema com Capitães Nêmesis e contingentes aumentados em cada território
func populate_initial_ecosystem() -> void:
	if not enemy_container:
		return
	
	for child in enemy_container.get_children():
		child.queue_free()
	
	# 1. PÂNTANO DOS GHÛLS (Sudoeste): Enxames e rastejantes necróticos
	var ghul_count: int = 10 if is_night else 6
	for i in range(ghul_count):
		if i % 2 == 0:
			_spawn_putrido_enxame()
		else:
			_spawn_putrido_limo()
	
	# 2. CUME DOS TITÃS & OLOGS (Noroeste): Olog-Titãs e Warlord Nêmesis
	_spawn_olog_warlord()
	_spawn_olog_grunt()
	
	# 3. BASTIÃO DOS ORCS FENDIDOS (Leste): Capitão Nêmesis e Esquadrão Tático
	_spawn_orc_captain()
	for pos in ORC_PATROL_POSITIONS:
		_spawn_fendido_soldier(pos)
	
	EventBus.tactical_pressure_updated.emit("TERRITORIOS_ESTABELECIDOS", 80.0)

## Verifica e repovoa os contingentes territoriais
func _check_and_replenish_habitats() -> void:
	if not enemy_container:
		return
	
	var putrido_count: int = 0
	var olog_count: int = 0
	var fendido_count: int = 0
	
	for child in enemy_container.get_children():
		if not is_instance_valid(child):
			continue
		if child.is_in_group("putridos"):
			putrido_count += 1
		elif child.is_in_group("ologs"):
			olog_count += 1
		elif child.is_in_group("fendidos"):
			fendido_count += 1
	
	# Manutenção do Pântano
	var target_ghuls: int = 10 if is_night else 6
	if putrido_count < target_ghuls:
		var needed: int = target_ghuls - putrido_count
		for i in range(mini(needed, 3)):
			_spawn_putrido_enxame()
	
	# Manutenção dos Titãs
	if olog_count < 2:
		_spawn_olog_grunt()
	
	# Manutenção dos Orcs
	var target_orcs: int = 6 if is_night else 8
	if fendido_count < target_orcs:
		var free_pos = ORC_PATROL_POSITIONS.pick_random()
		_spawn_fendido_soldier(free_pos)

func _spawn_putrido_enxame() -> void:
	var p: Node2D = PUTRIDO_ENXAME_SCENE.instantiate()
	p.global_position = Vector2(
		randf_range(SWAMP_BOUNDS_MIN.x, SWAMP_BOUNDS_MAX.x),
		randf_range(SWAMP_BOUNDS_MIN.y, SWAMP_BOUNDS_MAX.y)
	)
	p.add_to_group("putridos")
	enemy_container.add_child(p)

func _spawn_putrido_limo() -> void:
	var p: Node2D = PUTRIDO_LIMO_SCENE.instantiate()
	p.global_position = Vector2(
		randf_range(SWAMP_BOUNDS_MIN.x, SWAMP_BOUNDS_MAX.x),
		randf_range(SWAMP_BOUNDS_MIN.y, SWAMP_BOUNDS_MAX.y)
	)
	p.add_to_group("putridos")
	enemy_container.add_child(p)

func _spawn_olog_warlord() -> void:
	var olog: Node2D = OLOG_SCENE.instantiate()
	olog.global_position = OLOG_TERRITORY_CENTER
	olog.add_to_group("ologs")
	enemy_container.add_child(olog)
	
	var warlord_data = InfamyManager.get_warlord_by_name("Tharok")
	if not warlord_data:
		var captains = InfamyManager.get_alive_captains()
		if not captains.is_empty():
			warlord_data = captains[0]
	if warlord_data and olog.has_method("promote_to_captain"):
		olog.promote_to_captain(warlord_data)

func _spawn_olog_grunt() -> void:
	var olog: Node2D = OLOG_SCENE.instantiate()
	olog.global_position = Vector2(
		randf_range(OLOG_BOUNDS_MIN.x, OLOG_BOUNDS_MAX.x),
		randf_range(OLOG_BOUNDS_MIN.y, OLOG_BOUNDS_MAX.y)
	)
	olog.add_to_group("ologs")
	enemy_container.add_child(olog)

func _spawn_orc_captain() -> void:
	var orc: Node2D = FENDIDO_SCENE.instantiate()
	orc.global_position = ORC_CAMP_CENTER + Vector2(0, -100)
	orc.add_to_group("fendidos")
	enemy_container.add_child(orc)
	
	var captain_data = InfamyManager.get_warlord_by_name("Dorn")
	if not captain_data:
		var captains = InfamyManager.get_alive_captains()
		if not captains.is_empty():
			captain_data = captains[0]
	if captain_data and orc.has_method("promote_to_captain"):
		orc.promote_to_captain(captain_data)
	
	if tactical_director and orc.has_method("register_unit"):
		tactical_director.register_unit(orc)

func _spawn_fendido_soldier(pos: Vector2) -> void:
	var fendido: Node2D = FENDIDO_SCENE.instantiate()
	fendido.global_position = pos + Vector2(randf_range(-40, 40), randf_range(-40, 40))
	fendido.add_to_group("fendidos")
	enemy_container.add_child(fendido)
	if tactical_director and fendido.has_method("register_unit"):
		tactical_director.register_unit(fendido)

func _trigger_night_swarming() -> void:
	for i in range(4):
		_spawn_putrido_enxame()
	EventBus.tactical_pressure_updated.emit("ENXAME_NOTURNO_ATIVO", 90.0)

func _trigger_day_patrols() -> void:
	EventBus.tactical_pressure_updated.emit("PATRULHA_DIURNA_REFORCADA", 50.0)
