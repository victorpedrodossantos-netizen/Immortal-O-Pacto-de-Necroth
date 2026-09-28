class_name CodexResource
extends Resource

## Recurso Customizado: Códice das Cinzas (Grimório de Almas de Necroth)
## Gerencia o acervo de almas colhidas, essência espectral acumulada e capacidade de invocação.

signal souls_updated(current_energy: float, max_energy: float, total_souls: int)

@export var max_spectral_energy: float = 200.0
@export var current_spectral_energy: float = 60.0
@export var max_army_capacity: int = 12

# Dicionário de almas por ID: { soul_id: {"data": SoulData, "count": int} }
@export var soul_inventory: Dictionary = {}

## Adiciona uma alma colhida ao Códice
func add_soul(soul: SoulData) -> void:
	if not soul:
		return
	
	if not soul_inventory.has(soul.id):
		soul_inventory[soul.id] = {
			"data": soul,
			"count": 0
		}
	
	soul_inventory[soul.id]["count"] += 1
	current_spectral_energy = minf(max_spectral_energy, current_spectral_energy + soul.energy_value)
	emit_signal("souls_updated", current_spectral_energy, max_spectral_energy, get_total_soul_count())

## Consome energia ou alma para o Rito de Despertar
func consume_energy(amount: float) -> bool:
	if current_spectral_energy >= amount:
		current_spectral_energy -= amount
		emit_signal("souls_updated", current_spectral_energy, max_spectral_energy, get_total_soul_count())
		return true
	return false

## Retorna contagem total de almas armazenadas
func get_total_soul_count() -> int:
	var total: int = 0
	for key in soul_inventory:
		total += soul_inventory[key].get("count", 0)
	return total
