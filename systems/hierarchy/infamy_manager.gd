extends Node

## Gestor Central da Tábua da Infâmia (Ascensão de Sangue)
## Controla rivalidades procedurais, promoções por vitória e cicatrizes de combate.

signal hierarchy_updated

var warlords: Array[WarlordData] = []

const TITLES_CAPTAIN: Array[String] = [
	"O Rompedor de Escudos",
	"O Sedento de Cinzas",
	"Lâmina Cega",
	"O Rastejante de Ferro"
]

const TITLES_WARLORD: Array[String] = [
	"O Flagelo dos Espectros",
	"O Quebra-Crânios",
	"Mestre das Forjas Fendidas",
	"O Implacável"
]

const TITLES_AVATAR: Array[String] = [
	"Avatar do Rancor Ancestral",
	"O Devorador de Éter"
]

const STRENGTHS_POOL: Array[String] = [
	"Imunidade a Disparos Rúnicos",
	"Fúria ao perder tropas",
	"Ataques com Quebra de Guarda",
	"Pele de Ferro Endurecido",
	"Investida Brutal Ininterrupta"
]

const WEAKNESSES_POOL: Array[String] = [
	"Vulnerável à Foice do Carrasco",
	"Aterrorizado por Almas Colhidas",
	"Dano aumentado por ataques de flanco",
	"Atordoamento ao errar investida"
]

func _ready() -> void:
	if warlords.is_empty():
		_generate_initial_hierarchy()

func _generate_initial_hierarchy() -> void:
	# Tier 3: Avatar Supremo
	warlords.append(_create_commander("Balgor", TITLES_AVATAR[0], 3, 45, [STRENGTHS_POOL[0], STRENGTHS_POOL[4]], [WEAKNESSES_POOL[0]]))
	
	# Tier 2: Senhores da Guerra
	warlords.append(_create_commander("Kragor", TITLES_WARLORD[0], 2, 30, [STRENGTHS_POOL[1]], [WEAKNESSES_POOL[2]]))
	warlords.append(_create_commander("Tharok", TITLES_WARLORD[1], 2, 28, [STRENGTHS_POOL[2]], [WEAKNESSES_POOL[3]]))
	
	# Tier 1: Capitães
	warlords.append(_create_commander("Dorn", TITLES_CAPTAIN[0], 1, 15, [STRENGTHS_POOL[3]], [WEAKNESSES_POOL[1]]))
	warlords.append(_create_commander("Grak", TITLES_CAPTAIN[1], 1, 14, [STRENGTHS_POOL[1]], [WEAKNESSES_POOL[2]]))
	warlords.append(_create_commander("Murok", TITLES_CAPTAIN[2], 1, 12, [STRENGTHS_POOL[4]], [WEAKNESSES_POOL[0]]))
	
	emit_signal("hierarchy_updated")

func _create_commander(c_name: String, c_title: String, c_tier: int, p_level: int, strengths: Array[String], weaknesses: Array[String]) -> WarlordData:
	var w: WarlordData = WarlordData.new()
	w.id = "%s_%d" % [c_name.to_lower(), Time.get_ticks_msec()]
	w.commander_name = c_name
	w.title = c_title
	w.tier = c_tier
	w.power_level = p_level
	w.strengths = strengths
	w.weaknesses = weaknesses
	w.is_alive = true
	return w

## Promove um inimigo comum que venceu o jogador ou destacou-se em combate
func promote_enemy(enemy_name: String, faction: GameEnums.Faction = GameEnums.Faction.FENDIDOS_DE_FERRO) -> WarlordData:
	var title: String = TITLES_CAPTAIN.pick_random()
	var new_warlord: WarlordData = _create_commander(
		enemy_name,
		title,
		1,
		18,
		[STRENGTHS_POOL.pick_random()],
		[WEAKNESSES_POOL.pick_random()]
	)
	new_warlord.faction = faction
	new_warlord.kill_count += 1
	new_warlord.scars.append("Ascendeu à infâmia após derrotar tropas do Pacto.")
	
	warlords.append(new_warlord)
	emit_signal("hierarchy_updated")
	EventBus.enemy_promoted.emit(new_warlord.id, new_warlord.get_full_title(), new_warlord.tier)
	return new_warlord

## Registra a derrota de um comandante
func record_warlord_defeat(warlord_id: String) -> void:
	for w in warlords:
		if w.id == warlord_id and w.is_alive:
			w.is_alive = false
			w.scars.append("Cicatriz de lâmina espectral profunda deixada pelo Carrasco.")
			emit_signal("hierarchy_updated")
			break
