class_name Necroth
extends BaseCharacter

## Necroth: O Tecedor do Vazio e Mestre do Pacto Fúnebre
## Protagonista com absorção espectral, evocação do Carrasco e feitiçaria proibida de Magia Negra.

signal ether_changed(current_ether: float, max_ether: float)
signal soul_inventory_updated(total_souls: int)

@export_group("Magia & Almas")
@export var max_ether: float = 120.0
@export var ether_recovery_rate: float = 8.0 # Recuperação passiva por segundo
@export var codex: CodexResource
@export var garras_scene: PackedScene
@export var sifao_scene: PackedScene

@export_group("Esquiva do Vazio (Passo Umbral)")
@export var dash_speed: float = 620.0
@export var dash_duration: float = 0.22
@export var dash_cooldown: float = 0.8

var current_ether: float = 120.0
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cd_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO
var active_sifao: Node2D = null

@onready var summoner: SummonerComponent = $SummonerComponent
@onready var soul_reaper: SoulReaperComponent = $SoulReaperComponent
@onready var visual_root: Node2D = $Visual
@onready var melee_area: Area2D = $MeleeArea

func _ready() -> void:
	character_name = "Necroth"
	faction = GameEnums.Faction.PACTO_NECROTH
	max_health = 140.0
	move_speed = 240.0
	defense = 4.0
	current_ether = max_ether
	
	if not codex:
		codex = CodexResource.new()
	
	if summoner:
		summoner.codex = codex
	
	if not garras_scene:
		garras_scene = load("res://entities/spells/garras_condenadas_2d.tscn")
	
	if not sifao_scene:
		sifao_scene = load("res://entities/spells/sifao_da_morte_2d.tscn")
	
	super._ready()
	emit_signal("ether_changed", current_ether, max_ether)
	emit_signal("soul_inventory_updated", codex.get_total_soul_count())

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	# Regeneração passiva de éter
	if current_ether < max_ether:
		current_ether = minf(max_ether, current_ether + ether_recovery_rate * delta)
		emit_signal("ether_changed", current_ether, max_ether)
	
	# Timers de esquiva
	if dash_cd_timer > 0.0:
		dash_cd_timer -= delta
	
	if is_dashing:
		dash_timer -= delta
		velocity = dash_direction * dash_speed
		if dash_timer <= 0.0:
			is_dashing = false
	else:
		_handle_movement_input()
	
	move_and_slide()
	_update_facing_direction()
	_update_motion_animation(delta)

var motion_cycle_time: float = 0.0

func _update_motion_animation(delta: float) -> void:
	if not visual_root:
		return
	if velocity.length() > 10.0:
		motion_cycle_time += delta * 12.0
		visual_root.position.y = sin(motion_cycle_time) * 4.0
		visual_root.rotation = sin(motion_cycle_time * 0.5) * 0.05
	else:
		motion_cycle_time += delta * 3.0
		visual_root.position.y = sin(motion_cycle_time) * 2.0
		visual_root.rotation = 0.0

func _handle_movement_input() -> void:
	# Movimentação exclusiva via WASD
	var input_vec: Vector2 = Vector2.ZERO
	if Input.is_key_pressed(KEY_A): input_vec.x -= 1.0
	if Input.is_key_pressed(KEY_D): input_vec.x += 1.0
	if Input.is_key_pressed(KEY_W): input_vec.y -= 1.0
	if Input.is_key_pressed(KEY_S): input_vec.y += 1.0
	
	input_vec = input_vec.normalized()
	velocity = input_vec * move_speed
	
	# Ativação do Passo Umbral (Tecla Numérica 4 ou Espaço)
	if Input.is_key_pressed(KEY_4) or Input.is_key_pressed(KEY_SPACE) or Input.is_action_just_pressed("ui_accept"):
		if dash_cd_timer <= 0.0:
			var dash_dir = input_vec
			if dash_dir == Vector2.ZERO:
				dash_dir = (get_global_mouse_position() - global_position).normalized()
			if dash_dir != Vector2.ZERO:
				_start_dash(dash_dir)

