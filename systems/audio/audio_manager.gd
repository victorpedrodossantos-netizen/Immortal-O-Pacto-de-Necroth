extends Node

## Gestor de Áudio Diegético e Trilha Sonora do Projeto
## Centraliza a reprodução sonora procedimental e o controle de barramentos de áudio.

var stream_soul: AudioStreamWAV
var stream_summon: AudioStreamWAV
var stream_bolt: AudioStreamWAV
var stream_hit: AudioStreamWAV
var stream_cast: AudioStreamWAV

var sfx_player: AudioStreamPlayer
var whisper_player: AudioStreamPlayer
var music_player: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_players()
	_generate_audio_streams()
	_connect_events()

func _setup_players() -> void:
	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = &"SFX"
	add_child(sfx_player)
	
	whisper_player = AudioStreamPlayer.new()
	whisper_player.bus = &"Sussurros"
	add_child(whisper_player)
	
	music_player = AudioStreamPlayer.new()
	music_player.bus = &"Trilha"
	add_child(music_player)

func _generate_audio_streams() -> void:
	# Ressonância espectral de coleta de alma (sino de éter)
	stream_soul = ProceduralSoundFX.create_tone(587.33, 0.45, 22050, 3.5)
	
	# Estrondo do Rito de Despertar (ressonância grave do Vazio)
	stream_summon = ProceduralSoundFX.create_tone(110.0, 0.8, 22050, 1.8)
	
	# Feitiço sombrio de conjuração e magia negra
	stream_cast = ProceduralSoundFX.create_tone(293.66, 0.4, 22050, 3.0)
	
	# Disparo rúnico perfurante
	stream_bolt = ProceduralSoundFX.create_tone(420.0, 0.2, 22050, 8.0)
	
	# Impacto de lâmina
	stream_hit = ProceduralSoundFX.create_noise_hit(0.22, 22050)

func _connect_events() -> void:
	EventBus.soul_harvested.connect(_on_soul_harvested)
	EventBus.servant_summoned.connect(_on_servant_summoned)

func play_sfx(stream: AudioStream, vol_db: float = 0.0) -> void:
	if sfx_player and stream:
		sfx_player.stream = stream
		sfx_player.volume_db = vol_db
		sfx_player.play()

func play_whisper(stream: AudioStream, vol_db: float = -2.0) -> void:
	if whisper_player and stream:
		whisper_player.stream = stream
		whisper_player.volume_db = vol_db
		whisper_player.play()

func _on_soul_harvested(_id: String, _energy: float, _pos: Vector2) -> void:
	play_sfx(stream_soul, -2.0)

func _on_servant_summoned(_servant: Node2D, _cost: float) -> void:
	play_sfx(stream_summon, 2.0)

## Ajustes de barramento para a tela de configurações
func set_master_volume(linear_val: float) -> void:
	var bus_idx: int = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(clampf(linear_val, 0.001, 1.0)))

func set_sfx_volume(linear_val: float) -> void:
	var bus_idx: int = AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(clampf(linear_val, 0.001, 1.0)))

func set_music_volume(linear_val: float) -> void:
	var bus_idx: int = AudioServer.get_bus_index("Trilha")
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(clampf(linear_val, 0.001, 1.0)))
