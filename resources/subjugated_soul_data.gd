class_name SubjugatedSoulData
extends Resource

## Dados de uma Alma Subjulgada no Grimório dos Condenados
## Representa guerreiros e comandantes capturados prontos para invocação ou sacrifício.

enum SoulClass {
	TROPA_CHOQUE,      ## Guerreiro de armadura e escudo pesado
	FLANQUEADOR,       ## Assassino veloz com dano crítico pelas costas
	SUPORTE_DISTANCIA, ## Taumaturgo com ataques mágicos ou projéteis
	COMANDANTE         ## Líder de esquadrão com aura de comando
}

enum SacrificeBuffType {
	COURAÇA_FERRO,      ## +50% Armadura & Imunidade a Atordoamento
	PASSO_FANTASMA,     ## +40% Velocidade & Cooldown de Dash 0.2s
	MANANCIAL_VAZIO,    ## Regeneração de Éter triplicada & Custo de feitiços -50%
	ASCENSAO_FUNEBRE    ## Cura 100% Vida/Éter + Onda de Choque Atordoante
}

@export var id: String = "soul_01"
@export var soldier_name: String = "Incursor Fendido"
@export var soul_class: SoulClass = SoulClass.TROPA_CHOQUE
@export var faction: GameEnums.Faction = GameEnums.Faction.FENDIDOS_DE_FERRO
@export var max_health: float = 160.0
@export var attack_damage: float = 22.0
@export var move_speed: float = 180.0
@export var summon_ether_cost: float = 20.0
@export var sacrifice_buff: SacrificeBuffType = SacrificeBuffType.COURAÇA_FERRO
@export var lore_description: String = "Guerreiro que jurou lealdade eterna sob a lâmina da Foice de Necroth."
@export var is_summoned: bool = false
@export var assigned_to_guardian: bool = false
@export var assigned_group: int = 0 ## 0 = Livre, 1 = Grupo 1, 2 = Grupo 2
@export var is_group_captain: bool = false ## Se é o Capitão Líder do seu grupo

func get_class_name_string() -> String:
	var base_str: String = ""
	match soul_class:
		SoulClass.TROPA_CHOQUE: base_str = "Tropa de Choque (Escudo)"
		SoulClass.FLANQUEADOR: base_str = "Flanqueador Ágil (Adagas)"
		SoulClass.SUPORTE_DISTANCIA: base_str = "Taumaturgo (Mágico)"
		SoulClass.COMANDANTE: base_str = "Comandante Espectral"
		_: base_str = "Guerreiro"
	
	if is_group_captain:
		return "👑 Capitão de Esquadrão (%s)" % base_str
	return base_str

func get_sacrifice_description() -> String:
	match sacrifice_buff:
		SacrificeBuffType.COURAÇA_FERRO:
			return "+50% Armadura e Imunidade a Atordoamento por 30s."
		SacrificeBuffType.PASSO_FANTASMA:
			return "+40% Velocidade e Passo Umbral quase instantâneo por 25s."
		SacrificeBuffType.MANANCIAL_VAZIO:
			return "Regeneração de Éter 3x e custo de Magia Negra pela metade por 30s."
		SacrificeBuffType.ASCENSAO_FUNEBRE:
			return "Cura total de Vida e Éter + Onda de Choque que atordoa a arena por 3s."
		_:
			return "Bônus temporário de combate."