func _input(event: InputEvent) -> void:
	if is_dead:
		return
	
	# 1. Ceifa Pesada da Foice de Éter (Tecla 1 ou Botão Esquerdo do Mouse)
	if (event is InputEventKey and event.pressed and event.keycode == KEY_1) or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		execute_scythe_attack(get_global_mouse_position())
	
	# 2. Magia Negra I: Garras dos Condenados (Tecla 2)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_2:
		cast_garras_condenadas(get_global_mouse_position())
	
	# 3. Magia Negra II: Sifão da Morte / Dreno de Essência (Tecla 3)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_3:
		toggle_sifao_da_morte(get_global_mouse_position())
	
	# 4. Passo Umbral / Esquiva Incorpórea (Tecla 4 ou Espaço)
	elif event is InputEventKey and event.pressed and (event.keycode == KEY_4 or event.keycode == KEY_SPACE):
		if dash_cd_timer <= 0.0:
			var dash_dir = velocity.normalized()
			if dash_dir == Vector2.ZERO:
				dash_dir = (get_global_mouse_position() - global_position).normalized()
			if dash_dir == Vector2.ZERO:
				dash_dir = Vector2.DOWN
			_start_dash(dash_dir)
	
	# 5. Invocação do Cavaleiro da Morte / Carrasco do Limbo (Tecla 5)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_5:
		summon_guardian()
	
	# 6. Ordem Tática de Foco para o Cavaleiro (Tecla 6 ou Botão Direito do Mouse)
	elif (event is InputEventKey and event.pressed and event.keycode == KEY_6) or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed):
		order_squad_focus(get_global_mouse_position())

func _start_dash(dir: Vector2) -> void:
	is_dashing = true
	dash_direction = dir
	dash_timer = dash_duration
	dash_cd_timer = dash_cooldown
	# Efeito visual de sombra espectral
	if visual_root:
		var tween: Tween = create_tween()
		tween.tween_property(visual_root, "modulate", Color(0.1, 0.9, 0.4, 0.3), 0.1)
		tween.tween_property(visual_root, "modulate", Color(1, 1, 1, 1), 0.15)
	AudioManager.play_sfx(AudioManager.stream_cast, 1.8)

## Executa o corte pesado em arco da Foice de Éter (Melee corporal autêntico com clivagem)
func execute_scythe_attack(target_world_pos: Vector2 = Vector2.ZERO) -> void:
	if target_world_pos == Vector2.ZERO:
		target_world_pos = get_global_mouse_position()
		if target_world_pos == Vector2.ZERO or target_world_pos == global_position:
			var dir: Vector2 = Vector2.RIGHT if (visual_root and visual_root.scale.x >= 0) else Vector2.LEFT
			target_world_pos = global_position + dir * 80.0
	
	var to_mouse: Vector2 = (target_world_pos - global_position).normalized()
	if to_mouse == Vector2.ZERO:
		to_mouse = Vector2.RIGHT if (visual_root and visual_root.scale.x > 0) else Vector2.LEFT
	
	# Visual imponente de ceifa com arco sombrio
	_spawn_scythe_slash_visual(to_mouse)
	AudioManager.play_sfx(AudioManager.stream_hit, 2.0)
	
	# Dano físico e impacto corporal em arco amplo (155px de alcance e 125 graus de amplitude)
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy is BaseCharacter and not enemy.is_dead and enemy.faction != faction:
			var d: float = global_position.distance_to(enemy.global_position)
			if d <= 155.0:
				var to_enemy: Vector2 = (enemy.global_position - global_position).normalized()
				var angle_diff: float = absf(to_mouse.angle_to(to_enemy))
				if angle_diff <= deg_to_rad(65.0):
					# Dano pesado da foice
					enemy.take_damage(attack_power * 1.8, self)
					# Recuo físico (Knockback de impacto)
					enemy.velocity += to_mouse * 220.0
					enemy.global_position += to_mouse * 12.0
					# Tremor visual no inimigo
					var hit_tween: Tween = enemy.create_tween()
					hit_tween.tween_property(enemy, "modulate", Color(1.8, 0.4, 0.4, 1.0), 0.08)
					hit_tween.tween_property(enemy, "modulate", Color(1, 1, 1, 1), 0.1)
	
	emit_sensory_noise(1.0)

