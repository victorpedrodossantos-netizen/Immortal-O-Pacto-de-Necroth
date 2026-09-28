class_name TestChamber2D
extends Node2D

const SubjugatedSoulData = preload("res://resources/subjugated_soul_data.gd")
const SoulGrimoireScreen = preload("res://ui/screens/soul_grimoire_screen.gd")
const AbilityHotbar = preload("res://ui/components/ability_hotbar.gd")

## Câmara de Testes 2D: Arena de combate, ritos, comando de esquadrão, chefes e ecologia

const MAIN_MENU_SCENE: String = "res://ui/screens/main_menu.tscn"
const TACTICAL_FENDIDO_SCENE: PackedScene = preload("res://entities/characters/enemies/tactical_fendido_enemy.tscn")
const BOSS_SCENE: PackedScene = preload("res://entities/characters/bosses/avatar_predador.tscn")
const OLOG_SCENE: PackedScene = preload("res://entities/characters/enemies/olog_tita_enemy.tscn")

@onready var btn_back: Button = %BtnBack
@onready var btn_open_grimoire: Button = %BtnOpenGrimoire
@onready var btn_respawn_enemies: Button = %BtnRespawnEnemies
@onready var btn_spawn_boss: Button = %BtnSpawnBoss
@onready var btn_spawn_olog: Button = %BtnSpawnOlog
@onready var btn_toggle_cycle: Button = %BtnToggleCycle
@onready var soul_grimoire_screen: SoulGrimoireScreen = %SoulGrimoireScreen
@onready var ability_hotbar: AbilityHotbar = %AbilityHotbar
@onready var hp_bar: ProgressBar = %HpBar
@onready var hp_label: Label = %HpLabel
@onready var ether_bar: ProgressBar = %EtherBar
@onready var ether_label: Label = %EtherLabel
@onready var soul_count_label: Label = %SoulCountLabel
@onready var guardian_label: Label = %GuardianLabel
@onready var cycle_label: Label = %CycleLabel
@onready var tactical_bark_label: Label = %TacticalBarkLabel
@onready var necroth: Necroth = $Necroth
@onready var enemy_container: Node2D = $EnemyContainer
@onready var tactical_director: TacticalDirector2D = $TacticalDirector2D
@onready var macro_director: MacroPredatorDirector = $MacroPredatorDirector
@onready var day_night: DayNightCycle2D = $DayNightCycle2D
@onready var biome_spawner: BiomeSpawner2D = $BiomeSpawner2D
@onready var dialogue_system: BattleDialogueSystem = $BattleDialogueSystem

var bark_timer: float = 0.0

func _ready() -> void:
	if btn_back:
		btn_back.pressed.connect(_on_back_pressed)
	if btn_open_grimoire:
		btn_open_grimoire.pressed.connect(_toggle_grimoire)
	if btn_respawn_enemies:
		btn_respawn_enemies.pressed.connect(spawn_test_enemies)
	if btn_spawn_boss:
		btn_spawn_boss.pressed.connect(spawn_boss)
	if btn_spawn_olog:
		btn_spawn_olog.pressed.connect(spawn_olog_brute)
	if btn_toggle_cycle:
		btn_toggle_cycle.pressed.connect(_toggle_cycle)
	
	GameManager.buff_started.connect(_on_buff_started)
	GameManager.buff_expired.connect(_on_buff_expired)
	
	if day_night:
		day_night.hour_updated.connect(_on_hour_updated)
		day_night.time_of_day_changed.connect(_on_time_of_day_changed)
	
	if dialogue_system:
		dialogue_system.dialogue_triggered.connect(_on_dialogue_triggered)
	
	if biome_spawner:
		biome_spawner.enemy_container = enemy_container
		biome_spawner.tactical_director = tactical_director
		if day_night:
			biome_spawner.setup_cycle(day_night)
		biome_spawner.populate_initial_ecosystem()
	
	if tactical_director:
		tactical_director.tactical_bark_issued.connect(_on_tactical_bark)
		if necroth:
			tactical_director.target_node = necroth
	
	if macro_director and necroth:
		macro_director.target_player = necroth
	
	if necroth:
		necroth.health_changed.connect(_on_necroth_health_changed)
		necroth.ether_changed.connect(_on_necroth_ether_changed)
		necroth.soul_inventory_updated.connect(_on_necroth_souls_changed)
		if necroth.summoner:
			necroth.summoner.guardian_state_changed.connect(_on_guardian_state_changed)
		
		# Inicialização do HUD
		_on_necroth_health_changed(necroth.current_health, necroth.max_health)
		_on_necroth_ether_changed(necroth.current_ether, necroth.max_ether)
		_on_necroth_souls_changed(necroth.codex.get_total_soul_count())
		
		if ability_hotbar:
			ability_hotbar.setup_necroth(necroth)
	
	if soul_grimoire_screen and necroth and necroth.summoner:
		pass

func _process(delta: float) -> void:
	if bark_timer > 0.0:
		bark_timer -= delta
		if bark_timer <= 0.0 and tactical_bark_label:
			tactical_bark_label.text = ""

func spawn_test_enemies() -> void:
	if biome_spawner:
		biome_spawner.populate_initial_ecosystem()
		_on_tactical_bark("Ecos do Ermo", "O ecossistema dos biomas foi repovoado organicamente!")

