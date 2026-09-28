class_name ProceduralSoundFX
extends RefCounted

## Gerador de Áudio Sintetizado Diegético para Efeitos Espectrais de Necroth

## Cria um AudioStreamWAV com onda senoidal e decaimento exponencial
static func create_tone(frequency: float, duration: float, sample_rate: int = 22050, decay_rate: float = 4.0) -> AudioStreamWAV:
	var total_samples: int = int(duration * sample_rate)
	var byte_data: PackedByteArray = PackedByteArray()
	byte_data.resize(total_samples * 2) # 16-bit mono
	
	for i in range(total_samples):
		var t: float = float(i) / float(sample_rate)
		var envelope: float = exp(-decay_rate * t)
		var sample_val: float = sin(2.0 * PI * frequency * t) * envelope
		var int_val: int = int(clampf(sample_val * 32000.0, -32767.0, 32767.0))
		
		# Gravação little-endian 16-bit
		byte_data[i * 2] = int_val & 0xFF
		byte_data[i * 2 + 1] = (int_val >> 8) & 0xFF
	
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = byte_data
	return wav

## Cria um som de impacto com ruído e decaimento rápido
static func create_noise_hit(duration: float, sample_rate: int = 22050) -> AudioStreamWAV:
	var total_samples: int = int(duration * sample_rate)
	var byte_data: PackedByteArray = PackedByteArray()
	byte_data.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t: float = float(i) / float(sample_rate)
		var envelope: float = exp(-12.0 * t)
		var sample_val: float = randf_range(-1.0, 1.0) * envelope
		var int_val: int = int(clampf(sample_val * 28000.0, -32767.0, 32767.0))
		
		byte_data[i * 2] = int_val & 0xFF
		byte_data[i * 2 + 1] = (int_val >> 8) & 0xFF
	
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = byte_data
	return wav