## Emite ruídos que alertam os sensores auditivos de inimigos dentro do raio
func emit_sensory_noise(intensity: float = 1.0) -> void:
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.has_node("PerceptionSensor2D"):
			enemy.get_node("PerceptionSensor2D").hear_noise(global_position, intensity)

## Magia Negra I: Conjura Garras dos Condenados no ponto indicado
func cast_garras_condenadas(target_world_pos: Vector2) -> bool:
	var ether_cost: float = 25.0
	if current_ether < ether_cost:
		AudioManager.play_sfx(AudioManager.stream_hit, 0.8)
		return false
	
	current_ether -= ether_cost
	emit_signal("ether_changed", current_ether, max_ether)
	
	var spawn_pos: Vector2 = target_world_pos
	var dist: float = global_position.distance_to(spawn_pos)
	if dist > 450.0:
		spawn_pos = global_position + (spawn_pos - global_position).normalized() * 450.0
	
	var garras: Node2D = garras_scene.instantiate()
	garras.global_position = spawn_pos
	if garras.has_method("setup"):
		garras.setup(self)
	
	var cur_scene: Node = get_tree().current_scene if get_tree() else null
	var target_parent: Node = cur_scene if cur_scene else get_parent()
	if target_parent:
		target_parent.add_child.call_deferred(garras)
	
	emit_sensory_noise(1.4)
	return true

## Magia Negra II: Ativa ou desativa a canalização do Sifão da Morte
func toggle_sifao_da_morte(target_world_pos: Vector2) -> void:
	if is_instance_valid(active_sifao):
		active_sifao.stop_drain()
		active_sifao = null
		return
	
	if current_ether < 12.0:
		AudioManager.play_sfx(AudioManager.stream_hit, 0.8)
		return
	
	# Procura inimigo vivo mais próximo do cursor dentro de 450px
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	var best_target: BaseCharacter = null
	var best_dist: float = 450.0
	
	for enemy in enemies:
		if enemy is BaseCharacter and not enemy.is_dead and enemy.faction != faction:
			var d: float = target_world_pos.distance_to(enemy.global_position)
			if d < best_dist and global_position.distance_to(enemy.global_position) <= 450.0:
				best_dist = d
				best_target = enemy
	
	if best_target:
		var sifao: Node2D = sifao_scene.instantiate()
		var cur_scene: Node = get_tree().current_scene
		if cur_scene:
			cur_scene.add_child(sifao)
		else:
			get_parent().add_child(sifao)
		if sifao.has_method("setup"):
			sifao.setup(self, best_target)
		active_sifao = sifao

func _spawn_scythe_slash_visual(dir: Vector2) -> void:
	var slash: Node2D = Node2D.new()
	slash.global_position = global_position + (dir * 55.0)
	slash.rotation = dir.angle()
	
	# Sombra profunda externa
	var shadow: Polygon2D = Polygon2D.new()
	shadow.color = Color(0.04, 0.05, 0.08, 0.75)
	shadow.polygon = PackedVector2Array([
		Vector2(-20, -70), Vector2(48, -48), Vector2(75, 0),
		Vector2(48, 48), Vector2(-20, 70), Vector2(10, 35),
		Vector2(25, 0), Vector2(10, -35)
	])
	slash.add_child(shadow)
	
	# Lâmina espectral interna verde-esmeralda
	var blade: Polygon2D = Polygon2D.new()
	blade.color = Color(0.145, 0.886, 0.596, 0.95)
	blade.polygon = PackedVector2Array([
		Vector2(-12, -58), Vector2(40, -40), Vector2(65, 0),
		Vector2(40, 40), Vector2(-12, 58), Vector2(12, 28),
		Vector2(22, 0), Vector2(12, -28)
	])
	slash.add_child(blade)
	
	var parent_scene: Node = get_tree().current_scene if get_tree() else null
	var target_parent: Node = parent_scene if parent_scene else get_parent()
	if target_parent:
		target_parent.add_child.call_deferred(slash)
	
	var tween: Tween = create_tween()
	tween.tween_property(slash, "scale", Vector2(1.25, 1.25), 0.16)
	tween.parallel().tween_property(blade, "color:a", 0.0, 0.16)
	tween.parallel().tween_property(shadow, "color:a", 0.0, 0.16)
	tween.tween_callback(slash.queue_free)