func spawn_boss() -> void:
	if not enemy_container:
		return
	
	var boss: AvatarPredador = BOSS_SCENE.instantiate()
	boss.global_position = Vector2(950, -400) # Ruínas Rúnicas do Vazio
	enemy_container.add_child(boss)
	
	if macro_director:
		var target: Node2D = necroth if is_instance_valid(necroth) else null
		macro_director.setup_hunt(boss, target)
	
	_on_tactical_bark("Balgor, Avatar", "O sangue dos invasores nutrirá as pedras de ferro!")

func spawn_olog_brute() -> void:
	if not enemy_container:
		return
	var olog: Node2D = OLOG_SCENE.instantiate()
	olog.global_position = Vector2(-550, -450) # Pilares de Pedra do Norte
	olog.add_to_group("ologs")
	enemy_container.add_child(olog)
	_on_tactical_bark("Olog das Profundezas", "O chão treme com a marcha do Titã de Pedra nos Pilares!")

func _toggle_cycle() -> void:
	if day_night:
		day_night.toggle_day_night()

func _on_hour_updated(hour: float) -> void:
	if cycle_label and day_night:
		var period_str: String = "NOITE [ENXAMES ATIVOS]" if day_night.is_currently_night else "DIA [PATRULHAS MARCIAIS]"
		cycle_label.text = "Ciclo: %s • %02d:00" % [period_str, int(hour)]
		if day_night.is_currently_night:
			cycle_label.modulate = Color(0.4, 0.7, 1.0)
		else:
			cycle_label.modulate = Color(1.0, 0.9, 0.4)

func _on_time_of_day_changed(is_night: bool) -> void:
	if is_night:
		_on_tactical_bark("Voz do Véu", "O manto da noite caiu. Os Pútridos do Limo emergem de suas tocas!")
	else:
		_on_tactical_bark("Voz do Véu", "A luz solar dissipa os vermes. As hostes de ferro reorganizam as linhas.")

func _on_tactical_bark(speaker: String, text: String) -> void:
	if tactical_bark_label:
		tactical_bark_label.text = "🗣 [%s]: \"%s\"" % [speaker, text]
		tactical_bark_label.modulate = Color(1.0, 0.4, 0.4)
		bark_timer = 4.0

func _on_dialogue_triggered(speaker: String, text: String, color: Color) -> void:
	if tactical_bark_label:
		tactical_bark_label.text = "📜 [%s]: \"%s\"" % [speaker, text]
		tactical_bark_label.modulate = color
		bark_timer = 4.5

func _on_necroth_health_changed(curr: float, max_v: float) -> void:
	if hp_bar:
		hp_bar.max_value = max_v
		hp_bar.value = curr
	if hp_label:
		hp_label.text = "Vida: %d / %d" % [int(curr), int(max_v)]

func _on_necroth_ether_changed(curr: float, max_v: float) -> void:
	if ether_bar:
		ether_bar.max_value = max_v
		ether_bar.value = curr
	if ether_label:
		ether_label.text = "Éter Fúnebre: %d / %d" % [int(curr), int(max_v)]

func _on_necroth_souls_changed(total: int) -> void:
	if soul_count_label:
		soul_count_label.text = "Almas no Códice: %d" % total

func _on_guardian_state_changed(is_active: bool) -> void:
	if guardian_label:
		if is_active:
			guardian_label.text = "O Cavaleiro da Morte: [ ATIVO NO CAMPO ]"
			guardian_label.modulate = Color(0.145, 0.886, 0.596)
		else:
			guardian_label.text = "O Cavaleiro da Morte: [ NO VÉU (Pressione B ou Q) ]"
			guardian_label.modulate = Color(0.7, 0.7, 0.7)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
	# 7. Grimório das Almas (Tecla 7 ou TAB)
	elif event is InputEventKey and event.pressed and (event.keycode == KEY_7 or event.keycode == KEY_TAB):
		_toggle_grimoire()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_8:
		_quick_summon(1)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_9:
		_quick_summon(2)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_R:
		spawn_test_enemies()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_O:
		spawn_olog_brute()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_T:
		_toggle_cycle()

func _toggle_grimoire() -> void:
	if soul_grimoire_screen and necroth and necroth.summoner:
		if soul_grimoire_screen.visible:
			soul_grimoire_screen.close_grimoire()
		else:
			soul_grimoire_screen.open_grimoire(necroth.summoner)

func _quick_summon(slot_num: int) -> void:
	if necroth and necroth.summoner:
		var target_soul: SubjugatedSoulData = necroth.summoner.quick_slot_1 if slot_num == 1 else necroth.summoner.quick_slot_2
		if target_soul:
			var mouse_pos: Vector2 = get_global_mouse_position()
			var summoned: Node2D = necroth.summoner.summon_subjugated_soul(target_soul, mouse_pos)
			if summoned:
				_on_tactical_bark("Necroth", "Erga-se das cinzas, %s!" % target_soul.soldier_name)
		else:
			_on_tactical_bark("Pacto de Necroth", "Nenhuma alma vinculada ao Slot %d. Vincule pelo Grimório (TAB)." % slot_num)

func _on_buff_started(_buff_id: String, buff_name: String, duration: float) -> void:
	_on_tactical_bark("Pacto de Necroth", "🔥 Rito Consumado: [%s] ativo por %.0fs!" % [buff_name, duration])

func _on_buff_expired(_buff_id: String) -> void:
	_on_tactical_bark("Pacto de Necroth", "As cinzas do bônus temporário se dissiparam.")

func _on_back_pressed() -> void:
	EventBus.scene_transition_requested.emit(MAIN_MENU_SCENE)