func summon_guardian() -> Node2D:
	if summoner:
		var success: bool = summoner.summon_carrasco()
		emit_signal("ether_changed", current_ether, max_ether)
		if codex:
			emit_signal("soul_inventory_updated", codex.get_total_soul_count())
		if success:
			emit_sensory_noise(1.6)
		return summoner.active_guardian if success else null
	return null

func order_squad_focus(target_pos: Vector2) -> void:
	if summoner:
		summoner.issue_squad_order(target_pos, "ATTACK_FOCUS")

const SubjugatedSoulData = preload("res://resources/subjugated_soul_data.gd")

## Chamado quando Necroth absorve uma orbe de alma física no campo de batalha
func harvest_soul_orb(drop: Node2D) -> void:
	if not drop:
		return
	
	var s_data: SoulData = drop.soul_data if "soul_data" in drop and drop.soul_data else SoulData.new()
	harvest_soul(s_data)
	
	if summoner:
		var sub_soul: SubjugatedSoulData = SubjugatedSoulData.new()
		var enemy_name: String = drop.source_enemy_name if "source_enemy_name" in drop else "Inimigo"
		var faction_val = drop.source_faction if "source_faction" in drop else GameEnums.Faction.FENDIDOS_DE_FERRO
		var is_cap: bool = drop.is_captain if "is_captain" in drop else false
		var w_data = drop.captain_warlord_data if "captain_warlord_data" in drop else null
		
		sub_soul.id = "soul_%s_%d" % [enemy_name.to_lower().replace(" ", "_"), Time.get_ticks_msec()]
		sub_soul.faction = faction_val
		
		if is_cap and w_data:
			sub_soul.soldier_name = "Espectro de %s" % w_data.get_full_title()
			sub_soul.soul_class = SubjugatedSoulData.SoulClass.COMANDANTE
			sub_soul.sacrifice_buff = SubjugatedSoulData.SacrificeBuffType.ASCENSAO_FUNEBRE
			sub_soul.max_health = 380.0
			sub_soul.attack_damage = 36.0
			sub_soul.move_speed = 195.0
			sub_soul.summon_ether_cost = 35.0
			sub_soul.lore_description = "Capitão Nêmesis subjugado ao Grimório de Invocações. Concede Ascensão Fúnebre ao ser sacrificado."
		else:
			sub_soul.soldier_name = "Espectro de %s" % enemy_name
			sub_soul.summon_ether_cost = 20.0
			match faction_val:
				GameEnums.Faction.FENDIDOS_DE_FERRO:
					sub_soul.soul_class = SubjugatedSoulData.SoulClass.TROPA_CHOQUE
					sub_soul.sacrifice_buff = SubjugatedSoulData.SacrificeBuffType.COURAÇA_FERRO
					sub_soul.max_health = 180.0
					sub_soul.attack_damage = 24.0
					sub_soul.move_speed = 185.0
					sub_soul.lore_description = "Guerreiro Orc Fendido disciplinado no manejo do escudo de ferro."
				GameEnums.Faction.PUTRIDOS_DO_LIMO:
					sub_soul.soul_class = SubjugatedSoulData.SoulClass.FLANQUEADOR
					sub_soul.sacrifice_buff = SubjugatedSoulData.SacrificeBuffType.PASSO_FANTASMA
					sub_soul.max_health = 130.0
					sub_soul.attack_damage = 28.0
					sub_soul.move_speed = 230.0
					sub_soul.lore_description = "Carniçal voraz que rasteja e salta sobre os alvos."
				GameEnums.Faction.VAGANTES_DO_VEU:
					sub_soul.soul_class = SubjugatedSoulData.SoulClass.TROPA_CHOQUE
					sub_soul.sacrifice_buff = SubjugatedSoulData.SacrificeBuffType.COURAÇA_FERRO
					sub_soul.max_health = 340.0
					sub_soul.attack_damage = 40.0
					sub_soul.move_speed = 145.0
					sub_soul.lore_description = "Titã Olog colossal que esmaga múltiplos oponentes."
				_:
					sub_soul.soul_class = SubjugatedSoulData.SoulClass.TROPA_CHOQUE
					sub_soul.max_health = 150.0
					sub_soul.attack_damage = 20.0
		
		summoner.subjugated_souls.append(sub_soul)
		summoner.emit_signal("subjugated_souls_updated")
		EventBus.soul_harvested.emit(sub_soul.id, sub_soul.attack_damage, drop.global_position)

## Chamado quando Necroth absorve uma orbe de alma
func harvest_soul(soul: SoulData) -> void:
	if codex:
		codex.add_soul(soul)
		emit_signal("soul_inventory_updated", codex.get_total_soul_count())
	
	# Recupera vida e éter com o banquete de almas
	heal(14.0)
	current_ether = minf(max_ether, current_ether + 22.0)
	emit_signal("ether_changed", current_ether, max_ether)
	
	# Pulso ritual no corpo de Necroth
	if visual_root:
		var pulse: Tween = create_tween()
		pulse.tween_property(visual_root, "modulate", Color(0.3, 1.8, 0.9, 1.2), 0.12)
		pulse.tween_property(visual_root, "modulate", Color(1, 1, 1, 1), 0.2)
	
	AudioManager.play_sfx(AudioManager.stream_cast, 2.0)

func _update_facing_direction() -> void:
	var mouse_x: float = get_global_mouse_position().x
	if visual_root:
		if mouse_x < global_position.x:
			visual_root.scale.x = -1.0
		else:
			visual_root.scale.x = 1.0

## Sobrescreve a morte para honrar o Pacto de Necroth (Imortalidade e Ressurreição Espectral)
func _on_death(_killer: Node) -> void:
	call_deferred("_trigger_pact_resurrection")

func _trigger_pact_resurrection() -> void:
	is_dead = false
	current_health = max_health
	current_ether = max_ether
	emit_signal("health_changed", current_health, max_health)
	emit_signal("ether_changed", current_ether, max_ether)
	
	# Reposiciona no Círculo Ritual Central
	global_position = Vector2.ZERO
	velocity = Vector2.ZERO
	
	# Onda de choque espectral repulsiva que afasta e repele inimigos ao redor
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy is BaseCharacter and not enemy.is_dead:
			var d: float = global_position.distance_to(enemy.global_position)
			if d <= 360.0:
				var dir: Vector2 = (enemy.global_position - global_position).normalized()
				if dir == Vector2.ZERO: dir = Vector2.RIGHT
				enemy.velocity += dir * 480.0
				enemy.take_damage(25.0, self)
	
	# Efeito visual de quebra e recomposição do Véu
	if visual_root:
		var tween: Tween = create_tween()
		tween.tween_property(visual_root, "modulate", Color(0.2, 2.0, 1.0, 1.0), 0.2)
		tween.tween_property(visual_root, "modulate", Color(1, 1, 1, 1), 0.4)
	
	AudioManager.play_sfx(AudioManager.stream_cast, 1.2)
	EventBus.tactical_pressure_updated.emit("PACTO_RESSURREICAO", 100.0)
